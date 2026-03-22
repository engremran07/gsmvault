"""
Admin Suite Infrastructure Views - Storage & Firmwares Management

Enterprise-grade admin views for:
- Storage (Shared Drives, Service Accounts, File Management)
- Firmwares (Brands, Models, Variants, ROMs)
"""

from __future__ import annotations

import logging
import threading
from datetime import timedelta
from typing import Any

from django.conf import settings
from django.contrib.admin.views.decorators import staff_member_required
from django.http import HttpRequest, HttpResponse
from django.views.decorators.csrf import csrf_protect

from .views_shared import (
    _ADMIN_DISABLED,
    _admin_paginate,
    _admin_search,
    _admin_sort,
    _make_breadcrumb,
    _render_admin,
)

logger = logging.getLogger(__name__)


# =============================================================================
# STORAGE MANAGEMENT
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_storage(request: HttpRequest) -> HttpResponse:
    """Storage dashboard - Shared Drives, Service Accounts, Files overview."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    stats = {
        "total_drives": 0,
        "active_drives": 0,
        "total_files": 0,
        "total_size_gb": 0,
        "service_accounts": 0,
        "healthy_drives": 0,
        "warning_drives": 0,
        "critical_drives": 0,
    }
    drives = []
    service_accounts = []
    message = ""

    # Handle POST actions
    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.storage.models import ServiceAccount as SA
            from apps.storage.models import SharedDriveAccount

            if action == "toggle_drive":
                drive_id = request.POST.get("drive_id")
                drive = SharedDriveAccount.objects.filter(pk=drive_id).first()
                if drive:
                    drive.is_active = not drive.is_active
                    drive.save(update_fields=["is_active"])
                    message = f"Drive {'enabled' if drive.is_active else 'disabled'}."
            elif action == "health_check":
                drive_id = request.POST.get("drive_id")
                drive = SharedDriveAccount.objects.filter(pk=drive_id).first()
                if drive:
                    drive.update_health_status()
                    message = f"Health check completed for {drive.name}."
            elif action == "create_drive":
                name = (request.POST.get("name") or "").strip()[:128]
                drive_id_val = (request.POST.get("drive_id_value") or "").strip()[:128]
                owner_email = (request.POST.get("owner_email") or "").strip()[:255]
                if name and drive_id_val:
                    SharedDriveAccount.objects.create(
                        name=name,
                        drive_id=drive_id_val,
                        owner_email=owner_email,
                        is_active=True,
                    )
                    message = f"Drive '{name}' created."
        except Exception as exc:
            logger.warning("Storage admin action failed: %s", exc)
            message = f"Action failed: {exc}"

    # Load data
    try:
        from apps.storage.models import CloudStorageProvider, SharedDriveAccount
        from apps.storage.models import ServiceAccount as SA

        # Cloud Storage Providers
        all_providers = CloudStorageProvider.objects.all().order_by(
            "-priority", "-is_active", "name"
        )
        stats["total_providers"] = all_providers.count()
        stats["active_providers"] = all_providers.filter(
            is_active=True, status="active"
        ).count()

        providers = list(
            all_providers[:20].values(
                "id",
                "name",
                "provider",
                "auth_type",
                "account_email",
                "status",
                "is_active",
                "total_space_bytes",
                "used_space_bytes",
                "last_sync_at",
            )
        )

        # Shared Drives
        all_drives = SharedDriveAccount.objects.all().order_by(
            "-priority", "-is_active", "name"
        )
        stats["total_drives"] = all_drives.count()
        stats["active_drives"] = all_drives.filter(is_active=True).count()
        stats["healthy_drives"] = all_drives.filter(health_status="healthy").count()
        stats["warning_drives"] = all_drives.filter(health_status="warning").count()
        stats["critical_drives"] = all_drives.filter(
            health_status__in=["critical", "full"]
        ).count()

        for d in all_drives:
            stats["total_files"] += d.current_file_count
            stats["total_size_gb"] += d.total_size_gb

        drives = list(
            all_drives[:50].values(
                "id",
                "name",
                "drive_id",
                "owner_email",
                "max_files",
                "current_file_count",
                "total_size_gb",
                "is_active",
                "health_status",
                "priority",
                "last_health_check",
                "provider__name",
            )
        )

        stats["service_accounts"] = SA.objects.count()
        service_accounts = list(
            SA.objects.all()[:50].values(
                "id",
                "name",
                "email",
                "is_active",
                "used_quota_today_gb",
                "daily_quota_gb",
            )
        )
    except Exception as exc:
        logger.debug("Failed to load storage data: %s", exc)
        providers = []

    return _render_admin(
        request,
        "admin_suite/storage.html",
        {
            "stats": stats,
            "providers": providers,
            "drives": drives,
            "service_accounts": service_accounts,
            "message": message,
        },
        nav_active="storage",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Storage", None),
        ),
        subtitle="Cloud Providers, Shared Drives & Service Accounts",
    )


@csrf_protect
@staff_member_required
def admin_suite_storage_files(request: HttpRequest) -> HttpResponse:
    """Firmware file management — browse, search, add firmware files to models."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    query = (request.GET.get("q") or "").strip()
    type_filter = (request.GET.get("type") or "").strip()

    files_list: list[dict[str, Any]] = []
    total_count = 0
    message = ""
    brands: list[dict[str, Any]] = []
    models_list: list[dict[str, Any]] = []

    firmware_types = {
        "official": "OfficialFirmware",
        "engineering": "EngineeringFirmware",
        "readback": "ReadbackFirmware",
        "modified": "ModifiedFirmware",
        "other": "OtherFirmware",
    }

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.firmwares import models as fw_models

            if action == "add_firmware":
                fw_type = request.POST.get("firmware_type", "official")
                model_class_name = firmware_types.get(fw_type, "OfficialFirmware")
                model_class = getattr(fw_models, model_class_name)

                model_id = request.POST.get("model_id")
                brand_id = request.POST.get("brand_id")
                original_file_name = (
                    request.POST.get("original_file_name") or ""
                ).strip()[:255]
                stored_file_path = (request.POST.get("stored_file_path") or "").strip()[
                    :500
                ]

                if model_id and original_file_name and stored_file_path:
                    fw_model = fw_models.Model.objects.filter(pk=model_id).first()
                    if fw_model:
                        create_kwargs: dict[str, Any] = {
                            "model": fw_model,
                            "brand_id": brand_id or fw_model.brand_id,  # type: ignore[attr-defined]
                            "original_file_name": original_file_name,
                            "stored_file_path": stored_file_path,
                            "uploader": request.user,
                            "is_active": request.POST.get("is_active") == "on",
                        }

                        # Optional fields
                        file_size = request.POST.get("file_size", "").strip()
                        if file_size and file_size.isdigit():
                            create_kwargs["file_size"] = int(file_size)

                        for field in (
                            "android_version",
                            "build_number",
                            "chipset",
                            "file_hash",
                        ):
                            val = (request.POST.get(field) or "").strip()
                            if val:
                                create_kwargs[field] = val

                        security_patch = (
                            request.POST.get("security_patch") or ""
                        ).strip()
                        if security_patch:
                            from datetime import datetime

                            try:
                                create_kwargs["security_patch"] = datetime.strptime(  # noqa: DTZ007
                                    security_patch, "%Y-%m-%d"
                                ).date()
                            except ValueError:
                                pass

                        build_date = (request.POST.get("build_date") or "").strip()
                        if build_date:
                            from datetime import datetime

                            try:
                                create_kwargs["build_date"] = datetime.strptime(  # noqa: DTZ007
                                    build_date, "%Y-%m-%d"
                                ).date()
                            except ValueError:
                                pass

                        # Subtype for engineering/modified/other
                        if fw_type in ("engineering", "modified", "other"):
                            subtype = (request.POST.get("subtype") or "").strip()[:128]
                            if subtype:
                                create_kwargs["subtype"] = subtype

                        variant_id = request.POST.get("variant_id")
                        if variant_id:
                            create_kwargs["variant_id"] = variant_id

                        model_class.objects.create(**create_kwargs)
                        message = (
                            f"{model_class_name} '{original_file_name}' added "
                            f"to {fw_model.brand.name} {fw_model.name}."
                        )
                    else:
                        message = "Model not found."
                else:
                    message = (
                        "Model, filename, and download link or file path are required."
                    )

            elif action == "delete_firmware":
                fw_type = request.POST.get("firmware_type", "official")
                fw_id = request.POST.get("firmware_id")
                model_class_name = firmware_types.get(fw_type, "OfficialFirmware")
                model_class = getattr(fw_models, model_class_name)
                fw_obj = model_class.objects.filter(pk=fw_id).first()
                if fw_obj:
                    fw_obj.is_active = False
                    fw_obj.save(update_fields=["is_active"])
                    message = "Firmware file deactivated."

            elif action == "activate_firmware":
                fw_type = request.POST.get("firmware_type", "official")
                fw_id = request.POST.get("firmware_id")
                model_class_name = firmware_types.get(fw_type, "OfficialFirmware")
                model_class = getattr(fw_models, model_class_name)
                fw_obj = model_class.objects.filter(pk=fw_id).first()
                if fw_obj:
                    fw_obj.is_active = True
                    fw_obj.save(update_fields=["is_active"])
                    message = "Firmware file activated."

        except Exception as exc:
            logger.warning("Firmware file action failed: %s", exc)
            message = f"Action failed: {exc}"

    # Load firmware files from all types
    try:
        from apps.firmwares import models as fw_models

        brands = list(fw_models.Brand.objects.order_by("name").values("id", "name"))
        models_list = list(
            fw_models.Model.objects.select_related("brand")
            .order_by("brand__name", "name")
            .values("id", "name", "brand_id", "brand__name")
        )

        for type_key, class_name in firmware_types.items():
            if type_filter and type_filter != type_key:
                continue
            model_class = getattr(fw_models, class_name)
            qs = model_class.objects.select_related("brand", "model").order_by(
                "-created_at"
            )
            if query:
                qs = qs.filter(original_file_name__icontains=query)

            for fw in qs[:200]:
                files_list.append(
                    {
                        "id": str(fw.id),
                        "type": type_key,
                        "type_label": class_name.replace("Firmware", ""),
                        "original_file_name": fw.original_file_name,
                        "brand_name": fw.brand.name if fw.brand else "-",
                        "model_name": fw.model.name if fw.model else "-",
                        "file_size": fw.file_size,
                        "android_version": fw.android_version or "-",
                        "build_number": fw.build_number or "-",
                        "is_active": fw.is_active,
                        "is_verified": fw.is_verified,
                        "download_count": fw.download_count,
                        "created_at": fw.created_at,
                    }
                )

        # Sort by created_at descending
        files_list.sort(key=lambda x: x["created_at"], reverse=True)
        total_count = len(files_list)

    except Exception as exc:
        logger.debug("Failed to load firmware files: %s", exc)

    files_page = _admin_paginate(request, files_list, per_page=50)

    return _render_admin(
        request,
        "admin_suite/firmwares_files.html",
        {
            "files": files_page,
            "page_obj": files_page,
            "total_count": total_count,
            "query": query,
            "type_filter": type_filter,
            "brands": brands,
            "models_list": models_list,
            "message": message,
            "firmware_types": [
                ("official", "Official"),
                ("engineering", "Engineering"),
                ("readback", "Readback"),
                ("modified", "Modified"),
                ("other", "Other"),
            ],
        },
        nav_active="firmwares_files",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Firmwares", "admin_suite:firmwares"),
            ("Files", None),
        ),
        subtitle="Firmware File Management",
    )


@csrf_protect
@staff_member_required
def admin_suite_storage_providers(request: HttpRequest) -> HttpResponse:
    """Cloud storage providers management - Add, configure, manage providers."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    message = ""
    providers = []
    provider_choices = []
    auth_type_choices = []

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.storage.models import CloudStorageProvider
            from apps.storage.services.provisioning import provisioner

            if action == "create_provider":
                name = (request.POST.get("name") or "").strip()[:128]
                provider_type = request.POST.get("provider_type")
                account_email = (request.POST.get("account_email") or "").strip()[:255]

                if name and provider_type:
                    provider = CloudStorageProvider.objects.create(
                        name=name,
                        provider=provider_type,
                        account_email=account_email,
                        status="pending",
                        is_active=True,
                    )
                    message = (
                        f"Provider '{name}' created. Configure credentials to activate."
                    )

            elif action == "configure_google_service_account":
                provider_id = request.POST.get("provider_id")
                sa_json = request.POST.get("service_account_json", "").strip()

                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider and sa_json:
                    try:
                        import json

                        sa_data = json.loads(sa_json)
                        result = provisioner.provision_google_service_account(
                            provider=provider,
                            service_account_info=sa_data,
                        )
                        if result.get("success"):
                            provider.service_account_json_path = result.get(
                                "credentials_path", ""
                            )
                            provider.status = "active"
                            provider.save()
                            message = (
                                f"Service account configured: {result.get('email')}"
                            )
                        else:
                            message = f"Failed: {result.get('error')}"
                    except json.JSONDecodeError:
                        message = "Invalid JSON format for service account."

            elif action == "bulk_upload_service_accounts":
                provider_id = request.POST.get("provider_id")
                sa_json_array = request.POST.get("service_accounts_json", "").strip()

                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider and sa_json_array:
                    try:
                        import json

                        sa_list = json.loads(sa_json_array)
                        if isinstance(sa_list, list):
                            result = provisioner.bulk_provision_google_service_accounts(
                                provider=provider,
                                service_accounts_json=sa_list,
                            )
                            message = f"Provisioned {result['success']}/{result['total']} service accounts."
                        else:
                            message = "Expected JSON array of service accounts."
                    except json.JSONDecodeError:
                        message = "Invalid JSON format."

            elif action == "fetch_shared_drives":
                provider_id = request.POST.get("provider_id")
                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider:
                    drives = provisioner.fetch_google_shared_drives(provider)
                    message = f"Found and synced {len(drives)} shared drives."

            elif action == "validate_connection":
                provider_id = request.POST.get("provider_id")
                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider:
                    result = provisioner.validate_provider_connection(provider)
                    if result.get("success"):
                        message = f"Connection valid. Available: {result.get('available_space_gb', 0):.2f} GB"
                    else:
                        message = f"Connection failed: {result.get('error')}"

            elif action == "toggle_provider":
                provider_id = request.POST.get("provider_id")
                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider:
                    provider.is_active = not provider.is_active
                    provider.save(update_fields=["is_active"])
                    message = (
                        f"Provider {'enabled' if provider.is_active else 'disabled'}."
                    )

            elif action == "delete_provider":
                provider_id = request.POST.get("provider_id")
                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider:
                    name = provider.name
                    provider.delete()
                    message = f"Provider '{name}' deleted."

            elif action == "configure_s3":
                provider_id = request.POST.get("provider_id")
                access_key = request.POST.get("access_key_id", "").strip()
                secret_key = request.POST.get("secret_access_key", "").strip()
                bucket = request.POST.get("bucket_name", "").strip()
                region = request.POST.get("region", "us-east-1").strip()
                endpoint = request.POST.get("endpoint_url", "").strip()

                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider and access_key and secret_key and bucket:
                    result = provisioner.provision_s3_compatible(
                        provider=provider,
                        access_key_id=access_key,
                        secret_access_key=secret_key,
                        bucket_name=bucket,
                        region=region,
                        endpoint_url=endpoint or None,
                    )
                    if result.get("success"):
                        message = f"S3 storage configured for bucket: {bucket}"
                    else:
                        message = f"Failed: {result.get('error')}"

            elif action == "configure_mega":
                provider_id = request.POST.get("provider_id")
                email = request.POST.get("mega_email", "").strip()
                password = request.POST.get("mega_password", "").strip()

                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider and email and password:
                    result = provisioner.provision_mega(
                        provider=provider,
                        email=email,
                        password=password,
                    )
                    if result.get("success"):
                        message = f"MEGA account configured: {email}"
                    else:
                        message = f"Failed: {result.get('error')}"

            elif action == "configure_onedrive":
                provider_id = request.POST.get("provider_id")
                client_id = request.POST.get("client_id", "").strip()
                client_secret = request.POST.get("client_secret", "").strip()
                tenant_id = request.POST.get("tenant_id", "common").strip()

                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider and client_id and client_secret:
                    result = provisioner.provision_onedrive(
                        provider=provider,
                        client_id=client_id,
                        client_secret=client_secret,
                        tenant_id=tenant_id,
                    )
                    if result.get("success"):
                        message = f"OneDrive configured. Auth URL: {result.get('auth_url', 'N/A')[:50]}..."
                    else:
                        message = f"Failed: {result.get('error')}"

            elif action == "configure_dropbox":
                provider_id = request.POST.get("provider_id")
                app_key = request.POST.get("app_key", "").strip()
                app_secret = request.POST.get("app_secret", "").strip()
                access_token = request.POST.get("access_token", "").strip()

                provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
                if provider and app_key and app_secret:
                    result = provisioner.provision_dropbox(
                        provider=provider,
                        app_key=app_key,
                        app_secret=app_secret,
                        access_token=access_token or None,
                    )
                    if result.get("success"):
                        message = f"Dropbox configured. Status: {result.get('status')}"
                    else:
                        message = f"Failed: {result.get('error')}"

        except Exception as exc:
            logger.warning("Storage provider action failed: %s", exc)
            message = f"Action failed: {exc}"

    # Load providers
    try:
        from apps.storage.models import CloudStorageProvider

        providers = list(
            CloudStorageProvider.objects.all()
            .order_by("-is_active", "-priority", "name")
            .values(
                "id",
                "name",
                "provider",
                "auth_type",
                "account_email",
                "account_id",
                "status",
                "is_active",
                "total_space_bytes",
                "used_space_bytes",
                "daily_transfer_limit_gb",
                "used_transfer_today_gb",
                "last_sync_at",
                "last_error",
                "created_at",
            )
        )
        provider_choices = CloudStorageProvider.PROVIDER_CHOICES
        auth_type_choices = CloudStorageProvider.AUTH_TYPE_CHOICES
    except Exception as exc:
        logger.debug("Failed to load providers: %s", exc)

    return _render_admin(
        request,
        "admin_suite/storage_providers.html",
        {
            "providers": providers,
            "provider_choices": provider_choices,
            "auth_type_choices": auth_type_choices,
            "message": message,
        },
        nav_active="storage_providers",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Storage", "admin_suite:storage"),
            ("Cloud Providers", None),
        ),
        subtitle="Cloud Storage Provider Management",
    )


@csrf_protect
@staff_member_required
def admin_suite_storage_provider_detail(
    request: HttpRequest, provider_id: str
) -> HttpResponse:
    """Detailed view for a single cloud storage provider."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    message = ""
    provider = None
    shared_drives = []
    service_accounts = []

    try:
        from apps.storage.models import CloudStorageProvider

        provider = CloudStorageProvider.objects.filter(pk=provider_id).first()
        if not provider:
            return _render_admin(
                request,
                "admin_suite/storage_provider_detail.html",
                {"error": "Provider not found"},
                nav_active="storage",
                breadcrumb=_make_breadcrumb(
                    ("Admin Home", "admin_suite:admin_suite"),
                    ("Storage", "admin_suite:storage"),
                    ("Cloud Providers", "admin_suite:storage_providers"),
                    ("Not Found", None),
                ),
                subtitle="Provider Not Found",
            )

        # Load related data
        all_drives = provider.shared_drives.all()  # type: ignore[attr-defined]
        shared_drives = list(
            all_drives.values(
                "id",
                "name",
                "drive_id",
                "owner_email",
                "max_files",
                "current_file_count",
                "total_size_gb",
                "is_active",
                "health_status",
            )
        )

        # Get service accounts from shared drives
        for drive in all_drives:
            sa_list = list(
                drive.service_accounts.all()[:20].values(
                    "id",
                    "name",
                    "email",
                    "is_active",
                    "is_banned",
                    "used_quota_today_gb",
                    "daily_quota_gb",
                    "last_used_at",
                )
            )
            service_accounts.extend(sa_list)

    except Exception as exc:
        logger.debug("Failed to load provider detail: %s", exc)
        message = f"Error loading provider: {exc}"

    return _render_admin(
        request,
        "admin_suite/storage_provider_detail.html",
        {
            "provider": provider,
            "shared_drives": shared_drives,
            "service_accounts": service_accounts,
            "message": message,
        },
        nav_active="storage_providers",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Storage", "admin_suite:storage"),
            ("Cloud Providers", "admin_suite:storage_providers"),
            (provider.name if provider else "Detail", None),
        ),
        subtitle=f"Provider: {provider.name}" if provider else "Provider Detail",
    )


# =============================================================================
# FIRMWARES MANAGEMENT
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_firmwares(request: HttpRequest) -> HttpResponse:
    """Firmwares dashboard - Brands, Models, Variants, ROMs overview."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    stats = {
        "total_brands": 0,
        "total_models": 0,
        "total_variants": 0,
        "total_roms": 0,
        "pending_brand_requests": 0,
        "pending_model_requests": 0,
        "pending_variant_requests": 0,
    }
    recent_brands = []
    recent_models = []
    pending_requests = []
    message = ""

    # Handle POST actions
    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.firmwares.models import (
                Brand,
                BrandCreationRequest,
                Model,
                ModelCreationRequest,
                Variant,
            )

            if action == "approve_brand":
                req_id = request.POST.get("request_id")
                bcr = BrandCreationRequest.objects.filter(
                    pk=req_id, status="pending"
                ).first()
                if bcr:
                    from django.utils.text import slugify

                    Brand.objects.create(name=bcr.name, slug=slugify(bcr.name))
                    bcr.status = "approved"
                    bcr.reviewed_by = request.user
                    bcr.save(update_fields=["status", "reviewed_by", "reviewed_at"])
                    message = f"Brand '{bcr.name}' approved and created."
            elif action == "reject_brand":
                req_id = request.POST.get("request_id")
                bcr = BrandCreationRequest.objects.filter(
                    pk=req_id, status="pending"
                ).first()
                if bcr:
                    bcr.status = "rejected"
                    bcr.reviewed_by = request.user
                    bcr.notes = request.POST.get("notes", "")
                    bcr.save(
                        update_fields=["status", "reviewed_by", "reviewed_at", "notes"]
                    )
                    message = "Brand request rejected."
            elif action == "create_brand":
                name = (request.POST.get("name") or "").strip()[:128]
                if name:
                    from django.utils.text import slugify

                    Brand.objects.create(name=name, slug=slugify(name))
                    message = f"Brand '{name}' created."
            elif action == "create_model":
                brand_id = request.POST.get("brand_id")
                name = (request.POST.get("name") or "").strip()[:128]
                if brand_id and name:
                    from django.utils.text import slugify

                    brand = Brand.objects.filter(pk=brand_id).first()
                    if brand:
                        Model.objects.create(brand=brand, name=name, slug=slugify(name))
                        message = f"Model '{name}' created for {brand.name}."
        except Exception as exc:
            logger.warning("Firmwares admin action failed: %s", exc)
            message = f"Action failed: {exc}"

    # Load data
    try:
        from apps.firmwares.models import (
            Brand,
            BrandCreationRequest,
            Model,
            ModelCreationRequest,
            Variant,
            VariantCreationRequest,
        )

        stats["total_brands"] = Brand.objects.count()
        stats["total_models"] = Model.objects.count()
        stats["total_variants"] = Variant.objects.count()
        stats["pending_brand_requests"] = BrandCreationRequest.objects.filter(
            status="pending"
        ).count()
        stats["pending_model_requests"] = ModelCreationRequest.objects.filter(
            status="pending"
        ).count()
        stats["pending_variant_requests"] = VariantCreationRequest.objects.filter(
            status="pending"
        ).count()

        # Try to get ROM count
        try:
            from apps.firmwares.models import StockROM  # type: ignore[attr-defined]

            stats["total_roms"] = StockROM.objects.count()
        except Exception:
            logger.debug("StockROM model not available")

        recent_brands = list(
            Brand.objects.order_by("-created_at")[:10].values(
                "id", "name", "slug", "created_at"
            )
        )
        recent_models = list(
            Model.objects.select_related("brand")
            .order_by("-created_at")[:10]
            .values("id", "name", "slug", "brand__name", "created_at")
        )

        # Pending requests
        pending_brand_reqs = list(
            BrandCreationRequest.objects.filter(status="pending")
            .order_by("-created_at")[:10]
            .values("id", "name", "created_at", "requested_by__email")
        )
        pending_model_reqs = list(
            ModelCreationRequest.objects.filter(status="pending")
            .order_by("-created_at")[:10]
            .values("id", "name", "brand__name", "created_at", "requested_by__email")
        )
        pending_requests = [{"type": "brand", **r} for r in pending_brand_reqs] + [
            {"type": "model", **r} for r in pending_model_reqs
        ]
    except Exception as exc:
        logger.debug("Failed to load firmwares data: %s", exc)

    return _render_admin(
        request,
        "admin_suite/firmwares.html",
        {
            "stats": stats,
            "recent_brands": recent_brands,
            "recent_models": recent_models,
            "pending_requests": pending_requests,
            "message": message,
        },
        nav_active="firmwares",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Firmwares", None),
        ),
        subtitle="Brands, Models & ROMs",
    )


@csrf_protect
@staff_member_required
def admin_suite_firmwares_brands(request: HttpRequest) -> HttpResponse:
    """Detailed brand management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    query = _admin_search(request)

    brands_page = None
    total_count = 0
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from django.utils.text import slugify

            from apps.firmwares.models import Brand

            if action == "create":
                name = (request.POST.get("name") or "").strip()[:128]
                if name:
                    Brand.objects.create(name=name, slug=slugify(name))
                    message = f"Brand '{name}' created."
            elif action == "delete":
                brand_id = request.POST.get("brand_id")
                Brand.objects.filter(pk=brand_id).delete()
                message = "Brand deleted."
            elif action == "update":
                brand_id = request.POST.get("brand_id")
                name = (request.POST.get("name") or "").strip()[:128]
                if brand_id and name:
                    Brand.objects.filter(pk=brand_id).update(
                        name=name, slug=slugify(name)
                    )
                    message = "Brand updated."
        except Exception as exc:
            logger.warning("Brand action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from django.db.models import Count

        from apps.firmwares.models import Brand

        qs = Brand.objects.annotate(model_count=Count("models"))
        if query:
            qs = qs.filter(name__icontains=query)

        total_count = qs.count()
        qs, sort_field, sort_dir = _admin_sort(
            request,
            qs,
            {"name": "name", "models": "model_count", "created": "created_at"},
            default_sort="name",
        )
        brands_page = _admin_paginate(request, qs, per_page=50)
    except Exception as exc:
        logger.debug("Failed to load brands: %s", exc)
        sort_field = ""
        sort_dir = "asc"

    return _render_admin(
        request,
        "admin_suite/firmwares_brands.html",
        {
            "brands": brands_page,
            "page_obj": brands_page,
            "total_count": total_count,
            "query": query,
            "q": query,
            "sort": sort_field,
            "dir": sort_dir,
            "message": message,
        },
        nav_active="firmwares",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Firmwares", "admin_suite:firmwares"),
            ("Brands", None),
        ),
        subtitle="Brand Management",
    )


@csrf_protect
@staff_member_required
def admin_suite_firmwares_models(request: HttpRequest) -> HttpResponse:
    """Detailed model management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    query = _admin_search(request)
    brand_filter = (request.GET.get("brand") or "").strip()

    models_page = None
    brands = []
    total_count = 0
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            import json

            from django.utils.text import slugify

            from apps.firmwares.models import Brand, Model

            if action == "create":
                brand_id = request.POST.get("brand_id")
                name = (request.POST.get("name") or "").strip()[:128]
                brand = Brand.objects.filter(pk=brand_id).first()
                if brand and name:
                    # Parse JSON list fields
                    def _parse_json_list(val: str) -> list[str]:
                        val = val.strip()
                        if not val:
                            return []
                        try:
                            parsed = json.loads(val)
                            if isinstance(parsed, list):
                                return [str(v) for v in parsed]
                        except (json.JSONDecodeError, TypeError):
                            pass
                        return [v.strip() for v in val.split(",") if v.strip()]

                    # Parse optional date fields
                    def _parse_date(val: str):  # noqa: ANN202
                        from datetime import datetime

                        val = val.strip()
                        if not val:
                            return None
                        try:
                            return datetime.strptime(val, "%Y-%m-%d").date()  # noqa: DTZ007
                        except ValueError:
                            return None

                    Model.objects.create(
                        brand=brand,
                        name=name,
                        slug=slugify(name),
                        marketing_name=(
                            request.POST.get("marketing_name") or ""
                        ).strip()[:255],
                        codename=(request.POST.get("codename") or "").strip()[:128],
                        model_code=(request.POST.get("model_code") or "").strip()[:64],
                        model_codes=_parse_json_list(
                            request.POST.get("model_codes") or ""
                        ),
                        also_known_as=(request.POST.get("also_known_as") or "").strip(),
                        description=(request.POST.get("description") or "").strip(),
                        image_url=(request.POST.get("image_url") or "").strip()[:500],
                        chipset=(request.POST.get("chipset") or "").strip()[:256],
                        cpu=(request.POST.get("cpu") or "").strip()[:256],
                        gpu=(request.POST.get("gpu") or "").strip()[:256],
                        network_technology=(
                            request.POST.get("network_technology") or ""
                        ).strip()[:128],
                        os_version=(request.POST.get("os_version") or "").strip()[:128],
                        ram_options=_parse_json_list(
                            request.POST.get("ram_options") or ""
                        ),
                        storage_options=_parse_json_list(
                            request.POST.get("storage_options") or ""
                        ),
                        colors=_parse_json_list(request.POST.get("colors") or ""),
                        display_size=(request.POST.get("display_size") or "").strip()[
                            :64
                        ],
                        battery=(request.POST.get("battery") or "").strip()[:64],
                        dimensions=(request.POST.get("dimensions") or "").strip()[:128],
                        weight=(request.POST.get("weight") or "").strip()[:64],
                        status=(request.POST.get("status") or "available").strip(),
                        regions=_parse_json_list(request.POST.get("regions") or ""),
                        release_date=_parse_date(
                            request.POST.get("release_date") or ""
                        ),
                        announced_date=_parse_date(
                            request.POST.get("announced_date") or ""
                        ),
                        is_active=request.POST.get("is_active") == "on",
                    )
                    message = f"Model '{name}' created."
            elif action == "delete":
                model_id = request.POST.get("model_id")
                Model.objects.filter(pk=model_id).delete()
                message = "Model deleted."
        except Exception as exc:
            logger.warning("Model action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from django.db.models import Count

        from apps.firmwares.models import Brand, Model

        brands = list(Brand.objects.order_by("name").values("id", "name"))

        qs = Model.objects.select_related("brand").annotate(
            variant_count=Count("variants")
        )
        if query:
            qs = qs.filter(name__icontains=query)
        if brand_filter:
            qs = qs.filter(brand_id=brand_filter)

        total_count = qs.count()
        qs, sort_field, sort_dir = _admin_sort(
            request,
            qs,
            {
                "name": "name",
                "brand": "brand__name",
                "variants": "variant_count",
                "created": "created_at",
            },
            default_sort="brand__name",
        )
        models_page = _admin_paginate(request, qs, per_page=50)
    except Exception as exc:
        logger.debug("Failed to load models: %s", exc)
        sort_field = ""
        sort_dir = "asc"

    return _render_admin(
        request,
        "admin_suite/firmwares_models.html",
        {
            "models": models_page,
            "page_obj": models_page,
            "brands": brands,
            "total_count": total_count,
            "query": query,
            "q": query,
            "sort": sort_field,
            "dir": sort_dir,
            "brand_filter": brand_filter,
            "message": message,
        },
        nav_active="firmwares",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Firmwares", "admin_suite:firmwares"),
            ("Models", None),
        ),
        subtitle="Model Management",
    )


# =============================================================================
# ENHANCED ADS MANAGEMENT
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_ads_campaigns(request: HttpRequest) -> HttpResponse:
    """Campaign management for ads."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    campaigns = None
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.ads.models import Campaign

            if action == "create":
                name = (request.POST.get("name") or "").strip()[:255]
                if name:
                    Campaign.objects.create(
                        name=name,
                        is_active=bool(request.POST.get("is_active")),
                    )
                    message = f"Campaign '{name}' created."
            elif action == "toggle":
                campaign_id = request.POST.get("campaign_id")
                camp = Campaign.objects.filter(pk=campaign_id).first()
                if camp:
                    camp.is_active = not camp.is_active
                    camp.save(update_fields=["is_active"])
                    message = (
                        f"Campaign {'activated' if camp.is_active else 'deactivated'}."
                    )
            elif action == "delete":
                campaign_id = request.POST.get("campaign_id")
                Campaign.objects.filter(pk=campaign_id).delete()
                message = "Campaign deleted."
            elif action == "bulk_activate":
                ids = request.POST.getlist("campaign_ids")
                if ids:
                    count = Campaign.objects.filter(pk__in=ids).update(is_active=True)
                    message = f"{count} campaign(s) activated."
            elif action == "bulk_deactivate":
                ids = request.POST.getlist("campaign_ids")
                if ids:
                    count = Campaign.objects.filter(pk__in=ids).update(is_active=False)
                    message = f"{count} campaign(s) deactivated."
            elif action == "bulk_delete":
                ids = request.POST.getlist("campaign_ids")
                if ids:
                    count, _ = Campaign.objects.filter(pk__in=ids).delete()
                    message = f"{count} campaign(s) deleted."
        except Exception as exc:
            logger.warning("Campaign action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.ads.models import Campaign

        q = _admin_search(request)
        qs = Campaign.objects.all()
        if q:
            qs = qs.filter(name__icontains=q)

        qs, sort_field, sort_dir = _admin_sort(
            request,
            qs,
            {"name": "name", "created": "created_at", "budget": "budget"},
            default_sort="-created_at",
        )
        campaigns = _admin_paginate(request, qs, per_page=20)
    except Exception as exc:
        logger.debug("Failed to load campaigns: %s", exc)
        q = ""
        sort_field = ""
        sort_dir = "asc"

    return _render_admin(
        request,
        "admin_suite/ads_campaigns.html",
        {
            "campaigns": campaigns,
            "page_obj": campaigns,
            "q": q,
            "sort": sort_field,
            "dir": sort_dir,
            "message": message,
        },
        nav_active="ads",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Ads", "admin_suite:ads"),
            ("Campaigns", None),
        ),
        subtitle="Campaign Management",
    )


@csrf_protect
@staff_member_required
def admin_suite_ads_placements(request: HttpRequest) -> HttpResponse:
    """Detailed placement management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    placements = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.ads.models import AdPlacement

            if action == "create":
                name = (request.POST.get("name") or "").strip()[:255]
                slug = (request.POST.get("slug") or "").strip()[:255]
                page_context = (request.POST.get("page_context") or "").strip()[:255]
                if name and slug:
                    AdPlacement.objects.create(
                        name=name,
                        slug=slug,
                        page_context=page_context,
                        is_active=True,
                        is_enabled=True,
                    )
                    message = f"Placement '{name}' created."
            elif action == "toggle":
                placement_id = request.POST.get("placement_id")
                pl = AdPlacement.objects.filter(pk=placement_id).first()
                if pl:
                    pl.is_active = not pl.is_active
                    pl.save(update_fields=["is_active"])
                    message = (
                        f"Placement {'activated' if pl.is_active else 'deactivated'}."
                    )
            elif action == "delete":
                placement_id = request.POST.get("placement_id")
                AdPlacement.objects.filter(pk=placement_id).update(is_deleted=True)
                message = "Placement deleted."
        except Exception as exc:
            logger.warning("Placement action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.ads.models import AdPlacement

        placements = list(
            AdPlacement.objects.filter(is_deleted=False)
            .order_by("name")
            .values(
                "id",
                "name",
                "slug",
                "page_context",
                "is_active",
                "is_enabled",
                "allowed_types",
                "allowed_sizes",
                "created_at",
            )
        )
    except Exception as exc:
        logger.debug("Failed to load placements: %s", exc)

    return _render_admin(
        request,
        "admin_suite/ads_placements.html",
        {
            "placements": placements,
            "message": message,
        },
        nav_active="ads",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Ads", "admin_suite:ads"),
            ("Placements", None),
        ),
        subtitle="Placement Management",
    )


@csrf_protect
@staff_member_required
def admin_suite_ads_creatives(request: HttpRequest) -> HttpResponse:
    """Creative assets management."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    creatives = []
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        try:
            from apps.ads.models import AdCreative

            if action == "toggle":
                creative_id = request.POST.get("creative_id")
                cr = AdCreative.objects.filter(pk=creative_id).first()
                if cr:
                    cr.is_active = not cr.is_active
                    cr.save(update_fields=["is_active"])
                    message = (
                        f"Creative {'activated' if cr.is_active else 'deactivated'}."
                    )
        except Exception as exc:
            logger.warning("Creative action failed: %s", exc)
            message = f"Action failed: {exc}"

    try:
        from apps.ads.models import AdCreative

        creatives = list(
            AdCreative.objects.filter(is_deleted=False)
            .order_by("-created_at")[:100]
            .values(
                "id", "name", "creative_type", "is_active", "is_enabled", "created_at"
            )
        )
    except Exception as exc:
        logger.debug("Failed to load creatives: %s", exc)

    return _render_admin(
        request,
        "admin_suite/ads_creatives.html",
        {
            "creatives": creatives,
            "message": message,
        },
        nav_active="ads",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Ads", "admin_suite:ads"),
            ("Creatives", None),
        ),
        subtitle="Creative Assets",
    )


@csrf_protect
@staff_member_required
def admin_suite_ads_analytics(request: HttpRequest) -> HttpResponse:
    """Ads analytics and reporting."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    stats = {
        "total_impressions": 0,
        "total_clicks": 0,
        "ctr": 0,
        "impressions_24h": 0,
        "clicks_24h": 0,
        "impressions_7d": 0,
        "clicks_7d": 0,
    }
    top_placements = []
    recent_events = []

    try:
        from django.db.models import Count
        from django.utils import timezone

        from apps.ads.models import AdEvent, AdPlacement

        now = timezone.now()
        day_ago = now - timedelta(hours=24)
        week_ago = now - timedelta(days=7)

        stats["total_impressions"] = AdEvent.objects.filter(
            event_type="impression"
        ).count()
        stats["total_clicks"] = AdEvent.objects.filter(event_type="click").count()
        stats["impressions_24h"] = AdEvent.objects.filter(
            event_type="impression", created_at__gte=day_ago
        ).count()
        stats["clicks_24h"] = AdEvent.objects.filter(
            event_type="click", created_at__gte=day_ago
        ).count()
        stats["impressions_7d"] = AdEvent.objects.filter(
            event_type="impression", created_at__gte=week_ago
        ).count()
        stats["clicks_7d"] = AdEvent.objects.filter(
            event_type="click", created_at__gte=week_ago
        ).count()

        if stats["total_impressions"] > 0:
            stats["ctr"] = round(  # type: ignore[assignment]
                (stats["total_clicks"] / stats["total_impressions"]) * 100, 2
            )

        top_placements = list(
            AdPlacement.objects.filter(is_deleted=False)
            .annotate(event_count=Count("events"))
            .order_by("-event_count")[:10]
            .values("id", "name", "slug", "event_count")
        )

        recent_events = list(
            AdEvent.objects.select_related("placement")
            .order_by("-created_at")[:50]
            .values("id", "event_type", "placement__name", "created_at")
        )
    except Exception as exc:
        logger.debug("Failed to load ads analytics: %s", exc)

    return _render_admin(
        request,
        "admin_suite/ads_analytics.html",
        {
            "stats": stats,
            "top_placements": top_placements,
            "recent_events": recent_events,
        },
        nav_active="ads",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Ads", "admin_suite:ads"),
            ("Analytics", None),
        ),
        subtitle="Performance Analytics",
    )


__all__ = [
    "admin_suite_ads_analytics",
    # Ads Enhanced
    "admin_suite_ads_campaigns",
    "admin_suite_ads_creatives",
    "admin_suite_ads_placements",
    # Firmwares
    "admin_suite_firmwares",
    "admin_suite_firmwares_brands",
    "admin_suite_firmwares_models",
    # Downloads
    "admin_suite_firmwares_downloads",
    # Scraper
    "admin_suite_scraper",
    # Audit
    "admin_suite_audit_log",
    # Celery
    "admin_suite_celery",
    # Storage
    "admin_suite_storage",
    "admin_suite_storage_files",
]


# =============================================================================
# DOWNLOAD MANAGEMENT
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_firmwares_downloads(request: HttpRequest) -> HttpResponse:
    """Download gating management — tokens, sessions, ad-gate logs, hotlink blocks, config."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from django.utils import timezone

    query = _admin_search(request)
    tab = request.GET.get("tab", "overview")
    message = ""

    # ---------- Config save ----------
    if request.method == "POST":
        action = request.POST.get("action", "")
        try:
            if action == "save_config":
                from apps.site_settings.models import SiteSettings

                ss = SiteSettings.get_solo()
                ss.download_gate_enabled = request.POST.get("gate_enabled") == "on"
                ss.download_countdown_seconds = int(
                    request.POST.get("countdown_seconds", 10)
                )
                ss.download_ad_gate_enabled = (
                    request.POST.get("ad_gate_enabled") == "on"
                )
                ss.download_ad_gate_seconds = int(
                    request.POST.get("ad_gate_seconds", 30)
                )
                ss.download_token_expiry_minutes = int(
                    request.POST.get("token_expiry_minutes", 30)
                )
                ss.download_require_login = request.POST.get("require_login") == "on"
                ss.download_max_per_day = int(request.POST.get("max_per_day", 0))
                ss.download_hotlink_protection = (
                    request.POST.get("hotlink_protection") == "on"
                )
                ss.download_link_encryption = (
                    request.POST.get("link_encryption") == "on"
                )
                ss.save()
                message = "Download settings saved."
                tab = "config"
            elif action == "add_hotlink_block":
                from apps.firmwares.models import HotlinkBlock

                domain = (request.POST.get("domain") or "").strip().lower()[:253]
                reason = (request.POST.get("reason") or "").strip()[:500]
                if domain:
                    HotlinkBlock.objects.get_or_create(
                        domain=domain,
                        defaults={"reason": reason, "is_active": True},
                    )
                    message = f"Hotlink block added for {domain}."
                tab = "hotlinks"
            elif action == "delete_hotlink":
                from apps.firmwares.models import HotlinkBlock

                block_id = request.POST.get("block_id")
                HotlinkBlock.objects.filter(pk=block_id).delete()
                message = "Hotlink block removed."
                tab = "hotlinks"
            elif action == "revoke_token":
                from apps.firmwares.models import DownloadToken

                token_id = request.POST.get("token_id")
                DownloadToken.objects.filter(pk=token_id).update(
                    status=DownloadToken.Status.REVOKED
                )
                message = "Token revoked."
                tab = "tokens"
            elif action == "expire_stale":
                from apps.firmwares.download_service import expire_stale_tokens

                count = expire_stale_tokens()
                message = f"Expired {count} stale token(s)."
                tab = "tokens"
        except Exception as exc:
            logger.warning("Download admin action failed: %s", exc)
            message = f"Action failed: {exc}"

    # ---------- Load data ----------
    # Config
    config: dict[str, Any] = {}
    try:
        from apps.site_settings.models import SiteSettings

        ss = SiteSettings.get_solo()
        config = {
            "gate_enabled": ss.download_gate_enabled,
            "countdown_seconds": ss.download_countdown_seconds,
            "ad_gate_enabled": ss.download_ad_gate_enabled,
            "ad_gate_seconds": ss.download_ad_gate_seconds,
            "token_expiry_minutes": ss.download_token_expiry_minutes,
            "require_login": ss.download_require_login,
            "max_per_day": ss.download_max_per_day,
            "hotlink_protection": ss.download_hotlink_protection,
            "link_encryption": ss.download_link_encryption,
        }
    except Exception as exc:
        logger.debug("Failed to load download config: %s", exc)

    # Overview stats
    token_stats: dict[str, int] = {}
    session_stats: dict[str, int] = {}
    try:
        from apps.firmwares.models import DownloadSession, DownloadToken

        now = timezone.now()
        day_ago = now - timedelta(hours=24)
        token_stats = {
            "total": DownloadToken.objects.count(),
            "active": DownloadToken.objects.filter(
                status=DownloadToken.Status.ACTIVE
            ).count(),
            "used": DownloadToken.objects.filter(
                status=DownloadToken.Status.USED
            ).count(),
            "expired": DownloadToken.objects.filter(
                status=DownloadToken.Status.EXPIRED
            ).count(),
            "today": DownloadToken.objects.filter(created_at__gte=day_ago).count(),
        }
        session_stats = {
            "total": DownloadSession.objects.count(),
            "completed": DownloadSession.objects.filter(
                status=DownloadSession.Status.COMPLETED
            ).count(),
            "started": DownloadSession.objects.filter(
                status=DownloadSession.Status.STARTED
            ).count(),
            "failed": DownloadSession.objects.filter(
                status=DownloadSession.Status.FAILED
            ).count(),
            "today": DownloadSession.objects.filter(started_at__gte=day_ago).count(),
        }
    except Exception as exc:
        logger.debug("Failed to load download stats: %s", exc)

    # Tokens list
    tokens_page = None
    try:
        from apps.firmwares.models import DownloadToken

        qs = DownloadToken.objects.select_related("firmware", "user")
        if query:
            qs = qs.filter(token__icontains=query)
        qs, sort_field, sort_dir = _admin_sort(
            request,
            qs,
            {
                "created": "created_at",
                "status": "status",
                "expires": "expires_at",
            },
            default_sort="-created_at",
        )
        tokens_page = _admin_paginate(request, qs, per_page=25)
    except Exception as exc:
        logger.debug("Failed to load tokens: %s", exc)
        sort_field = ""
        sort_dir = "asc"

    # Sessions list
    sessions_page = None
    try:
        from apps.firmwares.models import DownloadSession

        qs = DownloadSession.objects.select_related("token", "user")
        qs, _, _ = _admin_sort(
            request,
            qs,
            {"started": "started_at", "status": "status"},
            default_sort="-started_at",
        )
        sessions_page = _admin_paginate(request, qs, per_page=25)
    except Exception as exc:
        logger.debug("Failed to load sessions: %s", exc)

    # Hotlink blocks
    hotlinks_page = None
    try:
        from apps.firmwares.models import HotlinkBlock

        qs = HotlinkBlock.objects.all()
        if query:
            qs = qs.filter(domain__icontains=query)
        hotlinks_page = _admin_paginate(request, qs, per_page=25)
    except Exception as exc:
        logger.debug("Failed to load hotlinks: %s", exc)

    # Ad gate logs
    adgate_page = None
    try:
        from apps.firmwares.models import AdGateLog

        qs = AdGateLog.objects.select_related("session")
        adgate_page = _admin_paginate(request, qs, per_page=25)
    except Exception as exc:
        logger.debug("Failed to load ad gate logs: %s", exc)

    return _render_admin(
        request,
        "admin_suite/firmwares_downloads.html",
        {
            "config": config,
            "token_stats": token_stats,
            "session_stats": session_stats,
            "tokens": tokens_page,
            "tokens_page": tokens_page,
            "sessions": sessions_page,
            "sessions_page": sessions_page,
            "hotlinks": hotlinks_page,
            "hotlinks_page": hotlinks_page,
            "adgate_logs": adgate_page,
            "adgate_page": adgate_page,
            "tab": tab,
            "query": query,
            "q": query,
            "message": message,
            "sort": sort_field if "sort_field" in dir() else "",
            "dir": sort_dir if "sort_dir" in dir() else "asc",
        },
        nav_active="firmwares_downloads",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Firmwares", "admin_suite:firmwares"),
            ("Downloads", None),
        ),
        subtitle="Download Management",
    )


# =============================================================================
# SCRAPER MANAGEMENT (P3)
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_scraper(request: HttpRequest) -> HttpResponse:
    """OEM firmware scraper management — sources, configs, runs, approval queue."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    from django.utils import timezone

    sources: list[dict[str, Any]] = []
    recent_runs: list[dict[str, Any]] = []
    pending_jobs: list[dict[str, Any]] = []
    gsmarena_sync_runs: list[dict[str, Any]] = []
    gsmarena_stats: dict[str, int] = {
        "total_devices": 0,
        "total_syncs": 0,
        "successful_syncs": 0,
    }
    stats: dict[str, int] = {
        "total_sources": 0,
        "active_sources": 0,
        "total_runs": 0,
        "successful_runs": 0,
        "items_ingested": 0,
        "pending_review": 0,
    }
    message = ""

    if request.method == "POST":
        action = request.POST.get("action")
        source_id = request.POST.get("source_id")
        job_id = request.POST.get("job_id")
        job_ids = request.POST.getlist("job_ids")
        try:
            from apps.firmwares.models import IngestionJob, OEMSource

            if action == "toggle" and source_id:
                src = OEMSource.objects.get(pk=source_id)
                src.is_active = not src.is_active
                src.save(update_fields=["is_active"])
                message = f"{'Enabled' if src.is_active else 'Disabled'} {src.name}"

            elif action == "approve" and job_id:
                job = IngestionJob.objects.get(
                    pk=job_id, status=IngestionJob.Status.PENDING
                )
                job.status = IngestionJob.Status.APPROVED
                job.reviewed_by = request.user
                job.reviewed_at = timezone.now()
                job.save(update_fields=["status", "reviewed_by", "reviewed_at"])
                message = f"Approved job #{job.pk}"

            elif action == "reject" and job_id:
                job = IngestionJob.objects.get(
                    pk=job_id, status=IngestionJob.Status.PENDING
                )
                job.status = IngestionJob.Status.REJECTED
                job.reviewed_by = request.user
                job.reviewed_at = timezone.now()
                job.save(update_fields=["status", "reviewed_by", "reviewed_at"])
                message = f"Rejected job #{job.pk}"

            elif action == "bulk_approve" and job_ids:
                count = IngestionJob.objects.filter(
                    pk__in=job_ids, status=IngestionJob.Status.PENDING
                ).update(
                    status=IngestionJob.Status.APPROVED,
                    reviewed_by=request.user,
                    reviewed_at=timezone.now(),
                )
                message = f"Approved {count} job(s)"

            elif action == "bulk_reject" and job_ids:
                count = IngestionJob.objects.filter(
                    pk__in=job_ids, status=IngestionJob.Status.PENDING
                ).update(
                    status=IngestionJob.Status.REJECTED,
                    reviewed_by=request.user,
                    reviewed_at=timezone.now(),
                )
                message = f"Rejected {count} job(s)"

            elif action == "run_scraper":
                # Check if scraper is already running — survive page refresh
                from apps.firmwares.models import SyncRun as _SyncRun

                already_running = _SyncRun.objects.filter(status="running").exists()
                if already_running:
                    message = (
                        "Scraper is already running — refresh the page"
                        " to see live progress. No new run started."
                    )
                else:
                    strategy = request.POST.get("strategy", "brand_walk")
                    sample_size_str = request.POST.get("sample_size", "")
                    exclude_scraped = request.POST.get("exclude_scraped") == "on"
                    exclude_discontinued = (
                        request.POST.get("exclude_discontinued") == "on"
                    )

                    allowed_strategies = {
                        "brand_walk",
                        "search_targeted",
                        "rumor_mill",
                        "hybrid",
                    }
                    if strategy not in allowed_strategies:
                        strategy = "brand_walk"

                    sample_size_val: int | None = None
                    if sample_size_str.isdigit():
                        sample_size_val = max(1, min(int(sample_size_str), 500))

                    try:
                        from apps.firmwares.tasks import scrape_gsmarena_async

                        scrape_gsmarena_async.delay(  # type: ignore[attr-defined]
                            strategy=strategy,
                            sample_size=sample_size_val,
                            exclude_scraped=exclude_scraped,
                            exclude_discontinued=exclude_discontinued,
                        )
                        message = (
                            f"Scraper queued (async): strategy={strategy}"
                            f", sample_size={sample_size_val or 'unlimited'}"
                            f", exclude_scraped={exclude_scraped}"
                            f", exclude_discontinued={exclude_discontinued}"
                        )
                    except Exception:
                        # Redis/Celery not available — run in background thread
                        from apps.firmwares.gsmarena_service import (
                            run_gsmarena_scrape,
                        )

                        def _run_scraper_bg(
                            strat: str,
                            sz: int | None,
                            excl: bool,
                            excl_disc: bool,
                        ) -> None:
                            import django

                            django.setup()
                            try:
                                run_gsmarena_scrape(
                                    strategy=strat,
                                    sample_size=sz,
                                    exclude_scraped=excl,
                                    exclude_discontinued=excl_disc,
                                )
                            except Exception:
                                logger.exception("Background scraper failed")

                        t = threading.Thread(
                            target=_run_scraper_bg,
                            args=(
                                strategy,
                                sample_size_val,
                                exclude_scraped,
                                exclude_discontinued,
                            ),
                            daemon=True,
                        )
                        t.start()
                        message = (
                            f"Scraper started (background): strategy={strategy}"
                            f", sample_size={sample_size_val or 'unlimited'}"
                            f" — check Sync Runs table for live progress"
                        )

            elif action == "stop_scraper":
                from apps.firmwares.models import SyncRun as _SyncRun

                running_runs = _SyncRun.objects.filter(status="running")
                stopped_count = 0
                for run in running_runs:
                    run.cancel_requested = True
                    run.status = "stopped"
                    run.completed_at = timezone.now()
                    run.save(
                        update_fields=["cancel_requested", "status", "completed_at"]
                    )
                    stopped_count += 1
                if stopped_count:
                    message = (
                        f"Force-stopped {stopped_count} running run(s)."
                        " Status set to stopped."
                    )
                else:
                    message = "No running scraper to stop."

            elif action == "probe_methods":
                from apps.firmwares.models import SyncRun as _SyncRun

                already_running = _SyncRun.objects.filter(status="running").exists()
                if already_running:
                    message = (
                        "Cannot probe while scraper is running. Stop the scraper first."
                    )
                else:
                    # Run probe in background thread
                    def _run_probe_bg() -> None:
                        import django

                        django.setup()
                        try:
                            from apps.firmwares.scraper.fetch_methods import FetchChain

                            chain = FetchChain()
                            results = chain.probe_all(
                                "https://www.gsmarena.com/makers.php3"
                            )
                            from apps.firmwares.models import SyncRun

                            probe_run = SyncRun.objects.create(
                                status="success",
                                method_used="probe",
                            )
                            probe_run.errors = results
                            probe_run.completed_at = timezone.now()
                            probe_run.save(update_fields=["errors", "completed_at"])
                        except Exception:
                            logger.exception("Probe methods failed")

                    t = threading.Thread(target=_run_probe_bg, daemon=True)
                    t.start()
                    message = (
                        "Method probe started — testing all 8 methods"
                        " against GSMArena. Check Sync Runs for results."
                    )

            elif action == "approve_device":
                from apps.firmwares.gsmarena_service import (
                    materialize_approved_device,
                )
                from apps.firmwares.models import GSMArenaDevice

                device_id = request.POST.get("device_id")
                if device_id:
                    dev = GSMArenaDevice.objects.get(pk=device_id)
                    dev.review_status = GSMArenaDevice.ReviewStatus.APPROVED
                    dev.reviewed_by = request.user
                    dev.reviewed_at = timezone.now()
                    dev.save(
                        update_fields=[
                            "review_status",
                            "reviewed_by",
                            "reviewed_at",
                        ]
                    )
                    mat = materialize_approved_device(dev.pk)
                    extras = []
                    if mat["brand_created"]:
                        extras.append(f"brand '{mat['brand']}' created")
                    if mat["model_created"]:
                        extras.append(f"model '{mat['model']}' created")
                    suffix = f" — {', '.join(extras)}" if extras else ""
                    message = f"Approved: {dev.brand} {dev.model_name}{suffix}"

            elif action == "reject_device":
                from apps.firmwares.models import GSMArenaDevice

                device_id = request.POST.get("device_id")
                if device_id:
                    dev = GSMArenaDevice.objects.get(pk=device_id)
                    dev.review_status = GSMArenaDevice.ReviewStatus.REJECTED
                    dev.reviewed_by = request.user
                    dev.reviewed_at = timezone.now()
                    dev.save(
                        update_fields=[
                            "review_status",
                            "reviewed_by",
                            "reviewed_at",
                        ]
                    )
                    message = f"Rejected: {dev.brand} {dev.model_name}"

            elif action == "bulk_approve_devices":
                from apps.firmwares.gsmarena_service import (
                    materialize_approved_device,
                )
                from apps.firmwares.models import GSMArenaDevice

                device_ids = request.POST.getlist("device_ids")
                if device_ids:
                    pending_devs = list(
                        GSMArenaDevice.objects.filter(
                            pk__in=device_ids,
                            review_status=GSMArenaDevice.ReviewStatus.PENDING,
                        ).values_list("pk", flat=True)
                    )
                    count = GSMArenaDevice.objects.filter(
                        pk__in=pending_devs,
                    ).update(
                        review_status=GSMArenaDevice.ReviewStatus.APPROVED,
                        reviewed_by=request.user,
                        reviewed_at=timezone.now(),
                    )
                    brands_created = 0
                    models_created = 0
                    for dev_pk in pending_devs:
                        mat = materialize_approved_device(dev_pk)
                        if mat["brand_created"]:
                            brands_created += 1
                        if mat["model_created"]:
                            models_created += 1
                    parts = [f"Approved {count} device(s)"]
                    if brands_created:
                        parts.append(f"{brands_created} brand(s) created")
                    if models_created:
                        parts.append(f"{models_created} model(s) created")
                    message = " — ".join(parts)

            elif action == "bulk_reject_devices":
                from apps.firmwares.models import GSMArenaDevice

                device_ids = request.POST.getlist("device_ids")
                if device_ids:
                    count = GSMArenaDevice.objects.filter(
                        pk__in=device_ids,
                        review_status=GSMArenaDevice.ReviewStatus.PENDING,
                    ).update(
                        review_status=GSMArenaDevice.ReviewStatus.REJECTED,
                        reviewed_by=request.user,
                        reviewed_at=timezone.now(),
                    )
                    message = f"Rejected {count} device(s)"

            elif action == "edit_device":
                from apps.firmwares.models import GSMArenaDevice

                device_id = request.POST.get("device_id")
                if device_id:
                    dev = GSMArenaDevice.objects.get(pk=device_id)
                    dev.brand = (
                        request.POST.get("edit_brand") or dev.brand or ""
                    ).strip()
                    dev.model_name = (
                        request.POST.get("edit_model_name") or dev.model_name or ""
                    ).strip()
                    dev.marketed_as = (
                        request.POST.get("edit_marketed_as") or dev.marketed_as or ""
                    ).strip()[:500]
                    dev.model_codes = (
                        request.POST.get("edit_model_codes") or dev.model_codes or ""
                    ).strip()[:500]
                    dev.chipset = (
                        request.POST.get("edit_chipset") or dev.chipset or ""
                    ).strip()[:300]
                    dev.os_version = (
                        request.POST.get("edit_os_version") or dev.os_version or ""
                    ).strip()[:200]
                    dev.os_upgradeable_to = (
                        request.POST.get("edit_os_upgradeable_to")
                        or dev.os_upgradeable_to
                        or ""
                    ).strip()[:200]
                    dev.save(
                        update_fields=[
                            "brand",
                            "model_name",
                            "marketed_as",
                            "model_codes",
                            "chipset",
                            "os_version",
                            "os_upgradeable_to",
                        ]
                    )
                    message = f"Updated: {dev.brand} {dev.model_name}"

            elif action == "save_schedule":
                from apps.site_settings.models import SiteSettings

                schedule_hours = request.POST.get("schedule_hours", "0")
                ms_schedule_hours = request.POST.get("ms_schedule_hours", "0")
                try:
                    hours_val = int(schedule_hours)
                except (ValueError, TypeError):
                    hours_val = 0
                hours_val = max(0, min(hours_val, 168))

                try:
                    ms_hours_val = int(ms_schedule_hours)
                except (ValueError, TypeError):
                    ms_hours_val = 0
                ms_hours_val = max(0, min(ms_hours_val, 168))

                ss = SiteSettings.objects.first()
                if ss:
                    ss.gsmarena_scrape_interval_hours = hours_val
                    ss.multi_source_scrape_interval_hours = ms_hours_val
                    ss.save(
                        update_fields=[
                            "gsmarena_scrape_interval_hours",
                            "multi_source_scrape_interval_hours",
                        ]
                    )
                    parts = []
                    if hours_val > 0:
                        parts.append(f"GSMArena every {hours_val}h")
                    if ms_hours_val > 0:
                        parts.append(f"Multi-source every {ms_hours_val}h")
                    if parts:
                        message = f"Schedule saved: {', '.join(parts)}"
                    else:
                        message = "Both schedules disabled — manual runs only"
                else:
                    message = "SiteSettings not found — schedule not saved"

            elif action == "run_multi_source":
                # Multi-source swarm scrape across all registered sites
                from apps.firmwares.models import SyncRun as _SyncRun

                already_running = _SyncRun.objects.filter(status="running").exists()
                if already_running:
                    message = (
                        "A scraper is already running — wait for it to finish"
                        " before starting multi-source discovery."
                    )
                else:
                    ms_workers_str = request.POST.get("ms_workers", "4")
                    ms_delay_str = request.POST.get("ms_delay", "5")
                    ms_brand_limit_str = request.POST.get("ms_brand_limit", "30")

                    try:
                        ms_workers = max(1, min(int(ms_workers_str), 8))
                    except (ValueError, TypeError):
                        ms_workers = 4
                    try:
                        ms_delay = max(2.0, min(float(ms_delay_str), 30.0))
                    except (ValueError, TypeError):
                        ms_delay = 5.0
                    try:
                        ms_brand_limit = max(5, min(int(ms_brand_limit_str), 100))
                    except (ValueError, TypeError):
                        ms_brand_limit = 30

                    def _run_multi_source_bg(
                        workers: int, delay: float, blimit: int
                    ) -> None:
                        import django

                        django.setup()
                        try:
                            from apps.firmwares.gsmarena_service import (
                                run_multi_source_discovery,
                            )

                            run_multi_source_discovery(
                                max_workers=workers,
                                per_site_delay=delay,
                                brand_limit=blimit,
                            )
                        except Exception:
                            logger.exception("Multi-source scraper failed")

                    t = threading.Thread(
                        target=_run_multi_source_bg,
                        args=(ms_workers, ms_delay, ms_brand_limit),
                        daemon=True,
                    )
                    t.start()
                    message = (
                        f"Multi-source discovery started: {ms_workers} workers,"
                        f" {ms_delay}s delay, {ms_brand_limit} brands/source"
                        " — check Sync Runs for progress"
                    )

            elif action == "harvest_proxies":
                # Manual proxy pool harvest for status display
                try:
                    from apps.firmwares.scraper.proxy_pool import ProxyPool

                    pool = ProxyPool()
                    pool.harvest()
                    ps = pool.get_stats()
                    message = (
                        f"Proxy harvest: {ps['alive']} alive / {ps['dead']} dead"
                        f" from {ps['total_sources']} sources"
                    )
                except Exception as exc:
                    message = f"Proxy harvest failed: {exc}"

        except Exception as exc:
            message = f"Action failed: {exc}"

    try:
        from django.db.models import Sum

        from apps.firmwares.models import IngestionJob, OEMSource, ScraperRun

        stats["total_sources"] = OEMSource.objects.count()
        stats["active_sources"] = OEMSource.objects.filter(is_active=True).count()
        stats["total_runs"] = ScraperRun.objects.count()
        stats["successful_runs"] = ScraperRun.objects.filter(status="success").count()
        stats["items_ingested"] = (
            ScraperRun.objects.aggregate(total=Sum("items_ingested"))["total"] or 0
        )
        stats["pending_review"] = IngestionJob.objects.filter(
            status=IngestionJob.Status.PENDING
        ).count()

        sources = list(
            OEMSource.objects.select_related("brand")
            .order_by("-is_active", "name")[:50]
            .values(
                "id",
                "name",
                "base_url",
                "is_active",
                "auth_type",
                "brand__name",
            )
        )

        recent_runs = list(
            ScraperRun.objects.select_related("config__source")
            .order_by("-started_at")[:25]
            .values(
                "id",
                "config__source__name",
                "status",
                "items_found",
                "items_ingested",
                "started_at",
                "finished_at",
            )
        )

        pending_jobs = list(
            IngestionJob.objects.filter(status=IngestionJob.Status.PENDING)
            .select_related("run__config__source")
            .order_by("-created_at")[:50]
            .values(
                "id",
                "raw_data",
                "run__config__source__name",
                "created_at",
                "error",
            )
        )

        # GSMArena sync data
        from apps.firmwares.models import GSMArenaDevice, SyncRun

        # Auto-cleanup stale runs stuck in "running" for >1 hour
        stale_cutoff = timezone.now() - timedelta(hours=1)
        stale_count = SyncRun.objects.filter(
            status="running", started_at__lt=stale_cutoff
        ).update(status="failed", completed_at=timezone.now())
        if stale_count:
            logger.info("Cleaned up %d stale SyncRun(s) stuck in running", stale_count)

        gsmarena_stats["total_devices"] = GSMArenaDevice.objects.count()
        gsmarena_stats["total_syncs"] = SyncRun.objects.count()
        gsmarena_stats["successful_syncs"] = SyncRun.objects.filter(
            status="success"
        ).count()
        gsmarena_stats["pending_devices"] = GSMArenaDevice.objects.filter(
            review_status=GSMArenaDevice.ReviewStatus.PENDING
        ).count()
        gsmarena_stats["approved_devices"] = GSMArenaDevice.objects.filter(
            review_status=GSMArenaDevice.ReviewStatus.APPROVED
        ).count()

        gsmarena_sync_runs = list(
            SyncRun.objects.order_by("-started_at")[:15].values(
                "id",
                "status",
                "devices_checked",
                "devices_created",
                "devices_updated",
                "method_used",
                "started_at",
                "completed_at",
            )
        )

        # Pending GSMArena devices for review — with brand filter + pagination
        pending_qs = GSMArenaDevice.objects.filter(
            review_status=GSMArenaDevice.ReviewStatus.PENDING,
        ).order_by("brand", "-last_synced_at")

        # Brand filter
        device_brand_filter = (request.GET.get("device_brand") or "").strip()
        if device_brand_filter:
            pending_qs = pending_qs.filter(brand__iexact=device_brand_filter)

        # Distinct brands for the filter dropdown
        pending_brands = list(
            GSMArenaDevice.objects.filter(
                review_status=GSMArenaDevice.ReviewStatus.PENDING,
            )
            .values_list("brand", flat=True)
            .distinct()
            .order_by("brand")
        )

        pending_devices_page = _admin_paginate(request, pending_qs, per_page=25)

        # All scraped devices — browseable table with status filter
        device_status_filter = (request.GET.get("device_status") or "").strip()
        all_devices_qs = GSMArenaDevice.objects.all().order_by("brand", "model_name")
        if device_status_filter:
            all_devices_qs = all_devices_qs.filter(
                review_status=device_status_filter,
            )
        all_device_brand_filter = (request.GET.get("all_device_brand") or "").strip()
        if all_device_brand_filter:
            all_devices_qs = all_devices_qs.filter(
                brand__iexact=all_device_brand_filter,
            )
        all_devices_page = _admin_paginate(
            request,
            all_devices_qs,
            per_page=50,
            page_param="allpage",
        )
        all_devices_brands = list(
            GSMArenaDevice.objects.values_list("brand", flat=True)
            .distinct()
            .order_by("brand")
        )

        # Is scraper currently running?
        scraper_is_running = SyncRun.objects.filter(status="running").exists()

        # Latest probe results (probe runs have method_used="probe")
        probe_results: list[dict[str, Any]] = []
        latest_probe = (
            SyncRun.objects.filter(method_used="probe").order_by("-started_at").first()
        )
        if latest_probe and isinstance(latest_probe.errors, list):
            probe_results = latest_probe.errors

        # Source registry summary + health tracker stats
        source_registry_summary: dict[str, Any] = {}
        source_health_stats: list[dict[str, object]] = []
        try:
            from apps.firmwares.scraper.source_registry import (
                get_enabled_sources,
                get_registry_summary,
                source_health_tracker,
            )

            reg = get_registry_summary()
            source_registry_summary = {
                "total": reg.total,
                "global_count": reg.global_count,
                "regional_count": reg.regional_count,
                "languages": reg.languages,
                "needs_translation": reg.needs_translation,
            }

            # Build health lookup for template enrichment
            health_by_slug: dict[str, dict[str, object]] = {
                h["slug"]: h  # type: ignore[misc]
                for h in source_health_tracker.get_source_stats()
            }

            source_registry_sources = [
                {
                    "name": s.name,
                    "slug": s.slug,
                    "base_url": s.base_url,
                    "scope": s.scope,
                    "language": s.language,
                    "country": s.country,
                    "needs_translation": s.needs_translation,
                    "quality_tier": s.quality_tier,
                    "notes": s.notes,
                    "health": health_by_slug.get(s.slug, {}),
                }
                for s in get_enabled_sources()
            ]
            source_health_stats = source_health_tracker.get_source_stats()
        except Exception:
            source_registry_sources = []

        # Schedule config
        schedule_hours = 0
        ms_schedule_hours = 0
        try:
            from apps.site_settings.models import SiteSettings

            ss = SiteSettings.objects.first()
            if ss:
                schedule_hours = ss.gsmarena_scrape_interval_hours or 0
                ms_schedule_hours = ss.multi_source_scrape_interval_hours or 0
        except Exception:
            logger.debug("Failed to load scraper schedule config")

    except Exception as exc:
        logger.exception("Scraper admin load failed: %s", exc)
        pending_devices_page = None
        pending_brands = []
        device_brand_filter = ""
        all_devices_page = None
        all_devices_brands = []
        all_device_brand_filter = ""
        device_status_filter = ""
        schedule_hours = 0
        ms_schedule_hours = 0
        scraper_is_running = False
        probe_results = []
        source_registry_summary = {}
        source_registry_sources = []
        source_health_stats = []

    return _render_admin(
        request,
        "admin_suite/scraper.html",
        {
            "sources": sources,
            "recent_runs": recent_runs,
            "pending_jobs": pending_jobs,
            "gsmarena_sync_runs": gsmarena_sync_runs,
            "gsmarena_stats": gsmarena_stats,
            "stats": stats,
            "message": message,
            "pending_devices": pending_devices_page,
            "pending_devices_page": pending_devices_page,
            "pending_brands": pending_brands,
            "device_brand_filter": device_brand_filter,
            "all_devices": all_devices_page,
            "all_devices_page": all_devices_page,
            "all_devices_brands": all_devices_brands,
            "all_device_brand_filter": all_device_brand_filter,
            "device_status_filter": device_status_filter,
            "schedule_hours": schedule_hours,
            "ms_schedule_hours": ms_schedule_hours,
            "scraper_is_running": scraper_is_running,
            "probe_results": probe_results,
            "source_registry_summary": source_registry_summary,
            "source_registry_sources": source_registry_sources,
            "source_health_stats": source_health_stats,
        },
        nav_active="firmwares",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Firmwares", "admin_suite:firmwares"),
            ("Scraper", None),
        ),
        subtitle="Multi-Source Device Scraper & Sync",
    )


@staff_member_required
def scraper_status_fragment(request: HttpRequest) -> HttpResponse:
    """HTMX fragment: returns live scraper run status for polling.

    Non-HTMX requests (e.g. page refresh) redirect back to the scraper page
    instead of showing raw JSON.
    """
    from apps.firmwares.models import GSMArenaDevice, SyncRun

    # Non-HTMX request → redirect to scraper page (fixes blank JSON screen)
    if not request.headers.get("HX-Request"):
        from django.shortcuts import redirect

        return redirect("admin_suite:scraper")

    latest_run = SyncRun.objects.order_by("-started_at").first()
    pending_count = GSMArenaDevice.objects.filter(
        review_status=GSMArenaDevice.ReviewStatus.PENDING
    ).count()

    data: dict[str, Any] = {
        "has_run": latest_run is not None,
        "pending_count": pending_count,
    }
    if latest_run:
        data.update(
            {
                "run_id": latest_run.pk,
                "status": latest_run.status,
                "devices_checked": latest_run.devices_checked,
                "devices_created": latest_run.devices_created,
                "devices_updated": latest_run.devices_updated,
                "method_used": latest_run.method_used or "",
                "started_at": (
                    latest_run.started_at.isoformat() if latest_run.started_at else ""
                ),
                "completed_at": (
                    latest_run.completed_at.isoformat()
                    if latest_run.completed_at
                    else ""
                ),
                "is_running": latest_run.status == "running",
                "errors": latest_run.errors or [],
            }
        )
    else:
        data["is_running"] = False

    # If HTMX request, return an HTML fragment for the live progress bar
    if request.headers.get("HX-Request"):
        is_running = data.get("is_running", False)
        if is_running and latest_run:
            html = (
                '<div class="px-5 py-3 bg-blue-500/5 border-b border-blue-500/20"'
                ' hx-get="'
                + request.path
                + '" hx-trigger="every 3s" hx-swap="innerHTML"'
                ' hx-target="#scraper-live-status">'
                '<div class="flex flex-wrap items-center gap-4 text-sm">'
                '<span class="text-blue-400 font-medium">'
                '<i data-lucide="activity" class="w-3.5 h-3.5 inline-block mr-1 animate-pulse"></i>'
                f" Run #{latest_run.pk}"
                "</span>"
                '<span class="text-[var(--color-text-secondary)]">'
                f"Checked: <strong>{latest_run.devices_checked}</strong>"
                "</span>"
                '<span class="text-emerald-400">'
                f"Created: <strong>{latest_run.devices_created}</strong>"
                "</span>"
                '<span class="text-blue-400">'
                f"Updated: <strong>{latest_run.devices_updated}</strong>"
                "</span>"
                '<span class="text-[var(--color-text-muted)]">Refreshing…</span>'
                "</div></div>"
            )
        else:
            # Scraper finished — show final status, stop polling
            status_label = data.get("status", "idle")
            if status_label == "stopped":
                badge_bg = "bg-orange-500/5 border-b border-orange-500/20"
                badge_text = "text-orange-400"
                badge_icon = "octagon"
            elif status_label in ("failed",):
                badge_bg = "bg-red-500/5 border-b border-red-500/20"
                badge_text = "text-red-400"
                badge_icon = "x-circle"
            else:
                badge_bg = "bg-emerald-500/5 border-b border-emerald-500/20"
                badge_text = "text-emerald-400"
                badge_icon = "check-circle"
            html = (
                f'<div class="px-5 py-3 {badge_bg}">'
                '<div class="flex flex-wrap items-center gap-4 text-sm">'
                f'<span class="{badge_text} font-medium">'
                f'<i data-lucide="{badge_icon}" class="w-3.5 h-3.5 inline-block mr-1"></i>'
                f" Last run: {status_label}"
                "</span>"
                f'<span class="text-[var(--color-text-muted)]">Pending: {pending_count}</span>'
                "</div></div>"
            )
        return HttpResponse(html)

    # Fallback — should not reach here due to redirect above
    from django.shortcuts import redirect

    return redirect("admin_suite:scraper")


# =============================================================================
# AUDIT LOG VIEWER (P3)
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_audit_log(request: HttpRequest) -> HttpResponse:
    """Admin audit log — view model changes, admin actions, field diffs."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    q = _admin_search(request)
    stats: dict[str, int] = {
        "total_logs": 0,
        "creates": 0,
        "updates": 0,
        "deletes": 0,
    }

    try:
        from apps.admin.models import AuditLog

        qs = AuditLog.objects.select_related("user").all()
        if q:
            from django.db.models import Q

            qs = qs.filter(
                Q(model_name__icontains=q)
                | Q(object_repr__icontains=q)
                | Q(user__email__icontains=q)
            )

        qs, sort_field, sort_dir = _admin_sort(
            request,
            qs,
            {
                "user": "user__email",
                "action": "action",
                "model": "model_name",
                "time": "timestamp",
            },
            default_sort="-timestamp",
        )
        page_obj = _admin_paginate(request, qs, per_page=50)

        stats["total_logs"] = AuditLog.objects.count()
        stats["creates"] = AuditLog.objects.filter(action="create").count()
        stats["updates"] = AuditLog.objects.filter(action="update").count()
        stats["deletes"] = AuditLog.objects.filter(action="delete").count()
    except Exception as exc:
        logger.debug("Audit log load failed: %s", exc)
        page_obj = None
        sort_field, sort_dir = "", "asc"

    return _render_admin(
        request,
        "admin_suite/audit_log.html",
        {
            "logs": page_obj,
            "page_obj": page_obj,
            "q": q,
            "sort": sort_field,
            "dir": sort_dir,
            "stats": stats,
        },
        nav_active="audit",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Audit Log", None),
        ),
        subtitle="Model changes and admin actions",
    )


# =============================================================================
# CELERY TASK MONITORING (P3)
# =============================================================================


@csrf_protect
@staff_member_required
def admin_suite_celery(request: HttpRequest) -> HttpResponse:
    """Celery task monitoring — workers, active tasks, beat schedule."""
    if not getattr(settings, "ADMIN_SUITE_ENABLED", True):
        raise _ADMIN_DISABLED

    workers: list[dict[str, Any]] = []
    active_tasks: list[dict[str, Any]] = []
    scheduled_tasks: list[dict[str, Any]] = []
    registered_tasks: list[str] = []
    stats: dict[str, int | str] = {
        "worker_count": 0,
        "active_count": 0,
        "registered_count": 0,
        "broker": "unknown",
    }

    try:
        from app.celery import app as celery_app

        stats["broker"] = str(celery_app.conf.broker_url or "not configured")

        # Beat schedule from settings
        beat = getattr(celery_app.conf, "beat_schedule", {})
        for name, entry in beat.items():
            scheduled_tasks.append(
                {
                    "name": name,
                    "task": entry.get("task", ""),
                    "schedule": str(entry.get("schedule", "")),
                }
            )

        # Try to inspect live workers (may timeout if no workers running)
        try:
            inspector = celery_app.control.inspect(timeout=2.0)
            active = inspector.active() or {}
            registered = inspector.registered() or {}
            for worker_name, tasks in active.items():
                workers.append(
                    {
                        "name": worker_name,
                        "active": len(tasks),
                    }
                )
                for t in tasks:
                    active_tasks.append(
                        {
                            "id": t.get("id", ""),
                            "name": t.get("name", ""),
                            "worker": worker_name,
                            "started": t.get("time_start", ""),
                        }
                    )
            for _worker_name, tasks in registered.items():
                for t in tasks:
                    if t not in registered_tasks:
                        registered_tasks.append(t)
            stats["worker_count"] = len(workers)
            stats["active_count"] = len(active_tasks)
            stats["registered_count"] = len(registered_tasks)
        except Exception:
            # Workers not running or Redis not available
            stats["worker_count"] = 0
    except Exception as exc:
        logger.debug("Celery monitoring load failed: %s", exc)

    return _render_admin(
        request,
        "admin_suite/celery.html",
        {
            "workers": workers,
            "active_tasks": active_tasks,
            "scheduled_tasks": scheduled_tasks,
            "registered_tasks": sorted(registered_tasks),
            "stats": stats,
        },
        nav_active="celery",
        breadcrumb=_make_breadcrumb(
            ("Admin Home", "admin_suite:admin_suite"),
            ("Celery", None),
        ),
        subtitle="Task queue monitoring",
    )
