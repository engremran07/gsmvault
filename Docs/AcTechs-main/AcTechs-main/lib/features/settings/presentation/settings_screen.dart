import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ac_techs/core/utils/base64_image_codec.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/core/utils/whatsapp_launcher.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/auth/data/auth_repository.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';
import 'package:ac_techs/features/settings/providers/app_branding_provider.dart';
import 'package:ac_techs/features/settings/data/approval_config_repository.dart';
import 'package:ac_techs/features/settings/data/app_branding_repository.dart';
import 'package:ac_techs/core/providers/app_build_provider.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sendingReset = false;

  static const String _supportPhoneSaudi = '00966530421571';
  static const String _supportPhonePakistan = '00923067863310';

  String _displayAppBrandingName(
    AppLocalizations l,
    AppBrandingConfig branding,
  ) {
    final name = branding.companyName.trim();
    return name.isEmpty ? l.ambiguousCompanyName : name;
  }

  Future<void> _launchCall(String rawPhone) async {
    final normalized = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    if (normalized.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: normalized);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> _confirmDiscardChangesDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.discardChangesTitle),
            content: Text(l.discardChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l.leavePage),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);
    final approvalConfigAsync = ref.watch(approvalConfigProvider);
    final appBrandingAsync = ref.watch(appBrandingProvider);
    final appBuildAsync = ref.watch(appBuildNumberProvider);
    final appVersionAsync = ref.watch(appVersionLabelProvider);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ──
          _ProfileHeader(
            name: user?.name ?? 'User',
            email: user?.email ?? '',
            role: user?.role ?? 'technician',
            onEditTap: user == null
                ? null
                : () => _showEditProfileDialog(context, user),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 24),

          // ── Theme Section ──
          _SectionTitle(title: l.appearance),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              children: [
                _ThemeTile(
                  icon: Icons.brightness_auto_rounded,
                  label: l.themeAuto,
                  sublabel: l.themeAutoDesc,
                  selected: themeMode == AppThemeMode.auto,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.auto),
                ),
                const Divider(height: 1),
                _ThemeTile(
                  icon: Icons.dark_mode_rounded,
                  label: l.themeDark,
                  sublabel: l.themeDarkDesc,
                  selected: themeMode == AppThemeMode.dark,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.dark),
                ),
                const Divider(height: 1),
                _ThemeTile(
                  icon: Icons.light_mode_rounded,
                  label: l.themeLight,
                  sublabel: l.themeLightDesc,
                  selected: themeMode == AppThemeMode.light,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.light),
                ),
                const Divider(height: 1),
                _ThemeTile(
                  icon: Icons.contrast_rounded,
                  label: l.themeHighContrast,
                  sublabel: l.themeHighContrastDesc,
                  selected: themeMode == AppThemeMode.highContrast,
                  onTap: () => ref
                      .read(appThemeModeProvider.notifier)
                      .setMode(AppThemeMode.highContrast),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),

          // ── Language Section ──
          _SectionTitle(title: l.language),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              children: [
                _LanguageTile(
                  flag: '🇬🇧',
                  label: l.english,
                  selected: locale == 'en',
                  onTap: () => _updateLanguage('en'),
                ),
                const Divider(height: 1),
                _LanguageTile(
                  flag: '🇵🇰',
                  label: l.urdu,
                  selected: locale == 'ur',
                  onTap: () => _updateLanguage('ur'),
                ),
                const Divider(height: 1),
                _LanguageTile(
                  flag: '🇸🇦',
                  label: l.arabic,
                  selected: locale == 'ar',
                  onTap: () => _updateLanguage('ar'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),

          _SectionTitle(title: l.companyBranding),
          const SizedBox(height: 8),
          ArcticCard(
            child: appBrandingAsync.when(
              data: (branding) {
                final displayName = _displayAppBrandingName(l, branding);
                final logoBase64 = branding.logoBase64.trim();
                final phoneNumber = branding.phoneNumber.trim();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: ArcticTheme.arcticBlue.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: logoBase64.isNotEmpty
                              ? _BrandLogoPreview(logoBase64: logoBase64)
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
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l.region}: ${l.pakistan}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: ArcticTheme.arcticTextSecondary,
                                    ),
                              ),
                              if (phoneNumber.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  phoneNumber,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: ArcticTheme.arcticTextSecondary,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const _PakistanFlagBadge(),
                      ],
                    ),
                    if (user?.isAdmin ?? false) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showAppBrandingDialog(branding),
                            icon: const Icon(Icons.business_rounded),
                            label: Text(l.editOwnCompanyBranding),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.push('/admin/companies'),
                            icon: const Icon(Icons.image_outlined),
                            label: Text(l.manageClientCompanyBranding),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        color: ArcticTheme.arcticBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.ambiguousCompanyName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const _PakistanFlagBadge(),
                    ],
                  ),
                  if (user?.isAdmin ?? false) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showAppBrandingDialog(
                            AppBrandingConfig.defaults(),
                          ),
                          icon: const Icon(Icons.business_rounded),
                          label: Text(l.editOwnCompanyBranding),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/admin/companies'),
                          icon: const Icon(Icons.image_outlined),
                          label: Text(l.manageClientCompanyBranding),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),

          if (user?.isAdmin ?? false) ...[
            _SectionTitle(title: '${l.approvals} ${l.settings}'),
            const SizedBox(height: 8),
            ArcticCard(
              child: approvalConfigAsync.when(
                data: (config) => Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text('${l.jobs} ${l.approvals}'),
                      subtitle: Text(l.required),
                      value: config.jobApprovalRequired,
                      onChanged: (value) => _toggleJobApproval(value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(l.sharedInstallApprovalRequired),
                      subtitle: Text(l.required),
                      value: config.sharedJobApprovalRequired,
                      onChanged: (value) => _toggleSharedJobApproval(value),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text('${l.inOut} ${l.approvals}'),
                      subtitle: Text(l.required),
                      value: config.inOutApprovalRequired,
                      onChanged: (value) => _toggleInOutApproval(value),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(l.lockRecordsBefore),
                      subtitle: Text(
                        config.lockedBeforeDate == null
                            ? l.noPeriodLock
                            : '${MaterialLocalizations.of(context).formatMediumDate(config.lockedBeforeDate!)} • ${l.lockedPeriodDescription}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (config.lockedBeforeDate != null)
                            IconButton(
                              onPressed: _clearLockedBeforeDate,
                              icon: const Icon(Icons.lock_open_rounded),
                              tooltip: l.clearPeriodLock,
                            ),
                          IconButton(
                            onPressed: () =>
                                _editLockedBeforeDate(config.lockedBeforeDate),
                            icon: const Icon(Icons.event_busy_rounded),
                            tooltip: l.lockRecordsBefore,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l.couldNotExport),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.03),
            const SizedBox(height: 24),
          ],

          // ── App Info ──
          _SectionTitle(title: l.about),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ArcticTheme.arcticBlue.withValues(alpha: 0.18),
                        ArcticTheme.arcticBlueDark.withValues(alpha: 0.08),
                      ],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: ArcticTheme.arcticBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      appBrandingAsync.maybeWhen(
                        data: (branding) {
                          final logoBase64 = branding.logoBase64.trim();
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: ArcticTheme.arcticBlue.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: logoBase64.isNotEmpty
                                ? _BrandLogoPreview(logoBase64: logoBase64)
                                : const Icon(
                                    Icons.ac_unit_rounded,
                                    color: ArcticTheme.arcticBlue,
                                  ),
                          );
                        },
                        orElse: () => Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: ArcticTheme.arcticBlue.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.ac_unit_rounded,
                            color: ArcticTheme.arcticBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appBrandingAsync.maybeWhen(
                                data: (branding) =>
                                    _displayAppBrandingName(l, branding),
                                orElse: () => 'AC Techs',
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.adminAboutBuiltBy,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _AboutBadge(
                                  icon: Icons.info_outline_rounded,
                                  text:
                                      '${l.version}: ${appVersionAsync.maybeWhen(data: (value) => value, orElse: () => '...')}',
                                ),
                                _AboutBadge(
                                  icon: Icons.numbers_rounded,
                                  text:
                                      '${l.currentBuild}: ${appBuildAsync.maybeWhen(data: (value) => '$value', orElse: () => '...')}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DevelopedBySignature(label: l.developedByMuhammadImran),
                const SizedBox(height: 16),
                _SupportContactRow(
                  countryLabel: l.saudiArabia,
                  phoneNumber: _supportPhoneSaudi,
                  onCallTap: () => _launchCall(_supportPhoneSaudi),
                  onWhatsAppTap: () =>
                      WhatsAppLauncher.openChat(_supportPhoneSaudi),
                ),
                const SizedBox(height: 10),
                _SupportContactRow(
                  countryLabel: l.pakistan,
                  phoneNumber: _supportPhonePakistan,
                  onCallTap: () => _launchCall(_supportPhonePakistan),
                  onWhatsAppTap: () =>
                      WhatsAppLauncher.openChat(_supportPhonePakistan),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.03),
          const SizedBox(height: 24),

          // ── Security ──
          _SectionTitle(title: l.resetPassword),
          const SizedBox(height: 8),
          ArcticCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.alternate_email_rounded),
                  title: Text(l.changeEmail),
                  subtitle: Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: user == null
                      ? null
                      : () => _showChangeEmailDialog(user),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: const Icon(Icons.password_rounded),
                  title: Text(l.changePassword),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: user == null ? null : _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: _sendingReset
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_rounded),
                  title: Text(l.resetPassword),
                  subtitle: Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap:
                      _sendingReset ||
                          user?.email == null ||
                          (user?.email.isEmpty ?? true)
                      ? null
                      : () => _handlePasswordReset(user!.email),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.03),
          const SizedBox(height: 32),

          // ── Sign Out ──
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await _confirmSignOut(context);
              if (!confirmed) return;
              await ref.read(signInProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArcticTheme.arcticError,
              side: const BorderSide(color: ArcticTheme.arcticError),
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _updateLanguage(String lang) {
    ref.read(appLocaleProvider.notifier).setLocale(lang);
  }

  Future<void> _toggleJobApproval(bool value) async {
    try {
      await ref
          .read(approvalConfigRepositoryProvider)
          .setJobApprovalRequired(value);
    } on Exception {
      if (!mounted) return;
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.couldNotExport,
      );
    }
  }

  Future<void> _toggleInOutApproval(bool value) async {
    try {
      await ref
          .read(approvalConfigRepositoryProvider)
          .setInOutApprovalRequired(value);
    } on Exception {
      if (!mounted) return;
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.couldNotExport,
      );
    }
  }

  Future<void> _toggleSharedJobApproval(bool value) async {
    try {
      await ref
          .read(approvalConfigRepositoryProvider)
          .setSharedJobApprovalRequired(value);
    } on Exception {
      if (!mounted) return;
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.couldNotExport,
      );
    }
  }

  Future<void> _editLockedBeforeDate(DateTime? initialValue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialValue ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final normalized = DateTime(picked.year, picked.month, picked.day);
    try {
      await ref
          .read(approvalConfigRepositoryProvider)
          .setLockedBeforeDate(normalized);
    } on Exception {
      if (!mounted) return;
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.couldNotExport,
      );
    }
  }

  Future<void> _clearLockedBeforeDate() async {
    try {
      await ref
          .read(approvalConfigRepositoryProvider)
          .setLockedBeforeDate(null);
    } on Exception {
      if (!mounted) return;
      ErrorSnackbar.show(
        context,
        message: AppLocalizations.of(context)!.couldNotExport,
      );
    }
  }

  Future<void> _handlePasswordReset(String email) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.passwordResetConfirmTitle),
        content: Text(l.passwordResetConfirmBody(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.send),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sendingReset = true);
    try {
      await ref.read(userRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      // Rich success dialog with spam-folder guidance
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 48),
          title: Text(l.passwordResetEmailSentTitle),
          content: Text(l.passwordResetEmailSentBody(email)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.confirm),
            ),
          ],
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, message: e.message(locale));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    UserModel user,
  ) async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();
    final locale = Localizations.localeOf(context).languageCode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editProfile),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.changeYourName, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.name,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.required : null,
              ),
              const SizedBox(height: 8),
              // Email is display-only (changing auth email requires reauth)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined),
                title: Text(
                  user.email,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                subtitle: Text(
                  l.changeEmail,
                  style: Theme.of(ctx).textTheme.labelSmall,
                ),
              ),
            ],
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
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .updateDisplayName(nameCtrl.text.trim());
      if (!context.mounted) return;
      AppFeedback.success(context, message: l.profileUpdated);
    } on AppException catch (e) {
      if (!context.mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _showChangeEmailDialog(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final emailCtrl = TextEditingController(text: user.email);
    final currentPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.changeEmail),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.email,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.enterEmail;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: currentPasswordCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.currentPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l.enterPassword : null,
              ),
            ],
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
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .updateEmail(
            newEmail: emailCtrl.text.trim(),
            currentPassword: currentPasswordCtrl.text,
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.emailChangeVerificationSent);
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    } finally {
      emailCtrl.dispose();
      currentPasswordCtrl.dispose();
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.changePassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordCtrl,
                obscureText: true,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.currentPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l.enterPassword : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordCtrl,
                obscureText: true,
                textInputAction: TextInputAction.next,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.newPassword,
                  prefixIcon: const Icon(Icons.password_rounded),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.enterPassword;
                  if (v.length < 6) return l.minChars(6);
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enableInteractiveSelection: true,
                decoration: InputDecoration(
                  hintText: l.confirmNewPassword,
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.required;
                  if (v != newPasswordCtrl.text) return l.passwordsDoNotMatch;
                  return null;
                },
              ),
            ],
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
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(
            currentPassword: currentPasswordCtrl.text,
            newPassword: newPasswordCtrl.text,
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.passwordUpdated);
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    } finally {
      currentPasswordCtrl.dispose();
      newPasswordCtrl.dispose();
      confirmPasswordCtrl.dispose();
    }
  }

  Future<bool> _confirmSignOut(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.signOut),
            content: Text(l.signOutConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArcticTheme.arcticError,
                ),
                child: Text(l.signOut),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showAppBrandingDialog(AppBrandingConfig branding) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final nameCtrl = TextEditingController(text: branding.companyName);
    final phoneCtrl = TextEditingController(text: branding.phoneNumber);
    final formKey = GlobalKey<FormState>();
    String pendingLogo = branding.logoBase64;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final hasChanges =
              nameCtrl.text.trim() != branding.companyName.trim() ||
              phoneCtrl.text.trim() != branding.phoneNumber.trim() ||
              pendingLogo != branding.logoBase64;

          Future<void> maybeCloseDialog() async {
            if (!hasChanges) {
              Navigator.pop(ctx, false);
              return;
            }

            final discard = await _confirmDiscardChangesDialog(ctx);
            if (discard && ctx.mounted) {
              Navigator.pop(ctx, false);
            }
          }

          return PopScope(
            canPop: !hasChanges,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              await maybeCloseDialog();
            },
            child: AlertDialog(
              title: Text(l.editOwnCompanyBranding),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          height: 88,
                          decoration: BoxDecoration(
                            color: ArcticTheme.arcticCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ArcticTheme.arcticBlue.withValues(
                                alpha: 0.3,
                              ),
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
                                      child: _BrandLogoPreview(
                                        logoBase64: pendingLogo,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setDialogState(
                                          () => pendingLogo = '',
                                        ),
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
                                              ctx,
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
                                  AppFeedback.error(
                                    ctx,
                                    message: l.logoTooLarge,
                                  );
                                }
                                return;
                              }
                              setDialogState(
                                () => pendingLogo = Base64ImageCodec.encode(
                                  bytes,
                                ),
                              );
                            },
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(
                              pendingLogo.isEmpty
                                  ? l.uploadLogo
                                  : l.replaceLogo,
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
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: l.companyName,
                          prefixIcon: const Icon(Icons.business_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.phone,
                        enableInteractiveSelection: true,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          hintText: l.companyPhoneNumber,
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) return null;
                          return trimmed.length < 7 ? l.enterValidPhone : null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: maybeCloseDialog, child: Text(l.cancel)),
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
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(appBrandingRepositoryProvider)
          .saveConfig(
            AppBrandingConfig(
              companyName: nameCtrl.text.trim(),
              phoneNumber: phoneCtrl.text.trim(),
              logoBase64: pendingLogo,
            ),
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.ownCompanyBrandingUpdated);
    } on AppException catch (error) {
      if (!mounted) return;
      AppFeedback.error(context, message: error.message(locale));
    }
  }
}

// ── Private Widgets ──

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
    this.onEditTap,
  });

  final String name;
  final String email;
  final String role;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return ArcticCard(
      onTap: onEditTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isAdmin
                    ? [ArcticTheme.arcticWarning, ArcticTheme.arcticWarningDark]
                    : [ArcticTheme.arcticBlue, ArcticTheme.arcticBlueDark],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isAdmin
                                ? ArcticTheme.arcticWarning
                                : ArcticTheme.arcticBlue)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAdmin
                        ? (AppLocalizations.of(context)?.administrator ??
                              'Administrator')
                        : (AppLocalizations.of(context)?.technician ??
                              'Technician'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isAdmin
                          ? ArcticTheme.arcticWarning
                          : ArcticTheme.arcticBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onEditTap != null)
            const Icon(
              Icons.edit_rounded,
              size: 18,
              color: ArcticTheme.arcticTextSecondary,
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(sublabel, style: Theme.of(context).textTheme.bodySmall),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Text(
        flag,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontSize: 24),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _AboutBadge extends StatelessWidget {
  const _AboutBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ArcticTheme.arcticBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ArcticTheme.arcticBlue.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ArcticTheme.arcticBlue),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SupportContactRow extends StatelessWidget {
  const _SupportContactRow({
    required this.countryLabel,
    required this.phoneNumber,
    required this.onCallTap,
    required this.onWhatsAppTap,
  });

  final String countryLabel;
  final String phoneNumber;
  final VoidCallback onCallTap;
  final VoidCallback onWhatsAppTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: onCallTap,
          tooltip: AppLocalizations.of(context)!.call,
          icon: const Icon(Icons.call_rounded, size: 18),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: onWhatsAppTap,
          tooltip: AppLocalizations.of(context)!.whatsApp,
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
        ),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(countryLabel, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(phoneNumber, style: textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }
}

class _DevelopedBySignature extends StatelessWidget {
  const _DevelopedBySignature({required this.label});

  final String label;

  static const String _heartSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="heartGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ff8a9b"/>
      <stop offset="100%" stop-color="#d90429"/>
    </linearGradient>
  </defs>
  <path d="M32 56c-1.1 0-2.2-.4-3.1-1.2C12.2 39.7 4 31.9 4 20.5 4 12.6 10.3 6 18.2 6c5 0 9.6 2.4 12.5 6.4C33.6 8.4 38.2 6 43.2 6 51.1 6 57.4 12.6 57.4 20.5c0 11.4-8.2 19.2-24.9 34.3-.9.8-2 1.2-3.1 1.2z" fill="url(#heartGradient)"/>
  <path d="M43.2 10c-4.3 0-8.2 2.3-10.3 6.1L32 17.7l-.9-1.6C29 12.3 25.1 10 20.8 10 14.8 10 10 14.9 10 20.9c0 9 6.7 15.6 22 29.5 15.3-13.9 22-20.5 22-29.5C54 14.9 49.2 10 43.2 10z" fill="#fff" fill-opacity="0.18"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ArcticTheme.arcticTextSecondary,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(width: 14, height: 14, child: SvgPicture.string(_heartSvg)),
      ],
    );
  }
}

class _BrandLogoPreview extends StatelessWidget {
  const _BrandLogoPreview({required this.logoBase64});

  final String logoBase64;

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
      return SvgPicture.memory(bytes, fit: BoxFit.contain);
    }

    return Image.memory(bytes, fit: BoxFit.contain);
  }
}

class _PakistanFlagBadge extends StatelessWidget {
  const _PakistanFlagBadge();

  static const String _flagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 480">
  <rect width="640" height="480" fill="#01411C"/>
  <rect width="160" height="480" fill="#fff"/>
  <circle cx="390" cy="220" r="110" fill="#fff"/>
  <circle cx="420" cy="200" r="100" fill="#01411C"/>
  <path d="M430 110l22 64h67l-54 39 20 64-55-40-55 40 21-64-55-39h68z" fill="#fff"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 28,
        height: 20,
        child: SvgPicture.string(_flagSvg, fit: BoxFit.cover),
      ),
    );
  }
}
