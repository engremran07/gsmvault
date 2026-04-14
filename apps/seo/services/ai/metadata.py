from __future__ import annotations

from django.utils import timezone
from django.utils.text import slugify

from apps.core import ai_client
from apps.core.utils import feature_flags
from apps.seo.models import BatchOperation, SeoEntity, SeoEntityEdge
from apps.seo.services.scoring.serp import run_seo_audit


def generate_metadata(text: str, user) -> dict:
    if not feature_flags.seo_enabled() or not feature_flags.auto_meta_enabled():
        return {}
    title = ai_client.generate_title(text, user)
    description = ai_client.generate_excerpt(text, user)
    keywords = ", ".join(ai_client.suggest_tags(text, user))
    return {
        "meta_title": title,
        "meta_description": description,
        "focus_keywords": [k.strip() for k in keywords.split(",") if k.strip()],
    }


def upsert_entity(
    name: str, entity_type: str, attributes: dict | None = None
) -> SeoEntity:
    slug = slugify(name)[:255]
    entity, _ = SeoEntity.objects.update_or_create(
        slug=slug,
        defaults={
            "name": name,
            "entity_type": entity_type,
            "attributes": attributes or {},
            "is_active": True,
        },
    )
    return entity


def connect_entities(
    source: SeoEntity, target: SeoEntity, relation_type: str, weight: float = 1.0
) -> SeoEntityEdge:
    edge, _ = SeoEntityEdge.objects.update_or_create(
        source=source,
        target=target,
        relation_type=relation_type,
        defaults={"weight": weight},
    )
    return edge


def start_batch(operation: BatchOperation) -> BatchOperation:
    operation.status = BatchOperation.Status.RUNNING
    operation.started_at = timezone.now()
    operation.save(update_fields=["status", "started_at", "updated_at"])
    return operation


def complete_batch(operation: BatchOperation, result: dict) -> BatchOperation:
    operation.status = BatchOperation.Status.COMPLETED
    operation.result = result
    operation.completed_at = timezone.now()
    operation.save(update_fields=["status", "result", "completed_at", "updated_at"])
    return operation


def fail_batch(operation: BatchOperation, error_message: str) -> BatchOperation:
    operation.status = BatchOperation.Status.FAILED
    operation.result = {"error": error_message}
    operation.completed_at = timezone.now()
    operation.save(update_fields=["status", "result", "completed_at", "updated_at"])
    return operation


def run_batch(operation: BatchOperation) -> BatchOperation:
    start_batch(operation)
    try:
        payload = operation.payload or {}

        if operation.operation_type == BatchOperation.OperationType.AUDIT:
            result = run_seo_audit(metadata=None, html=payload.get("html", ""))
            return complete_batch(operation, result)

        if operation.operation_type == BatchOperation.OperationType.KNOWLEDGE_GRAPH:
            source_name = payload.get("source_name", "")
            target_name = payload.get("target_name", "")
            source_type = payload.get("source_type", "generic")
            target_type = payload.get("target_type", "generic")
            relation_type = payload.get("relation_type", "related_to")
            weight = float(payload.get("weight", 1.0))
            source_entity = upsert_entity(source_name, source_type)
            target_entity = upsert_entity(target_name, target_type)
            edge = connect_entities(source_entity, target_entity, relation_type, weight)
            return complete_batch(operation, {"edge_id": edge.pk})

        if operation.operation_type in {
            BatchOperation.OperationType.METADATA,
            BatchOperation.OperationType.INTERLINK,
        }:
            return complete_batch(operation, {"status": "accepted", "payload": payload})

        return fail_batch(operation, "Unsupported batch operation type")
    except Exception as exc:
        return fail_batch(operation, str(exc))
