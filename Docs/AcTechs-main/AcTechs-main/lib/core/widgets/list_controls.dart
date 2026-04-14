import 'package:flutter/material.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

/// Unified search bar used across all list screens.
class ArcticSearchBar extends StatefulWidget {
  const ArcticSearchBar({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  @override
  State<ArcticSearchBar> createState() => _ArcticSearchBarState();
}

class _ArcticSearchBarState extends State<ArcticSearchBar> {
  late final TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint ?? AppLocalizations.of(context)!.search,
              prefixIcon: const Icon(
                Icons.search,
                size: 20,
                color: ArcticTheme.arcticTextSecondary,
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (_, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged?.call('');
                    },
                  );
                },
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          widget.trailing!,
        ],
      ],
    );
  }
}

/// A label+value pair for [SortButton] options.
class SortOption<T> {
  const SortOption({required this.label, required this.value});
  final String label;
  final T value;
}

/// Sort direction indicator + popup menu.
class SortButton<T> extends StatelessWidget {
  const SortButton({
    super.key,
    required this.options,
    required this.currentValue,
    required this.onSelected,
  });

  final List<SortOption<T>> options;
  final T currentValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: currentValue,
      onSelected: onSelected,
      icon: Icon(
        Icons.sort_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      tooltip: AppLocalizations.of(context)!.sort,
      itemBuilder: (_) => options
          .map(
            (o) => PopupMenuItem(
              value: o.value,
              child: Row(
                children: [
                  if (o.value == currentValue)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  if (o.value == currentValue) const SizedBox(width: 8),
                  Text(o.label),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Bulk action bar that slides in when items are selected.
class BulkActionBar extends StatelessWidget {
  const BulkActionBar({
    super.key,
    required this.selectedCount,
    required this.actions,
    required this.onClear,
    this.isProcessing = false,
  });

  final int selectedCount;
  final List<BulkAction> actions;
  final VoidCallback onClear;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClear,
            ),
            Text(
              AppLocalizations.of(context)!.selectedCount(selectedCount),
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (isProcessing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: actions
                        .map(
                          (a) => Padding(
                            padding: const EdgeInsetsDirectional.only(start: 8),
                            child: TextButton.icon(
                              onPressed: a.onPressed,
                              icon: Icon(a.icon, size: 18),
                              label: Text(a.label),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    a.color ?? ArcticTheme.arcticBlue,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BulkAction {
  const BulkAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
}

/// Filter chips row for status filtering.
class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.pendingCount,
    this.approvedCount,
    this.rejectedCount,
    this.sharedCount,
  });

  final String? selected;
  final ValueChanged<String> onSelected;
  final int? pendingCount;
  final int? approvedCount;
  final int? rejectedCount;

  /// When non-null, a 5th "Shared" chip is rendered with this count.
  final int? sharedCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final counts = <String, int?>{
      'pending': pendingCount,
      'approved': approvedCount,
      'rejected': rejectedCount,
      'shared': sharedCount,
    };

    final filters = [
      ('all', l.all, null),
      ('pending', l.pending, ArcticTheme.arcticPending),
      ('approved', l.approved, ArcticTheme.arcticSuccess),
      ('rejected', l.rejected, ArcticTheme.arcticError),
      if (sharedCount != null)
        ('shared', l.sharedInstall, ArcticTheme.arcticBlue),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final key = f.$1;
          final isSelected =
              key == selected || (key == 'all' && selected == 'all');
          final count = counts[key];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(count != null ? '${f.$2} ($count)' : f.$2),
              selectedColor: (f.$3 ?? ArcticTheme.arcticBlue).withValues(
                alpha: 0.2,
              ),
              checkmarkColor: f.$3 ?? ArcticTheme.arcticBlue,
              side: BorderSide(
                color: isSelected
                    ? (f.$3 ?? ArcticTheme.arcticBlue)
                    : ArcticTheme.arcticDivider,
              ),
              onSelected: (_) => onSelected(key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
