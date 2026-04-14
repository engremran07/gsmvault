import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/invoice_utils.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/admin/providers/admin_providers.dart';
import 'package:ac_techs/features/admin/providers/company_providers.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/features/settings/providers/approval_config_provider.dart';

class SubmitJobScreen extends ConsumerStatefulWidget {
  const SubmitJobScreen({this.initialJob, this.initialAggregate, super.key});

  final JobModel? initialJob;
  final SharedInstallAggregate? initialAggregate;

  @override
  ConsumerState<SubmitJobScreen> createState() => _SubmitJobScreenState();
}

class _SubmitJobScreenState extends ConsumerState<SubmitJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientContactController = TextEditingController();
  final _deliveryAmountController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String _initialFormSignature = '';
  int _bracketQty = 0;
  int _splitQty = 0;
  int _windowQty = 0;
  int _uninstallSplitQty = 0;
  int _uninstallWindowQty = 0;
  int _uninstallStandingQty = 0;
  int _dolabQty = 0;
  bool _isSharedInstall = false;
  int _sharedSplitUnits = 0;
  int _sharedWindowUnits = 0;
  int _sharedFreestandingUnits = 0;
  int _sharedUninstallSplitUnits = 0;
  int _sharedUninstallWindowUnits = 0;
  int _sharedUninstallFreestandingUnits = 0;
  int _sharedBracketQty = 0;
  int _sharedTeamSize = 0;
  List<UserModel> _selectedTeamMembers = [];
  int _techSplitShare = 0;
  int _techWindowShare = 0;
  int _techFreestandingShare = 0;
  int _techUninstallSplitShare = 0;
  int _techUninstallWindowShare = 0;
  int _techUninstallFreestandingShare = 0;
  int _techBracketShare = 0;
  String? _selectedCompanyId;
  String _selectedCompanyName = '';

  bool get _isEditing => widget.initialJob != null;

  /// True when opened from a pending shared install card on the dashboard.
  bool get _fromAggregate => widget.initialAggregate != null;

  @override
  void initState() {
    super.initState();
    final initialJob = widget.initialJob;
    if (initialJob != null) {
      _populateFromJob(initialJob);
    }
    final initialAggregate = widget.initialAggregate;
    if (initialAggregate != null) {
      _populateFromAggregate(initialAggregate);
      // Async-load client name / phone from the first job in this group.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadClientDetailsFromGroup(initialAggregate.groupKey);
      });
    }
    _captureInitialFormSignature();
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _clientNameController.dispose();
    _clientContactController.dispose();
    _deliveryAmountController.dispose();
    _deliveryNoteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int get _effectiveBracketQty =>
      _isSharedInstall ? _techBracketShare : _bracketQty;

  /// Total team count including self. Falls back to legacy numeric field
  /// when no team members have been explicitly selected (e.g. editing an
  /// old job that predates the team-roster feature).
  int get _effectiveTeamCount => _selectedTeamMembers.isNotEmpty
      ? _selectedTeamMembers.length + 1
      : _sharedTeamSize;

  void _populateFromJob(JobModel job) {
    _invoiceController.text = job.invoiceNumber;
    _clientNameController.text = job.clientName;
    _clientContactController.text = job.clientContact;
    _deliveryAmountController.text =
        job.charges?.deliveryAmount.toString() ?? '';
    _deliveryNoteController.text = job.charges?.deliveryNote ?? '';
    _descriptionController.text = job.expenseNote;

    _selectedDate = job.date ?? DateTime.now();
    _selectedCompanyId = job.companyId.trim().isEmpty ? null : job.companyId;
    _selectedCompanyName = job.companyName;
    _isSharedInstall = job.isSharedInstall;

    _splitQty = job.unitsForType(AppConstants.unitTypeSplitAc);
    _windowQty = job.unitsForType(AppConstants.unitTypeWindowAc);
    _dolabQty = job.unitsForType(AppConstants.unitTypeFreestandingAc);
    _uninstallSplitQty = job.unitsForType(AppConstants.unitTypeUninstallSplit);
    _uninstallWindowQty = job.unitsForType(
      AppConstants.unitTypeUninstallWindow,
    );
    _uninstallStandingQty = job.unitsForType(
      AppConstants.unitTypeUninstallFreestanding,
    );
    _bracketQty = job.charges?.bracketCount ?? job.effectiveBracketCount;

    _sharedSplitUnits = job.sharedInvoiceSplitUnits;
    _sharedWindowUnits = job.sharedInvoiceWindowUnits;
    _sharedFreestandingUnits = job.sharedInvoiceFreestandingUnits;
    _sharedUninstallSplitUnits = job.sharedInvoiceUninstallSplitUnits;
    _sharedUninstallWindowUnits = job.sharedInvoiceUninstallWindowUnits;
    _sharedUninstallFreestandingUnits =
        job.sharedInvoiceUninstallFreestandingUnits;
    _sharedBracketQty = job.sharedInvoiceBracketCount;
    _sharedTeamSize = job.sharedDeliveryTeamCount;
    _techSplitShare = job.techSplitShare;
    _techWindowShare = job.techWindowShare;
    _techFreestandingShare = job.techFreestandingShare;
    _techUninstallSplitShare = job.techUninstallSplitShare;
    _techUninstallWindowShare = job.techUninstallWindowShare;
    _techUninstallFreestandingShare = job.techUninstallFreestandingShare;
    _techBracketShare = job.techBracketShare;
  }

  /// Pre-fill invoice totals and delivery from a shared aggregate.
  /// Tech share fields are left at 0 — the tech fills those themselves.
  void _populateFromAggregate(SharedInstallAggregate agg) {
    _invoiceController.text = agg.invoiceNumber;
    _isSharedInstall = true;
    // Pre-fill company so the group key is computed correctly on submit.
    // Without this, Tech B would submit with no company selected → wrong
    // group key → invoice claim mismatch → duplicateInvoice error.
    if (agg.companyId.isNotEmpty) {
      _selectedCompanyId = agg.companyId;
      _selectedCompanyName = agg.companyName;
    }
    _sharedSplitUnits = agg.sharedInvoiceSplitUnits;
    _sharedWindowUnits = agg.sharedInvoiceWindowUnits;
    _sharedFreestandingUnits = agg.sharedInvoiceFreestandingUnits;
    _sharedUninstallSplitUnits = agg.sharedInvoiceUninstallSplitUnits;
    _sharedUninstallWindowUnits = agg.sharedInvoiceUninstallWindowUnits;
    _sharedUninstallFreestandingUnits =
        agg.sharedInvoiceUninstallFreestandingUnits;
    _sharedBracketQty = agg.sharedInvoiceBracketCount;
    _sharedTeamSize = agg.sharedDeliveryTeamCount;
    // Pre-fill client details stored on the aggregate (no job query needed).
    if (agg.clientName.isNotEmpty) {
      _clientNameController.text = agg.clientName;
    }
    if (agg.clientContact.isNotEmpty) {
      _clientContactController.text = agg.clientContact;
    }
    if (agg.sharedInvoiceDeliveryAmount > 0) {
      _deliveryAmountController.text = agg.sharedInvoiceDeliveryAmount
          .toStringAsFixed(
            agg.sharedInvoiceDeliveryAmount ==
                    agg.sharedInvoiceDeliveryAmount.roundToDouble()
                ? 0
                : 2,
          );
    }
  }

  /// Async one-time fetch of the first job in this group to pre-fill
  /// client name, phone, and company from the original submitter's job.
  /// Async fallback: fetches client details from the first job in the group
  /// for legacy aggregates that predate the clientName/clientContact fields.
  /// Silently ignored on PERMISSION_DENIED (tech can only read own jobs).
  Future<void> _loadClientDetailsFromGroup(String groupKey) async {
    if (!mounted) return;
    try {
      final job = await ref
          .read(jobRepositoryProvider)
          .fetchFirstJobForGroup(groupKey);
      if (!mounted || job == null) return;
      setState(() {
        if (_clientNameController.text.isEmpty &&
            job.clientName.trim().isNotEmpty) {
          _clientNameController.text = job.clientName.trim();
        }
        if (_clientContactController.text.isEmpty &&
            job.clientContact.trim().isNotEmpty) {
          _clientContactController.text = job.clientContact.trim();
        }
        if (job.companyId.trim().isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = job.companyId;
          _selectedCompanyName = job.companyName;
        }
      });
      _captureInitialFormSignature();
    } catch (_) {
      // PERMISSION_DENIED reading another tech’s job — silently ignored.
      // Client details were pre-filled from the aggregate if available.
    }
  }

  void _captureInitialFormSignature() {
    _initialFormSignature = _formSignature();
  }

  String _formSignature() {
    final teamIds = _selectedTeamMembers.map((user) => user.uid).toList()
      ..sort();
    return [
      _invoiceController.text.trim(),
      _clientNameController.text.trim(),
      _normalizeContact(_clientContactController.text),
      _deliveryAmountController.text.trim(),
      _deliveryNoteController.text.trim(),
      _descriptionController.text.trim(),
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _isSharedInstall,
      _selectedCompanyId ?? '',
      _selectedCompanyName.trim(),
      _bracketQty,
      _splitQty,
      _windowQty,
      _uninstallSplitQty,
      _uninstallWindowQty,
      _uninstallStandingQty,
      _dolabQty,
      _sharedSplitUnits,
      _sharedWindowUnits,
      _sharedFreestandingUnits,
      _sharedUninstallSplitUnits,
      _sharedUninstallWindowUnits,
      _sharedUninstallFreestandingUnits,
      _sharedBracketQty,
      _sharedTeamSize,
      teamIds.join(','),
      _techSplitShare,
      _techWindowShare,
      _techFreestandingShare,
      _techUninstallSplitShare,
      _techUninstallWindowShare,
      _techUninstallFreestandingShare,
      _techBracketShare,
    ].join('|');
  }

  bool get _hasUnsavedChanges => _formSignature() != _initialFormSignature;

  Future<bool> _confirmDiscardChanges() async {
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

  int _clampShare(int nextValue, int invoiceTotal) {
    return nextValue.clamp(0, invoiceTotal < 0 ? 0 : invoiceTotal);
  }

  List<AcUnit> _unitsFromQuickTemplate() {
    final units = <AcUnit>[];
    final splitQty = _isSharedInstall ? _techSplitShare : _splitQty;
    final windowQty = _isSharedInstall ? _techWindowShare : _windowQty;
    final dolabQty = _isSharedInstall ? _techFreestandingShare : _dolabQty;
    final uninstallSplitQty = _isSharedInstall
        ? _techUninstallSplitShare
        : _uninstallSplitQty;
    final uninstallWindowQty = _isSharedInstall
        ? _techUninstallWindowShare
        : _uninstallWindowQty;
    final uninstallStandingQty = _isSharedInstall
        ? _techUninstallFreestandingShare
        : _uninstallStandingQty;
    if (splitQty > 0) {
      units.add(AcUnit(type: 'Split AC', quantity: splitQty));
    }
    if (windowQty > 0) {
      units.add(AcUnit(type: 'Window AC', quantity: windowQty));
    }
    if (uninstallSplitQty > 0) {
      units.add(
        AcUnit(
          type: AppConstants.unitTypeUninstallSplit,
          quantity: uninstallSplitQty,
        ),
      );
    }
    if (uninstallWindowQty > 0) {
      units.add(
        AcUnit(
          type: AppConstants.unitTypeUninstallWindow,
          quantity: uninstallWindowQty,
        ),
      );
    }
    if (uninstallStandingQty > 0) {
      units.add(
        AcUnit(
          type: AppConstants.unitTypeUninstallFreestanding,
          quantity: uninstallStandingQty,
        ),
      );
    }
    if (dolabQty > 0) {
      units.add(AcUnit(type: 'Freestanding AC', quantity: dolabQty));
    }
    return units;
  }

  String _normalizeContact(String raw) {
    final trimmed = raw.trim();
    final hasLeadingPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';
    return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _invoiceController.clear();
    _clientNameController.clear();
    _clientContactController.clear();
    _deliveryAmountController.clear();
    _deliveryNoteController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _bracketQty = 0;
      _splitQty = 0;
      _windowQty = 0;
      _uninstallSplitQty = 0;
      _uninstallWindowQty = 0;
      _uninstallStandingQty = 0;
      _dolabQty = 0;
      _isSharedInstall = false;
      _sharedSplitUnits = 0;
      _sharedWindowUnits = 0;
      _sharedFreestandingUnits = 0;
      _sharedUninstallSplitUnits = 0;
      _sharedUninstallWindowUnits = 0;
      _sharedUninstallFreestandingUnits = 0;
      _sharedBracketQty = 0;
      _sharedTeamSize = 0;
      _selectedTeamMembers = [];
      _techSplitShare = 0;
      _techWindowShare = 0;
      _techFreestandingShare = 0;
      _techUninstallSplitShare = 0;
      _techUninstallWindowShare = 0;
      _techUninstallFreestandingShare = 0;
      _techBracketShare = 0;
      _selectedCompanyId = null;
      _selectedCompanyName = '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context)!;

    // Company is required when active companies exist. A job without a company
    // cannot be corrected after approval, so we block at submission time.
    final availableCompanies =
        ref.read(activeCompaniesProvider).value ?? const [];
    if (availableCompanies.isNotEmpty &&
        (_selectedCompanyId == null || _selectedCompanyId!.isEmpty)) {
      AppFeedback.error(context, message: l.companySelectionRequired);
      return;
    }

    final quickUnits = _unitsFromQuickTemplate();

    if (quickUnits.isEmpty) {
      AppFeedback.error(context, message: l.addServiceFirst);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final asyncUser = ref.read(currentUserProvider);
      if (!asyncUser.hasValue || asyncUser.value == null) {
        if (mounted) {
          AppFeedback.error(
            context,
            message: asyncUser.isLoading
                ? AppLocalizations.of(context)!.userDataLoading
                : AppLocalizations.of(context)!.couldNotSubmitJob,
          );
        }
        return;
      }
      final user = asyncUser.value!;
      final approvalConfig = ref.read(approvalConfigProvider).value;
      if (_isSharedInstall &&
          ((_techSplitShare > 0 && _techSplitShare > _sharedSplitUnits) ||
              (_techWindowShare > 0 && _techWindowShare > _sharedWindowUnits) ||
              (_techFreestandingShare > 0 &&
                  _techFreestandingShare > _sharedFreestandingUnits) ||
              (_techUninstallSplitShare > 0 &&
                  _techUninstallSplitShare > _sharedUninstallSplitUnits) ||
              (_techUninstallWindowShare > 0 &&
                  _techUninstallWindowShare > _sharedUninstallWindowUnits) ||
              (_techUninstallFreestandingShare > 0 &&
                  _techUninstallFreestandingShare >
                      _sharedUninstallFreestandingUnits) ||
              (_techBracketShare > 0 &&
                  _techBracketShare > _sharedBracketQty))) {
        if (mounted) {
          AppFeedback.error(context, message: l.sharedInstallLimitError);
        }
        return;
      }

      final rawDeliveryAmount =
          double.tryParse(_deliveryAmountController.text.trim()) ?? 0;
      if (_isSharedInstall &&
          rawDeliveryAmount > 0 &&
          _effectiveTeamCount <= 0) {
        if (mounted) {
          AppFeedback.error(context, message: l.sharedDeliverySplitInvalid);
        }
        return;
      }
      final deliveryAmount = _isSharedInstall && rawDeliveryAmount > 0
          ? rawDeliveryAmount / _effectiveTeamCount
          : rawDeliveryAmount;

      final charges = InvoiceCharges(
        acBracket: _effectiveBracketQty > 0,
        bracketCount: _effectiveBracketQty,
        bracketAmount: 0,
        deliveryAmount: deliveryAmount,
        deliveryCharge: deliveryAmount > 0,
        deliveryNote: _deliveryNoteController.text.trim(),
      );

      final normalizedInvoice = _buildInvoiceNumber();
      final sharedGroupKey = _isSharedInstall
          ? InvoiceUtils.sharedInstallGroupKey(
              companyId: _selectedCompanyId ?? '',
              invoiceNumber: normalizedInvoice,
            )
          : '';

      final sharedContributionUnits = _isSharedInstall
          ? _techSplitShare +
                _techWindowShare +
                _techFreestandingShare +
                _techUninstallSplitShare +
                _techUninstallWindowShare +
                _techUninstallFreestandingShare
          : _splitQty + _windowQty + _dolabQty;
      final sharedInvoiceTotalUnits =
          _sharedSplitUnits +
          _sharedWindowUnits +
          _sharedFreestandingUnits +
          _sharedUninstallSplitUnits +
          _sharedUninstallWindowUnits +
          _sharedUninstallFreestandingUnits;
      final requiresApproval =
          ((_isSharedInstall
              ? approvalConfig?.sharedJobApprovalRequired
              : approvalConfig?.jobApprovalRequired) ??
          true);
      final status = requiresApproval ? JobStatus.pending : JobStatus.approved;

      final job = JobModel(
        id: widget.initialJob?.id ?? '',
        techId: user.uid,
        techName: user.name,
        companyId: _selectedCompanyId ?? '',
        companyName: _selectedCompanyName,
        invoiceNumber: normalizedInvoice,
        clientName: _clientNameController.text.trim(),
        clientContact: _normalizeContact(_clientContactController.text),
        acUnits: quickUnits,
        expenseNote: _descriptionController.text.trim(),
        isSharedInstall: _isSharedInstall,
        sharedInstallGroupKey: sharedGroupKey,
        sharedInvoiceTotalUnits: _isSharedInstall ? sharedInvoiceTotalUnits : 0,
        sharedContributionUnits: _isSharedInstall ? sharedContributionUnits : 0,
        sharedInvoiceSplitUnits: _isSharedInstall ? _sharedSplitUnits : 0,
        sharedInvoiceWindowUnits: _isSharedInstall ? _sharedWindowUnits : 0,
        sharedInvoiceFreestandingUnits: _isSharedInstall
            ? _sharedFreestandingUnits
            : 0,
        sharedInvoiceUninstallSplitUnits: _isSharedInstall
            ? _sharedUninstallSplitUnits
            : 0,
        sharedInvoiceUninstallWindowUnits: _isSharedInstall
            ? _sharedUninstallWindowUnits
            : 0,
        sharedInvoiceUninstallFreestandingUnits: _isSharedInstall
            ? _sharedUninstallFreestandingUnits
            : 0,
        sharedInvoiceBracketCount: _isSharedInstall ? _sharedBracketQty : 0,
        sharedDeliveryTeamCount: _isSharedInstall ? _effectiveTeamCount : 0,
        sharedInvoiceDeliveryAmount: _isSharedInstall ? rawDeliveryAmount : 0,
        techSplitShare: _techSplitShare,
        techWindowShare: _techWindowShare,
        techFreestandingShare: _techFreestandingShare,
        techUninstallSplitShare: _techUninstallSplitShare,
        techUninstallWindowShare: _techUninstallWindowShare,
        techUninstallFreestandingShare: _techUninstallFreestandingShare,
        techBracketShare: _techBracketShare,
        charges: charges,
        date: _selectedDate,
        submittedAt: DateTime.now(),
        status: status,
      );

      final savedStatus = _isEditing
          ? await ref
                .read(jobRepositoryProvider)
                .updateTechnicianJob(job, approvalConfig: approvalConfig)
          : await ref
                .read(jobRepositoryProvider)
                .submitJob(
                  job,
                  lockedBeforeDate: approvalConfig?.lockedBeforeDate,
                  teamMemberIds:
                      _isSharedInstall && _selectedTeamMembers.isNotEmpty
                      ? [user.uid, ..._selectedTeamMembers.map((t) => t.uid)]
                      : [],
                  teamMemberNames:
                      _isSharedInstall && _selectedTeamMembers.isNotEmpty
                      ? [user.name, ..._selectedTeamMembers.map((t) => t.name)]
                      : [],
                );

      if (mounted) {
        AppFeedback.success(
          context,
          message: savedStatus == JobStatus.pending
              ? l.jobSubmitted
              : l.jobSaved,
        );
        if (_isEditing) {
          context.pop();
        } else {
          _resetForm();
          _captureInitialFormSignature();
        }
      }
    } on AppException catch (e) {
      if (mounted) {
        final locale = Localizations.localeOf(context).languageCode;
        AppFeedback.error(context, message: e.message(locale));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(activeCompaniesProvider);
    final approvalConfig = ref.watch(approvalConfigProvider).value;
    final requiresApproval =
        ((_isSharedInstall
            ? approvalConfig?.sharedJobApprovalRequired
            : approvalConfig?.jobApprovalRequired) ??
        true);

    return AppShortcuts(
      onSubmit: _isSubmitting ? null : _submit,
      child: PopScope(
        canPop: !_hasUnsavedChanges || _isSubmitting,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || _isSubmitting || !_hasUnsavedChanges) return;
          final navigator = Navigator.of(context);
          final discard = await _confirmDiscardChanges();
          if (!mounted || !discard) return;
          navigator.pop();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _fromAggregate
                  ? l.addYourShare
                  : (_isEditing ? l.editProfile : l.submitInvoice),
            ),
          ),
          body: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: FormFocusTraversal(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // ── Pre-fill banner (shared install join flow) ──
                      if (_fromAggregate) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: ArcticTheme.arcticBlue.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ArcticTheme.arcticBlue.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                color: ArcticTheme.arcticBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.preFilledFromSharedInstall,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: ArcticTheme.arcticBlue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── AC Services (single source of truth) ──
                      _SectionHeader(
                        icon: Icons.ac_unit_rounded,
                        title: l.acServices,
                      ),
                      const SizedBox(height: 8),
                      ArcticCard(
                        child: Column(
                          children: [
                            if (!_fromAggregate)
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.sharedInstall),
                                subtitle: Text(l.sharedInstallHint),
                                value: _isSharedInstall,
                                onChanged: (value) => setState(() {
                                  _isSharedInstall = value;
                                  if (!value) {
                                    _sharedSplitUnits = 0;
                                    _sharedWindowUnits = 0;
                                    _sharedFreestandingUnits = 0;
                                    _sharedUninstallSplitUnits = 0;
                                    _sharedUninstallWindowUnits = 0;
                                    _sharedUninstallFreestandingUnits = 0;
                                    _sharedBracketQty = 0;
                                    _sharedTeamSize = 0;
                                    _selectedTeamMembers = [];
                                    _techSplitShare = 0;
                                    _techWindowShare = 0;
                                    _techFreestandingShare = 0;
                                    _techUninstallSplitShare = 0;
                                    _techUninstallWindowShare = 0;
                                    _techUninstallFreestandingShare = 0;
                                    _techBracketShare = 0;
                                  }
                                }),
                              ),
                            if (_isSharedInstall) ...[
                              const SizedBox(height: 8),
                              Text(
                                l.sharedInstallMixHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.splitAcLabel,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedSplitUnits,
                                shareValue: _techSplitShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedSplitUnits = value;
                                  _techSplitShare = _clampShare(
                                    _techSplitShare,
                                    _sharedSplitUnits,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techSplitShare = _clampShare(
                                    value,
                                    _sharedSplitUnits,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.windowAcLabel,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedWindowUnits,
                                shareValue: _techWindowShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedWindowUnits = value;
                                  _techWindowShare = _clampShare(
                                    _techWindowShare,
                                    _sharedWindowUnits,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techWindowShare = _clampShare(
                                    value,
                                    _sharedWindowUnits,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.freestandingAcLabel,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedFreestandingUnits,
                                shareValue: _techFreestandingShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedFreestandingUnits = value;
                                  _techFreestandingShare = _clampShare(
                                    _techFreestandingShare,
                                    _sharedFreestandingUnits,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techFreestandingShare = _clampShare(
                                    value,
                                    _sharedFreestandingUnits,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.acOutdoorBracket,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedBracketQty,
                                shareValue: _techBracketShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedBracketQty = value;
                                  _techBracketShare = _clampShare(
                                    _techBracketShare,
                                    _sharedBracketQty,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techBracketShare = _clampShare(
                                    value,
                                    _sharedBracketQty,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.uninstallSplit,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedUninstallSplitUnits,
                                shareValue: _techUninstallSplitShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedUninstallSplitUnits = value;
                                  _techUninstallSplitShare = _clampShare(
                                    _techUninstallSplitShare,
                                    _sharedUninstallSplitUnits,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techUninstallSplitShare = _clampShare(
                                    value,
                                    _sharedUninstallSplitUnits,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.uninstallWindow,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedUninstallWindowUnits,
                                shareValue: _techUninstallWindowShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedUninstallWindowUnits = value;
                                  _techUninstallWindowShare = _clampShare(
                                    _techUninstallWindowShare,
                                    _sharedUninstallWindowUnits,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techUninstallWindowShare = _clampShare(
                                    value,
                                    _sharedUninstallWindowUnits,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              _SharedInstallTypeRow(
                                title: l.uninstallStanding,
                                totalReadOnly: _fromAggregate,
                                totalValue: _sharedUninstallFreestandingUnits,
                                shareValue: _techUninstallFreestandingShare,
                                onTotalChanged: (value) => setState(() {
                                  _sharedUninstallFreestandingUnits = value;
                                  _techUninstallFreestandingShare = _clampShare(
                                    _techUninstallFreestandingShare,
                                    _sharedUninstallFreestandingUnits,
                                  );
                                }),
                                onShareChanged: (value) => setState(() {
                                  _techUninstallFreestandingShare = _clampShare(
                                    value,
                                    _sharedUninstallFreestandingUnits,
                                  );
                                }),
                              ),
                              const SizedBox(height: 8),
                              if (!_fromAggregate)
                                _buildTeamSelectorSection(context, l),
                              const SizedBox(height: 8),
                            ],
                            if (!_isSharedInstall) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.splits,
                                      value: _splitQty,
                                      onChanged: (v) =>
                                          setState(() => _splitQty = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.windowAc,
                                      value: _windowQty,
                                      onChanged: (v) =>
                                          setState(() => _windowQty = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.standing,
                                      value: _dolabQty,
                                      onChanged: (v) =>
                                          setState(() => _dolabQty = v),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.acOutdoorBracket,
                                      value: _bracketQty,
                                      onChanged: (v) =>
                                          setState(() => _bracketQty = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.uninstallSplit,
                                      value: _uninstallSplitQty,
                                      onChanged: (v) => setState(
                                        () => _uninstallSplitQty = v,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.uninstallWindow,
                                      value: _uninstallWindowQty,
                                      onChanged: (v) => setState(
                                        () => _uninstallWindowQty = v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _QtyTile(
                                      label: l.uninstallStanding,
                                      value: _uninstallStandingQty,
                                      onChanged: (v) => setState(
                                        () => _uninstallStandingQty = v,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _descriptionController,
                              textInputAction: TextInputAction.next,
                              enableInteractiveSelection: true,
                              decoration: InputDecoration(
                                hintText: l.descriptionLabel,
                                prefixIcon: const Icon(
                                  Icons.notes_rounded,
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 80.ms),

                      const SizedBox(height: 20),

                      // ── Date Picker ──
                      _SectionHeader(icon: Icons.calendar_today, title: l.date),
                      const SizedBox(height: 8),
                      ArcticCard(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 30),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              color: ArcticTheme.arcticBlue,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: theme.textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              l.tapToChange,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 20),

                      // ── Invoice Details ──
                      _SectionHeader(
                        icon: Icons.receipt_long_rounded,
                        title: l.invoiceDetails,
                      ),
                      const SizedBox(height: 16),
                      companiesAsync
                          .when(
                            data: (companies) => companies.isEmpty
                                ? const SizedBox.shrink()
                                : CompanySelectorField(
                                    companies: companies,
                                    selectedCompanyId: _selectedCompanyId,
                                    // No "no-company" option when companies
                                    // exist — company is required for correct
                                    // invoice group-key computation and to
                                    // prevent uneditable data after approval.
                                    includeNoCompanyOption: false,
                                    hintText: l.selectCompany,
                                    onChanged: (selectedCompany) {
                                      setState(() {
                                        _selectedCompanyId =
                                            selectedCompany?.id;
                                        _selectedCompanyName =
                                            selectedCompany?.name ?? '';
                                      });
                                    },
                                  ),
                            loading: () =>
                                const ArcticShimmer(height: 56, count: 1),
                            error: (e, _) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ArcticShimmer(height: 56, count: 1),
                                const SizedBox(height: 4),
                                Text(
                                  l.loadingFailed,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _invoiceController,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        readOnly: _fromAggregate,
                        decoration: InputDecoration(
                          hintText: l.invoiceNumber,
                          labelText: l.invoiceNumber,
                          prefixIcon: const Icon(
                            Icons.receipt_outlined,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                          suffixIcon: _fromAggregate
                              ? const Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: ArcticTheme.arcticTextSecondary,
                                )
                              : null,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l.required : null,
                      ).animate().fadeIn(delay: 120.ms),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientNameController,
                        textInputAction: TextInputAction.next,
                        enableInteractiveSelection: true,
                        decoration: InputDecoration(
                          hintText: l.clientNameOptional,
                          labelText: l.clientName,
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clientContactController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        enableInteractiveSelection: true,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\-\s\(\)]'),
                          ),
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: InputDecoration(
                          hintText: l.clientPhone,
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: ArcticTheme.arcticTextSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l.required;
                          return _normalizeContact(v).isEmpty
                              ? l.enterValidPhone
                              : null;
                        },
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 28),

                      // ── Additional Charges ──
                      _SectionHeader(
                        icon: Icons.attach_money_rounded,
                        title: l.additionalCharges,
                      ),
                      const SizedBox(height: 8),
                      ArcticCard(
                        child: Column(
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                l.deliverySubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _deliveryAmountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              enableInteractiveSelection: true,
                              readOnly: _fromAggregate,
                              decoration: InputDecoration(
                                hintText: _isSharedInstall
                                    ? l.sharedInvoiceDeliveryAmount
                                    : l.deliveryChargeAmount,
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                                suffixIcon: _fromAggregate
                                    ? const Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: ArcticTheme.arcticTextSecondary,
                                      )
                                    : null,
                                isDense: true,
                              ),
                            ),
                            if (_isSharedInstall) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  l.sharedDeliverySplitHint,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: ArcticTheme.arcticTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _deliveryNoteController,
                              textInputAction: TextInputAction.done,
                              enableInteractiveSelection: true,
                              decoration: InputDecoration(
                                hintText: l.locationNote,
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: ArcticTheme.arcticTextSecondary,
                                ),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 32),

                      // ── Submit ──
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ArcticTheme.arcticDarkBg,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSubmitting
                                ? l.submitting
                                : (_isEditing
                                      ? l.save
                                      : (requiresApproval
                                            ? l.submitForApproval
                                            : l.submit)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSelectorSection(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    final currentUserUid = ref.watch(currentUserProvider).value?.uid ?? '';
    final allTechsAsync = ref.watch(activeTechniciansForTeamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.sharedTeamMembers,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _selectedTeamMembers.length >= 9
                  ? null
                  : () => _showAddTeamMemberDialog(
                      context,
                      l,
                      allTechsAsync.value ?? [],
                      currentUserUid,
                    ),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: Text(l.addTeamMember),
            ),
          ],
        ),
        if (_selectedTeamMembers.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _selectedTeamMembers
                .map(
                  (member) => Chip(
                    label: Text(member.name),
                    onDeleted: () => setState(
                      () => _selectedTeamMembers.removeWhere(
                        (m) => m.uid == member.uid,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          l.sharedTeamCount(_effectiveTeamCount > 0 ? _effectiveTeamCount : 1),
          style: theme.textTheme.bodySmall?.copyWith(
            color: ArcticTheme.arcticTextSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _showAddTeamMemberDialog(
    BuildContext context,
    AppLocalizations l,
    List<UserModel> allTechs,
    String selfUid,
  ) async {
    final eligible = allTechs
        .where(
          (t) =>
              t.uid != selfUid &&
              !_selectedTeamMembers.any((s) => s.uid == t.uid),
        )
        .toList();

    if (eligible.isEmpty) return;

    final selected = await showDialog<UserModel>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l.addTeamMember),
        children: eligible
            .map(
              (tech) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(tech),
                child: Text(tech.name),
              ),
            )
            .toList(),
      ),
    );

    if (selected != null) {
      setState(() => _selectedTeamMembers.add(selected));
    }
  }

  String _buildInvoiceNumber() {
    var entered = _invoiceController.text.trim();
    final upper = entered.toUpperCase();
    if (upper.startsWith('INV-')) {
      entered = entered.substring(4).trim();
    } else if (upper.startsWith('INV ')) {
      entered = entered.substring(4).trim();
    }
    return entered;
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ArcticTheme.arcticBlue),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _QtyTile extends StatelessWidget {
  const _QtyTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.readOnly = false,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool readOnly;

  Future<void> _showManualQuantityDialog(BuildContext context) async {
    if (readOnly) return;
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: '$value');

    final nextValue = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: l.quantity),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                AppFeedback.error(dialogContext, message: l.enterValidQuantity);
                return;
              }
              Navigator.of(dialogContext).pop(parsed);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );

    controller.dispose();

    if (nextValue != null) {
      onChanged(nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showManualQuantityDialog(context),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: readOnly
                ? (isDark
                      ? ArcticTheme.arcticCard.withValues(alpha: 0.5)
                      : scheme.surface.withValues(alpha: 0.5))
                : (isDark ? ArcticTheme.arcticCard : scheme.surface),
            border: Border.all(
              color: ArcticTheme.arcticBlue.withValues(
                alpha: isDark ? 0.18 : 0.28,
              ),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 22,
                  onPressed: (readOnly || value <= 0)
                      ? null
                      : () => onChanged(value - 1),
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 28,
                    color: value > 0
                        ? ArcticTheme.arcticTextSecondary
                        : ArcticTheme.arcticTextSecondary.withValues(
                            alpha: 0.3,
                          ),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showManualQuantityDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Text(
                    '$value',
                    style: textTheme.titleMedium?.copyWith(
                      color: textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 22,
                  onPressed: readOnly ? null : () => onChanged(value + 1),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 28,
                    color: ArcticTheme.arcticBlue,
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

class _SharedInstallTypeRow extends StatelessWidget {
  const _SharedInstallTypeRow({
    required this.title,
    required this.totalValue,
    required this.shareValue,
    required this.onTotalChanged,
    required this.onShareChanged,
    this.totalReadOnly = false,
  });

  final String title;
  final int totalValue;
  final int shareValue;
  final ValueChanged<int> onTotalChanged;
  final ValueChanged<int> onShareChanged;
  final bool totalReadOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QtyTile(
                label: l.totalOnInvoice,
                value: totalValue,
                onChanged: onTotalChanged,
                readOnly: totalReadOnly,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QtyTile(
                label: l.myShare,
                value: shareValue,
                onChanged: onShareChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
