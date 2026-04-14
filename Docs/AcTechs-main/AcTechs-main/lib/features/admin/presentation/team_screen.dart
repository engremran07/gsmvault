import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  String _search = '';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  List<UserModel> _filter(List<UserModel> techs) {
    if (_search.isEmpty) return techs;
    final q = _search.toLowerCase();
    return techs
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.email.toLowerCase().contains(q),
        )
        .toList();
  }

  void _toggleSelect(String uid) {
    setState(() {
      if (_selectedIds.contains(uid)) {
        _selectedIds.remove(uid);
        if (_selectedIds.isEmpty) _selectMode = false;
      } else {
        _selectedIds.add(uid);
        _selectMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectMode = false;
    });
  }

  Future<void> _bulkActivate(bool activate) async {
    if (_selectedIds.isEmpty) return;
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(userRepositoryProvider)
          .bulkToggleActive(_selectedIds.toList(), activate);
      if (!mounted) return;
      // Invalidate provider to refresh the list after bulk action
      ref.invalidate(allUsersProvider);
      _clearSelection();
      AppFeedback.success(
        context,
        message: activate ? l.usersActivated : l.usersDeactivated,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _showAddTechnicianDialog() async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedRole = AppConstants.roleTechnician;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(l.addTechnician),
          scrollable: true,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.name,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.required : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l.required;
                      if (!v.contains('@')) return l.invalidEmail;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      hintText: l.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) return l.minChars(6);
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: InputDecoration(
                      hintText: l.role,
                      prefixIcon: const Icon(Icons.security_rounded),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: AppConstants.roleTechnician,
                        child: Text(l.technician),
                      ),
                      DropdownMenuItem(
                        value: AppConstants.roleAdmin,
                        child: Text(l.admin),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setLocalState(() => selectedRole = value);
                      }
                    },
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

    if (result != true) return;
    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(userRepositoryProvider)
          .createUser(
            name: nameCtrl.text.trim(),
            email: emailCtrl.text.trim(),
            password: passCtrl.text,
            role: selectedRole,
          );
      if (!mounted) return;
      // Invalidate provider to show new user in team list
      ref.invalidate(allUsersProvider);
      AppFeedback.success(
        context,
        message: AppLocalizations.of(context)?.userCreated ?? 'User created!',
      );
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _showEditDialog(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();
    String selectedRole = user.isAdmin
        ? AppConstants.roleAdmin
        : AppConstants.roleTechnician;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.editTechnician),
        scrollable: true,
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  textInputAction: TextInputAction.next,
                  enableInteractiveSelection: true,
                  decoration: InputDecoration(
                    hintText: l.name,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.required : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: l.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    hintText: l.role,
                    prefixIcon: const Icon(Icons.security_rounded),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AppConstants.roleTechnician,
                      child: Text(l.technician),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.roleAdmin,
                      child: Text(l.admin),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    selectedRole = value;
                  },
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
    );

    if (result != true) return;
    if (!mounted) return;

    final locale = Localizations.localeOf(context).languageCode;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateUser(
            uid: user.uid,
            name: nameCtrl.text.trim(),
            role: selectedRole,
          );
      if (!mounted) return;
      // Invalidate provider to refresh the list if needed
      ref.invalidate(allUsersProvider);
      AppFeedback.success(
        context,
        message: AppLocalizations.of(context)?.userUpdated ?? 'User updated!',
      );
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _handlePasswordReset(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.passwordResetConfirmTitle),
        content: Text(l.passwordResetConfirmBody(user.email)),
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

    try {
      await ref.read(userRepositoryProvider).sendPasswordReset(user.email);
      if (!mounted) return;
      // Rich success dialog with spam-folder guidance
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 48),
          title: Text(l.passwordResetEmailSentTitle),
          content: Text(l.passwordResetEmailSentBody(user.email)),
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
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _handleDeleteUser(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTechnician),
        content: Text(l.confirmDeleteUser(user.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ArcticTheme.arcticError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref.read(userRepositoryProvider).deleteUser(user.uid);
      if (!mounted) return;
      // Invalidate the provider to force a fresh fetch from Firestore
      ref.invalidate(allUsersProvider);
      AppFeedback.success(context, message: l.userDeleted);
    } on AppException catch (e) {
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    try {
      await ref
          .read(userRepositoryProvider)
          .toggleUserActive(user.uid, !user.isActive);
      if (!mounted) return;

      ref.invalidate(allUsersProvider);
      AppFeedback.success(
        context,
        message: user.isActive ? l.usersDeactivated : l.usersActivated,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
    }
  }

  @override
  Widget build(BuildContext context) {
    final technicians = ref.watch(allUsersProvider);
    final l = AppLocalizations.of(context)!;

    return AppShortcuts(
      onRefresh: () => ref.invalidate(allUsersProvider),
      child: Scaffold(
        appBar: AppBar(
          title: _selectMode
              ? Text(l.selectedCount(_selectedIds.length))
              : Text(l.team),
          leading: _selectMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          actions: [
            if (_selectMode) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: l.bulkActivate,
                onPressed: () => _bulkActivate(true),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: l.delete,
                onPressed: () => _bulkActivate(false),
              ),
            ],
          ],
        ),
        floatingActionButton: _selectMode
            ? null
            : FloatingActionButton.extended(
                    onPressed: _showAddTechnicianDialog,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(l.addTechnician),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
        body: SafeArea(
          child: technicians.when(
            data: (techs) {
              final filtered = _filter(techs);
              final active = filtered.where((t) => t.isActive).toList();
              final inactive = filtered.where((t) => !t.isActive).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      8,
                    ),
                    child: ArcticSearchBar(
                      hint: l.searchByNameOrEmail,
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  // Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ArcticCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CountBadge(
                            count: techs.length,
                            label: l.total,
                            color: ArcticTheme.arcticBlue,
                          ),
                          _CountBadge(
                            count: techs.where((t) => t.isActive).length,
                            label: l.active,
                            color: ArcticTheme.arcticSuccess,
                          ),
                          _CountBadge(
                            count: techs.where((t) => !t.isActive).length,
                            label: l.inactive,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _search.isNotEmpty
                                  ? l.noMatchingMembers
                                  : l.noTeamMembers,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : ArcticRefreshIndicator(
                            onRefresh: () async =>
                                ref.invalidate(allUsersProvider),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                if (active.isNotEmpty) ...[
                                  Text(
                                    l.active,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ).animate().fadeIn(delay: 100.ms),
                                  const SizedBox(height: 12),
                                  ...active
                                      .map((tech) => _buildTechItem(tech))
                                      .toList()
                                      .animate(interval: 80.ms)
                                      .fadeIn()
                                      .slideX(begin: 0.03),
                                ],
                                if (inactive.isNotEmpty) ...[
                                  const SizedBox(height: 24),
                                  Text(
                                    l.inactive,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ).animate().fadeIn(delay: 200.ms),
                                  const SizedBox(height: 12),
                                  ...inactive
                                      .map((tech) => _buildTechItem(tech))
                                      .toList()
                                      .animate(interval: 80.ms)
                                      .fadeIn()
                                      .slideX(begin: 0.03),
                                ],
                                // Space for FAB
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                  ),
                ],
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
      ),
    );
  }

  Widget _buildTechItem(UserModel tech) {
    final isSelected = _selectedIds.contains(tech.uid);
    final l = AppLocalizations.of(context)!;
    return ContextMenuRegion(
      menuItems: [
        ContextMenuItem(
          id: 'edit',
          label: l.editTechnician,
          icon: Icons.edit_rounded,
          color: ArcticTheme.arcticBlue,
        ),
        ContextMenuItem(
          id: 'resetPassword',
          label: l.resetPassword,
          icon: Icons.lock_reset_rounded,
          color: ArcticTheme.arcticWarning,
        ),
        ContextMenuItem(
          id: 'toggleActive',
          label: tech.isActive ? l.inactive : l.active,
          icon: tech.isActive
              ? Icons.person_off_rounded
              : Icons.person_add_alt_1_rounded,
          color: tech.isActive
              ? ArcticTheme.arcticTextSecondary
              : ArcticTheme.arcticSuccess,
        ),
        ContextMenuItem(
          id: 'delete',
          label: l.deleteTechnician,
          icon: Icons.delete_outline_rounded,
          color: ArcticTheme.arcticError,
        ),
      ],
      onSelected: (action) {
        if (action == 'edit') {
          _showEditDialog(tech);
        } else if (action == 'resetPassword') {
          _handlePasswordReset(tech);
        } else if (action == 'toggleActive') {
          _toggleUserStatus(tech);
        } else if (action == 'delete') {
          _handleDeleteUser(tech);
        }
      },
      child: GestureDetector(
        onLongPress: () => _toggleSelect(tech.uid),
        onTap: _selectMode
            ? () => _toggleSelect(tech.uid)
            : () => _showEditDialog(tech),
        child: _TechCard(
          user: tech,
          selected: isSelected,
          onEdit: () => _showEditDialog(tech),
          onResetPassword: () => _handlePasswordReset(tech),
          onToggleActive: () => _toggleUserStatus(tech),
          onDelete: () => _handleDeleteUser(tech),
        ),
      ),
    );
  }
}

class _TechCard extends ConsumerWidget {
  const _TechCard({
    required this.user,
    this.selected = false,
    this.onEdit,
    this.onResetPassword,
    this.onToggleActive,
    this.onDelete,
  });

  final UserModel user;
  final bool selected;
  final VoidCallback? onEdit;
  final VoidCallback? onResetPassword;
  final VoidCallback? onToggleActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return ArcticCard(
      child: DecoratedBox(
        decoration: selected
            ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : const BoxDecoration(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: user.isActive
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.15)
                    : ArcticTheme.arcticTextSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: user.isActive
                        ? Theme.of(context).colorScheme.primary
                        : ArcticTheme.arcticTextSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (user.isAdmin
                                  ? ArcticTheme.arcticWarning
                                  : Theme.of(context).colorScheme.primary)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      user.isAdmin ? l.admin : l.technician,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: user.isAdmin
                            ? ArcticTheme.arcticWarning
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.editTechnician,
              onSelected: (action) {
                if (action == 'edit') {
                  onEdit?.call();
                } else if (action == 'reset') {
                  onResetPassword?.call();
                } else if (action == 'toggle') {
                  onToggleActive?.call();
                } else if (action == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l.editTechnician)),
                PopupMenuItem(value: 'reset', child: Text(l.resetPassword)),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(user.isActive ? l.inactive : l.active),
                ),
                PopupMenuItem(value: 'delete', child: Text(l.deleteTechnician)),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
