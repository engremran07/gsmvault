import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/providers/connectivity_status_provider.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/admin/data/user_repository.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// A two-step, time-delayed database flush confirmation screen.
///
/// Step 1 – Shows a danger-zone warning with a [_kStep1Delay]-second countdown
///          before the "Proceed" button is enabled.
/// Step 2 – Asks for the admin password with a [_kStep2Delay]-second countdown
///          before the "Flush" button is enabled. Executes the flush on confirm.
class FlushDatabaseScreen extends ConsumerStatefulWidget {
  const FlushDatabaseScreen({super.key});

  @override
  ConsumerState<FlushDatabaseScreen> createState() =>
      _FlushDatabaseScreenState();
}

const int _kStep1Delay = 5;
const int _kStep2Delay = 3;

class _FlushDatabaseScreenState extends ConsumerState<FlushDatabaseScreen> {
  int _step = 1;
  int _countdown = _kStep1Delay;
  Timer? _timer;

  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _deleteNonAdminUsers = false;
  String? _targetTechnicianId;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _goToStep2() {
    setState(() {
      _step = 2;
      _countdown = _kStep2Delay;
    });
    _startCountdown();
  }

  Future<void> _executeFlush() async {
    if (_formKey.currentState?.validate() != true) return;

    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final password = _passwordCtrl.text;

    try {
      await ref
          .read(flushDatabaseProvider.notifier)
          .flush(
            password,
            deleteNonAdminUsers: _deleteNonAdminUsers,
            targetTechnicianId: _targetTechnicianId,
          );
      if (!mounted) return;
      AppFeedback.success(context, message: l.flushSuccess);
      setState(() {
        _step = 1;
        _countdown = _kStep1Delay;
        _passwordCtrl.clear();
        _obscurePassword = true;
        _deleteNonAdminUsers = false;
        _targetTechnicianId = null;
      });
      _startCountdown();
    } on AppException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, message: e.message(locale));
      // Reset to step 1 on any failure so admin must re-confirm.
      setState(() {
        _step = 1;
        _countdown = _kStep1Delay;
        _passwordCtrl.clear();
        _deleteNonAdminUsers = false;
        _targetTechnicianId = null;
      });
      _startCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final flushState = ref.watch(flushDatabaseProvider);
    final progress = flushState.asData?.value ?? FlushProgressState.idle;
    final usersAsync = ref.watch(allUsersProvider);
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final users = usersAsync.asData?.value;
    final technicians =
        users?.where((u) => !u.isAdmin).toList() ?? const <UserModel>[];
    final isLoading = progress.isRunning;
    final isOffline = connectivityAsync.maybeWhen(
      data: (status) => status == AppConnectivityStatus.offline,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.flushDatabase),
        leading: isLoading
            ? const SizedBox.shrink()
            : BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _step == 1
              ? _Step1View(
                  key: const ValueKey(1),
                  countdown: _countdown,
                  onProceed: _goToStep2,
                  onCancel: () => context.pop(),
                )
              : _Step2View(
                  key: const ValueKey(2),
                  countdown: _countdown,
                  formKey: _formKey,
                  passwordCtrl: _passwordCtrl,
                  obscurePassword: _obscurePassword,
                  deleteNonAdminUsers: _deleteNonAdminUsers,
                  onToggleDeleteUsers: (value) =>
                      setState(() => _deleteNonAdminUsers = value),
                  onToggleObscure: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onFlush: _executeFlush,
                  onCancel: () => context.pop(),
                  isLoading: isLoading,
                  isOffline: isOffline,
                  progress: progress,
                  technicians: technicians,
                  targetTechnicianId: _targetTechnicianId,
                  onTargetTechnicianChanged: (value) =>
                      setState(() => _targetTechnicianId = value),
                ),
        ),
      ),
    );
  }
}

// ── Step 1 ────────────────────────────────────────────────────────────────────

class _Step1View extends StatelessWidget {
  const _Step1View({
    super.key,
    required this.countdown,
    required this.onProceed,
    required this.onCancel,
  });

  final int countdown;
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final waiting = countdown > 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Warning icon
        Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ArcticTheme.arcticError.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 44,
                  color: ArcticTheme.arcticError,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 16),

        // Step label
        Center(
          child: Text(
            l.flushStep1Title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: ArcticTheme.arcticError),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),

        // Danger zone title
        Center(
          child: Text(
            l.dangerZone,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ArcticTheme.arcticError,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 24),

        // Warning intro
        Text(
          l.flushWarningIntro,
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),

        ArcticCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.flushOperationGuidanceTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                l.flushOperationMigrationNote,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l.flushOperationReimportNote,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 220.ms),
        const SizedBox(height: 12),

        // Delete list
        ...[
              l.flushItemJobs,
              l.flushItemExpenses,
              l.flushItemCompanies,
              l.flushItemUsersOptional,
            ]
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                      color: ArcticTheme.arcticError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList()
            .animate(interval: 60.ms)
            .fadeIn(delay: 250.ms)
            .slideX(begin: 0.05),

        const SizedBox(height: 12),

        // Admin kept notice
        ArcticCard(
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: ArcticTheme.arcticSuccess,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.flushAdminKept,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ArcticTheme.arcticSuccess,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 32),

        // Countdown / proceed button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(
              waiting ? Icons.hourglass_empty_rounded : Icons.arrow_forward,
            ),
            label: Text(waiting ? l.flushProceedIn(countdown) : l.flushProceed),
            style: ElevatedButton.styleFrom(
              backgroundColor: waiting
                  ? ArcticTheme.arcticTextSecondary
                  : ArcticTheme.arcticError,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: waiting ? null : onProceed,
          ),
        ).animate().fadeIn(delay: 550.ms),
        const SizedBox(height: 12),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onCancel,
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

// ── Step 2 ────────────────────────────────────────────────────────────────────

class _Step2View extends StatelessWidget {
  const _Step2View({
    super.key,
    required this.countdown,
    required this.formKey,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onFlush,
    required this.onCancel,
    required this.isLoading,
    required this.isOffline,
    required this.progress,
    required this.deleteNonAdminUsers,
    required this.onToggleDeleteUsers,
    required this.technicians,
    required this.targetTechnicianId,
    required this.onTargetTechnicianChanged,
  });

  final int countdown;
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool deleteNonAdminUsers;
  final ValueChanged<bool> onToggleDeleteUsers;
  final List<UserModel> technicians;
  final String? targetTechnicianId;
  final ValueChanged<String?> onTargetTechnicianChanged;
  final VoidCallback onToggleObscure;
  final VoidCallback onFlush;
  final VoidCallback onCancel;
  final bool isLoading;
  final bool isOffline;
  final FlushProgressState progress;

  String _phaseLabel(AppLocalizations l) {
    return switch (progress.phase) {
      FlushOperationPhase.verifyingPassword => l.flushPhaseVerifyingPassword,
      FlushOperationPhase.checkingConnection => l.flushPhaseCheckingConnection,
      FlushOperationPhase.scanningAffectedData => l.flushPhaseScanningData,
      FlushOperationPhase.deletingOperationalData =>
        l.flushPhaseDeletingOperationalData,
      FlushOperationPhase.deletingDerivedData =>
        l.flushPhaseDeletingDerivedData,
      FlushOperationPhase.deletingCompanies => l.flushPhaseDeletingCompanies,
      FlushOperationPhase.archivingUsers => l.flushPhaseArchivingUsers,
      FlushOperationPhase.rebuildingDerivedData =>
        l.flushPhaseRebuildingDerivedData,
      FlushOperationPhase.clearingLocalCache => l.flushPhaseClearingLocalCache,
      FlushOperationPhase.refreshingAppData => l.flushPhaseRefreshingAppData,
      FlushOperationPhase.completed => l.flushSuccess,
      FlushOperationPhase.idle => l.flushInProgress,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final waiting = countdown > 0;
    final isFlushBlocked = isOffline || waiting || isLoading;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Icon
        Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ArcticTheme.arcticError.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  size: 44,
                  color: ArcticTheme.arcticError,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 16),

        // Step label
        Center(
          child: Text(
            l.flushStep2Title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: ArcticTheme.arcticError),
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),

        Center(
          child: Text(
            l.flushDatabase,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: ArcticTheme.arcticError,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 24),

        // Password entry
        Form(
          key: formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String?>(
                initialValue: targetTechnicianId,
                decoration: InputDecoration(
                  labelText: l.flushScope,
                  prefixIcon: const Icon(Icons.group_work_outlined),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l.flushAllData),
                  ),
                  ...technicians.map(
                    (tech) => DropdownMenuItem<String?>(
                      value: tech.uid,
                      child: Text(tech.name),
                    ),
                  ),
                ],
                onChanged: isLoading ? null : onTargetTechnicianChanged,
              ),
              const SizedBox(height: 12),
              if (targetTechnicianId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l.flushOnlySelectedTechnician,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ),
              TextFormField(
                controller: passwordCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: l.flushEnterPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: onToggleObscure,
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? l.required : null,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),

        if (targetTechnicianId == null) ...[
          CheckboxListTile(
            value: deleteNonAdminUsers,
            onChanged: isLoading
                ? null
                : (value) => onToggleDeleteUsers(value ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: ArcticTheme.arcticError,
            title: Text(
              l.flushDeleteUsersOption,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: deleteNonAdminUsers
                    ? ArcticTheme.arcticError
                    : ArcticTheme.arcticTextPrimary,
                fontWeight: deleteNonAdminUsers ? FontWeight.w700 : null,
              ),
            ),
            subtitle: Text(
              l.flushDeleteUsersHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: deleteNonAdminUsers
                    ? ArcticTheme.arcticError
                    : ArcticTheme.arcticTextSecondary,
              ),
            ),
          ).animate().fadeIn(delay: 220.ms),
          if (deleteNonAdminUsers)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArcticTheme.arcticError.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ArcticTheme.arcticError.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: ArcticTheme.arcticError,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.flushDeleteUsersEnabledWarning,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ArcticTheme.arcticError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.08),
        ],
        const SizedBox(height: 32),

        if (isOffline)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ArcticCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: ArcticTheme.arcticWarning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.flushRequiresInternetMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ArcticCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _phaseLabel(l),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress.progressValue,
                      backgroundColor: ArcticTheme.arcticTextSecondary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.flushProgressStep(progress.step, progress.totalSteps),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArcticTheme.arcticTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Countdown / flush button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: null,
                    ),
                  )
                : Icon(
                    waiting
                        ? Icons.hourglass_empty_rounded
                        : Icons.delete_forever_rounded,
                  ),
            label: Text(
              isLoading
                  ? _phaseLabel(l)
                  : waiting
                  ? l.flushConfirmIn(countdown)
                  : l.flushConfirm,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: (waiting || isLoading)
                  ? ArcticTheme.arcticTextSecondary
                  : ArcticTheme.arcticError,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: isFlushBlocked ? null : onFlush,
          ),
        ).animate().fadeIn(delay: 250.ms),
        const SizedBox(height: 12),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            child: Text(l.cancel),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}
