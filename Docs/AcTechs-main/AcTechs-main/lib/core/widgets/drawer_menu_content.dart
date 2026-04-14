import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/providers/app_build_provider.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/widgets/zoom_drawer.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// Menu items layout shown inside the [ZoomDrawerWrapper].
///
/// Adapts to the logged-in user's role (technician vs admin) and shows
/// different navigation items accordingly.  All strings are localised,
/// the active route is highlighted, and the drawer closes on selection.
class DrawerMenuContent extends ConsumerWidget {
  const DrawerMenuContent({super.key, required this.isAdmin});

  /// When `true` the menu renders admin navigation items; otherwise tech items.
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider).value;
    final versionAsync = ref.watch(appVersionLabelProvider);
    final locale = ref.watch(appLocaleProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User header ──
            const SizedBox(height: 16),
            _UserHeader(
              name: user?.name ?? '...',
              role: isAdmin ? l.admin : l.technician,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 24),
            Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              height: 1,
            ),
            const SizedBox(height: 12),

            // ── Navigation items ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isAdmin)
                      ..._adminItems(context, l, location, colorScheme)
                    else
                      ..._techItems(context, l, location, colorScheme),
                  ],
                ),
              ),
            ),

            // ── Language switcher ──
            Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              height: 1,
            ),
            const SizedBox(height: 8),
            _LanguageSwitcher(
              currentLocale: locale,
              onLocaleChanged: (newLocale) {
                ref.read(appLocaleProvider.notifier).setLocale(newLocale);
              },
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 8),

            // ── Sign out ──
            _DrawerMenuItem(
              icon: Icons.logout_rounded,
              label: l.signOut,
              isActive: false,
              activeColor: colorScheme.error,
              defaultColor: colorScheme.error.withValues(alpha: 0.8),
              onTap: () => _confirmSignOut(context, ref, l),
            ),
            const SizedBox(height: 8),

            // ── Version ──
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
              child: Text(
                versionAsync.maybeWhen(data: (v) => 'v$v', orElse: () => ''),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tech navigation items ──────────────────────────────────────────────

  /// Only items NOT in the bottom navigation bar.
  /// Bottom nav already has: Home, Submit, In-Out, History, Reports.
  List<Widget> _techItems(
    BuildContext context,
    AppLocalizations l,
    String location,
    ColorScheme cs,
  ) {
    return [
      _DrawerMenuItem(
        icon: Icons.ac_unit_rounded,
        label: l.acInstallations,
        isActive: location.startsWith('/tech/ac-installs'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/tech/ac-installs'),
      ),
      _DrawerMenuItem(
        icon: Icons.receipt_long_rounded,
        label: l.settlements,
        isActive: location.startsWith('/tech/settlements'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/tech/settlements'),
      ),
      _DrawerMenuItem(
        icon: Icons.settings_rounded,
        label: l.settings,
        isActive: location.startsWith('/tech/settings'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/tech/settings'),
      ),
    ];
  }

  // ── Admin navigation items ─────────────────────────────────────────────

  /// Only items NOT in the bottom navigation bar.
  /// Bottom nav already has: Dashboard, Approvals, Analytics, Team.
  List<Widget> _adminItems(
    BuildContext context,
    AppLocalizations l,
    String location,
    ColorScheme cs,
  ) {
    return [
      _DrawerMenuItem(
        icon: Icons.business_rounded,
        label: l.companies,
        isActive: location.startsWith('/admin/companies'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/admin/companies'),
      ),
      _DrawerMenuItem(
        icon: Icons.file_upload_rounded,
        label: l.importData,
        isActive: location.startsWith('/admin/import'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/admin/import'),
      ),
      _DrawerMenuItem(
        icon: Icons.receipt_long_rounded,
        label: l.settlements,
        isActive: location.startsWith('/admin/settlements'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/admin/settlements'),
      ),
      _DrawerMenuItem(
        icon: Icons.compare_arrows_rounded,
        label: l.reconciliation,
        isActive: location.startsWith('/admin/reconcile'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/admin/reconcile'),
      ),
      _DrawerMenuItem(
        icon: Icons.settings_rounded,
        label: l.settings,
        isActive: location.startsWith('/admin/settings'),
        activeColor: cs.primary,
        onTap: () => _navigate(context, '/admin/settings'),
      ),
      _DrawerMenuItem(
        icon: Icons.delete_forever_rounded,
        label: l.flushDatabase,
        isActive: location.startsWith('/admin/flush'),
        activeColor: cs.error,
        defaultColor: cs.error.withValues(alpha: 0.7),
        onTap: () => _navigate(context, '/admin/flush'),
      ),
    ];
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _navigate(BuildContext context, String path) {
    ZoomDrawerScope.of(context).close();
    // Use a short delay to let the drawer animation settle before navigating.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (context.mounted) {
        // Push instead of go so the route is added to the back stack.
        // This lets swipe-back / system-back pop to the previous screen
        // instead of closing the app.
        context.push(path);
      }
    });
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.signOut),
        content: Text(l.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ZoomDrawerScope.of(context).close();
      await ref.read(signInProvider.notifier).signOut();
    }
  }
}

// ── Private widgets ─────────────────────────────────────────────────────────

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.name,
    required this.role,
    required this.colorScheme,
    required this.textTheme,
  });

  final String name;
  final String role;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  role,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor,
    this.defaultColor,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;
  final Color? defaultColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = isActive
        ? (activeColor ?? cs.primary)
        : (defaultColor ?? cs.onSurface.withValues(alpha: 0.7));

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 24),
      child: Material(
        color: isActive
            ? cs.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher({
    required this.currentLocale,
    required this.onLocaleChanged,
    required this.colorScheme,
    required this.textTheme,
  });

  final String currentLocale;
  final ValueChanged<String> onLocaleChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 24),
      child: Row(
        children: [
          Icon(
            Icons.language_rounded,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          _localeChip('en', 'EN'),
          const SizedBox(width: 4),
          _localeChip('ur', 'اردو'),
          const SizedBox(width: 4),
          _localeChip('ar', 'عربي'),
        ],
      ),
    );
  }

  Widget _localeChip(String locale, String label) {
    final isSelected = currentLocale == locale;
    return GestureDetector(
      onTap: () => onLocaleChanged(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
