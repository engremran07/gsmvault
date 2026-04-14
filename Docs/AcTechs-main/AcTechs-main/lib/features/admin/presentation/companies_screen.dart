import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/utils/base64_image_codec.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/data/company_repository.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key});

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  Future<void> _showCompanyDialog([CompanyModel? company]) async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: company?.name ?? '');
    final formKey = GlobalKey<FormState>();
    // logoBase64 held in dialog-local state via StatefulBuilder
    String pendingLogo = company?.logoBase64 ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(company == null ? l.addCompany : l.editCompany),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo picker ──
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result == null) return;
                      final bytes = result.files.first.bytes;
                      if (bytes == null) return;
                      if (!Base64ImageCodec.isWithinRecommendedLogoLimit(
                        bytes,
                      )) {
                        if (ctx.mounted) {
                          AppFeedback.error(ctx, message: l.logoTooLarge);
                        }
                        return;
                      }
                      setDialogState(
                        () => pendingLogo = Base64ImageCodec.encode(bytes),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ArcticTheme.arcticCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ArcticTheme.arcticBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: pendingLogo.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: ArcticTheme.arcticBlue,
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.tapToUploadLogo,
                                  style: Theme.of(ctx).textTheme.bodySmall,
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: _CompanyLogoPreview(
                                    logoBase64: pendingLogo,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setDialogState(() => pendingLogo = ''),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: ArcticTheme.arcticError,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onError,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result == null) return;
                          final bytes = result.files.first.bytes;
                          if (bytes == null) return;
                          if (!Base64ImageCodec.isWithinRecommendedLogoLimit(
                            bytes,
                          )) {
                            if (ctx.mounted) {
                              AppFeedback.error(ctx, message: l.logoTooLarge);
                            }
                            return;
                          }
                          setDialogState(
                            () => pendingLogo = Base64ImageCodec.encode(bytes),
                          );
                        },
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(
                          pendingLogo.isEmpty ? l.uploadLogo : l.replaceLogo,
                        ),
                      ),
                      if (pendingLogo.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              setDialogState(() => pendingLogo = ''),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(l.removeLogo),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ArcticTheme.arcticError,
                            side: const BorderSide(
                              color: ArcticTheme.arcticError,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.companyName,
                      prefixIcon: const Icon(Icons.apartment_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l.required
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      if (company == null) {
        await ref
            .read(companyRepositoryProvider)
            .createCompany(
              name: nameCtrl.text.trim(),
              invoicePrefix: '',
              logoBase64: pendingLogo,
            );
        if (!mounted) return;
        AppFeedback.success(context, message: l.companyCreated);
      } else {
        await ref
            .read(companyRepositoryProvider)
            .updateCompany(
              id: company.id,
              name: nameCtrl.text.trim(),
              invoicePrefix: company.invoicePrefix,
              logoBase64: pendingLogo,
            );
        if (!mounted) return;
        AppFeedback.success(context, message: l.companyUpdated);
      }
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _toggleCompany(CompanyModel company, bool isActive) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(companyRepositoryProvider)
          .toggleCompanyActive(company.id, isActive);
      if (!mounted) return;
      AppFeedback.success(
        context,
        message: isActive ? l.companyActivated : l.companyDeactivated,
      );
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(allCompaniesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.companies)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCompanyDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(l.addCompany),
      ),
      body: SafeArea(
        child: companiesAsync.when(
          data: (companies) {
            if (companies.isEmpty) {
              return Center(
                child: Text(
                  l.noCompaniesYet,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }

            return ArcticRefreshIndicator(
              onRefresh: () async => ref.invalidate(allCompaniesProvider),
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 100),
                itemCount: companies.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return ArcticCard(
                        onTap: () => _showCompanyDialog(company),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: ArcticTheme.arcticBlue.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: company.logoBase64.isNotEmpty
                                  ? _CompanyLogoPreview(
                                      logoBase64: company.logoBase64,
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(
                                      Icons.apartment_rounded,
                                      color: ArcticTheme.arcticBlue,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: company.isActive,
                              activeTrackColor: ArcticTheme.arcticSuccess,
                              onChanged: (value) =>
                                  _toggleCompany(company, value),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 60).ms)
                      .slideX(begin: 0.03);
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: ArcticShimmer(count: 5),
          ),
          error: (error, _) => error is AppException
              ? Center(child: ErrorCard(exception: error))
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _CompanyLogoPreview extends StatelessWidget {
  const _CompanyLogoPreview({
    required this.logoBase64,
    this.fit = BoxFit.contain,
  });

  final String logoBase64;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = Base64ImageCodec.tryDecodeBytes(logoBase64);
    if (bytes == null) {
      return const Icon(
        Icons.broken_image_outlined,
        color: ArcticTheme.arcticTextSecondary,
      );
    }

    final svgText = Base64ImageCodec.tryDecodeSvgBytes(bytes);
    if (svgText != null) {
      return SvgPicture.memory(bytes, fit: fit);
    }

    return Image.memory(bytes, fit: fit);
  }
}
