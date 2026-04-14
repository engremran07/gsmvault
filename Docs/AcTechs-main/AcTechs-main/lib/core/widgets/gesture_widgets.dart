import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';

/// Wraps a child with swipe-to-action (left = primary, right = secondary).
/// Used for approval cards (swipe right = approve, swipe left = reject) and
/// job history cards (swipe to view details).
class SwipeActionCard extends StatefulWidget {
  const SwipeActionCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftBackground,
    this.rightBackground,
    this.leftIcon = Icons.close_rounded,
    this.rightIcon = Icons.check_rounded,
    this.leftColor,
    this.rightColor,
    this.confirmDismiss,
    this.threshold = 0.3,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget? leftBackground;
  final Widget? rightBackground;
  final IconData leftIcon;
  final IconData rightIcon;
  final Color? leftColor;
  final Color? rightColor;
  final Future<bool> Function(DismissDirection)? confirmDismiss;
  final double threshold;

  @override
  State<SwipeActionCard> createState() => _SwipeActionCardState();
}

class _SwipeActionCardState extends State<SwipeActionCard> {
  @override
  Widget build(BuildContext context) {
    // No actions = just render the child
    if (widget.onSwipeLeft == null && widget.onSwipeRight == null) {
      return widget.child;
    }

    DismissDirection direction;
    if (widget.onSwipeLeft != null && widget.onSwipeRight != null) {
      direction = DismissDirection.horizontal;
    } else if (widget.onSwipeRight != null) {
      direction = DismissDirection.startToEnd;
    } else {
      direction = DismissDirection.endToStart;
    }

    return Dismissible(
      key:
          widget.key ??
          ValueKey(
            Object.hash(
              widget.child.runtimeType,
              widget.onSwipeLeft != null,
              widget.onSwipeRight != null,
            ),
          ),
      direction: direction,
      resizeDuration: const Duration(milliseconds: 150),
      dismissThresholds: {
        DismissDirection.startToEnd: widget.threshold,
        DismissDirection.endToStart: widget.threshold,
      },
      confirmDismiss:
          widget.confirmDismiss ??
          (dir) async {
            await Future<void>.delayed(const Duration(milliseconds: 80));
            HapticFeedback.mediumImpact();
            if (dir == DismissDirection.startToEnd) {
              widget.onSwipeRight?.call();
            } else {
              widget.onSwipeLeft?.call();
            }
            return false; // Don't actually dismiss — let the callback handle UI
          },
      background:
          widget.rightBackground ??
          _SwipeBackground(
            alignment: AlignmentDirectional.centerStart,
            icon: widget.rightIcon,
            color: widget.rightColor ?? ArcticTheme.arcticSuccess,
          ),
      secondaryBackground:
          widget.leftBackground ??
          _SwipeBackground(
            alignment: AlignmentDirectional.centerEnd,
            icon: widget.leftIcon,
            color: widget.leftColor ?? ArcticTheme.arcticError,
          ),
      child: widget.child,
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.icon,
    required this.color,
  });

  final AlignmentGeometry alignment;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

/// Long-press context menu wrapper.
/// Shows a popup menu on long press with haptic feedback.
class ContextMenuRegion extends StatelessWidget {
  const ContextMenuRegion({
    super.key,
    required this.child,
    required this.menuItems,
    this.onSelected,
  });

  final Widget child;
  final List<ContextMenuItem> menuItems;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) async {
        HapticFeedback.mediumImpact();
        final position = details.globalPosition;
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx,
            position.dy,
            position.dx + 1,
            position.dy + 1,
          ),
          items: menuItems
              .map(
                (item) => PopupMenuItem<String>(
                  value: item.id,
                  child: Row(
                    children: [
                      Icon(item.icon, size: 18, color: item.color),
                      const SizedBox(width: 12),
                      Text(item.label),
                    ],
                  ),
                ),
              )
              .toList(),
        );
        if (result != null) onSelected?.call(result);
      },
      child: child,
    );
  }
}

class ContextMenuItem {
  const ContextMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color? color;
}

/// Pull-to-refresh wrapper that provides consistent styling.
class ArcticRefreshIndicator extends StatelessWidget {
  const ArcticRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await onRefresh();
      },
      color: Theme.of(context).colorScheme.primary,
      child: child,
    );
  }
}
