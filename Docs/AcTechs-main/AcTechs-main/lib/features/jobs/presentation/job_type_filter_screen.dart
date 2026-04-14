import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/core/utils/app_formatters.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/features/jobs/data/job_repository.dart';
import 'package:ac_techs/l10n/app_localizations.dart';
import 'package:ac_techs/features/jobs/providers/job_providers.dart';

class JobTypeFilterScreen extends ConsumerStatefulWidget {
  const JobTypeFilterScreen({
    required this.filter,
    required this.isAdminScope,
    super.key,
  });

  final JobAcTypeFilter filter;
  final bool isAdminScope;

  @override
  ConsumerState<JobTypeFilterScreen> createState() =>
      _JobTypeFilterScreenState();
}

class _JobTypeFilterScreenState extends ConsumerState<JobTypeFilterScreen> {
  static const int _pageSize = 20;
  static const int _adminQueryPageSize = 60;
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;
  final List<JobModel> _adminJobs = <JobModel>[];
  DocumentSnapshot<Map<String, dynamic>>? _adminCursor;
  bool _hasMoreAdminJobs = true;
  bool _isLoadingAdminJobs = false;

  bool _jobMatchesFilter(JobModel job) {
    switch (widget.filter) {
      case JobAcTypeFilter.split:
        return job.acUnits.any(
          (unit) => unit.type == 'Split AC' && unit.quantity > 0,
        );
      case JobAcTypeFilter.window:
        return job.acUnits.any(
          (unit) => unit.type == 'Window AC' && unit.quantity > 0,
        );
      case JobAcTypeFilter.freestanding:
        return job.acUnits.any(
          (unit) => unit.type == 'Freestanding AC' && unit.quantity > 0,
        );
      case JobAcTypeFilter.bracket:
        return job.effectiveBracketCount > 0;
      case JobAcTypeFilter.uninstall:
        return job.acUnits.any(
          (unit) => unit.type.startsWith('Uninstall') && unit.quantity > 0,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.isAdminScope) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMoreAdminJobs(reset: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    if (max - offset > 180) return;

    if (widget.isAdminScope) {
      _loadMoreAdminJobs();
      return;
    }

    final jobs = ref.read(techJobsByAcTypeProvider(widget.filter));

    if (_visibleCount >= jobs.length) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, jobs.length).toInt();
    });
  }

  Future<void> _loadMoreAdminJobs({bool reset = false}) async {
    if (_isLoadingAdminJobs) return;
    if (!reset && !_hasMoreAdminJobs) return;

    setState(() {
      _isLoadingAdminJobs = true;
      if (reset) {
        _adminJobs.clear();
        _adminCursor = null;
        _hasMoreAdminJobs = true;
        _visibleCount = _pageSize;
      }
    });

    try {
      final repo = ref.read(jobRepositoryProvider);
      var cursor = _adminCursor;
      var hasMore = _hasMoreAdminJobs;
      final matchedJobs = <JobModel>[];

      while (hasMore && matchedJobs.length < _pageSize) {
        final page = await repo.fetchAdminJobsPage(
          startAfter: cursor,
          limit: _adminQueryPageSize,
        );
        cursor = page.cursor;
        hasMore = page.hasMore;
        matchedJobs.addAll(
          page.jobs
              .where(_jobMatchesFilter)
              .where(
                (job) => !_adminJobs.any((existing) => existing.id == job.id),
              ),
        );
        if (page.jobs.isEmpty) {
          hasMore = false;
        }
      }

      if (!mounted) return;
      setState(() {
        _adminJobs.addAll(matchedJobs);
        _adminCursor = cursor;
        _hasMoreAdminJobs = hasMore;
        _isLoadingAdminJobs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasMoreAdminJobs = false;
        _isLoadingAdminJobs = false;
      });
    }
  }

  String _title(AppLocalizations l) {
    switch (widget.filter) {
      case JobAcTypeFilter.split:
        return l.splits;
      case JobAcTypeFilter.window:
        return l.windowAc;
      case JobAcTypeFilter.freestanding:
        return l.standing;
      case JobAcTypeFilter.bracket:
        return l.acOutdoorBracket;
      case JobAcTypeFilter.uninstall:
        return l.uninstalls;
    }
  }

  String _matchedLabel(AppLocalizations l) {
    switch (widget.filter) {
      case JobAcTypeFilter.split:
        return l.splits;
      case JobAcTypeFilter.window:
        return l.windowAc;
      case JobAcTypeFilter.freestanding:
        return l.standing;
      case JobAcTypeFilter.bracket:
        return l.acOutdoorBracket;
      case JobAcTypeFilter.uninstall:
        return l.uninstalls;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final jobs = widget.isAdminScope
        ? _adminJobs
        : ref.watch(techJobsByAcTypeProvider(widget.filter));

    if (_visibleCount > jobs.length) {
      _visibleCount = jobs.length;
    }
    final visibleJobs = jobs.take(_visibleCount).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(_title(l))),
      body: SafeArea(
        child: widget.isAdminScope && _adminJobs.isEmpty && _isLoadingAdminJobs
            ? const Center(child: CircularProgressIndicator())
            : ArcticRefreshIndicator(
                onRefresh: () async {
                  if (widget.isAdminScope) {
                    _loadMoreAdminJobs(reset: true);
                  } else {
                    ref.invalidate(techJobsByAcTypeProvider(widget.filter));
                  }
                },
                child: jobs.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.35,
                          ),
                          Center(
                            child: Text(
                              l.noMatchingJobs,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            visibleJobs.length +
                            (widget.isAdminScope
                                ? ((_isLoadingAdminJobs || _hasMoreAdminJobs)
                                      ? 1
                                      : 0)
                                : (visibleJobs.length < jobs.length ? 1 : 0)),
                        itemBuilder: (context, index) {
                          if (index >= visibleJobs.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final job = visibleJobs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ArcticCard(
                              onTap: () => context.push(
                                widget.isAdminScope
                                    ? '/admin/job/${job.id}'
                                    : '/tech/job/${job.id}',
                                extra: job,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          job.clientName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ArcticTheme.arcticBlue
                                              .withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: ArcticTheme.arcticBlue
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                        child: Text(
                                          'Matched: ${_matchedLabel(l)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: ArcticTheme.arcticBlue,
                                                fontSize: 11,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${job.invoiceNumber} • ${AppFormatters.date(job.date)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.companyName.isEmpty
                                        ? l.noCompany
                                        : job.companyName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              ArcticTheme.arcticTextSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    job.acUnits
                                        .where((u) => u.quantity > 0)
                                        .map((u) => '${u.type} x${u.quantity}')
                                        .join(' | '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
