// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Controller for [ZoomDrawerWrapper] that allows opening / closing / toggling
/// the drawer programmatically.
class ZoomDrawerController {
  _ZoomDrawerWrapperState? _state;

  void _attach(_ZoomDrawerWrapperState state) => _state = state;
  void _detach() => _state = null;

  /// Whether the drawer is fully or partially open.
  bool get isOpen => _state?._isOpen ?? false;

  void toggle() => _state?._toggle();
  void open() => _state?._open();
  void close() => _state?._close();
}

/// Inherited widget providing [ZoomDrawerController] down the tree.
class ZoomDrawerScope extends InheritedWidget {
  const ZoomDrawerScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ZoomDrawerController controller;

  static ZoomDrawerController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZoomDrawerScope>();
    assert(scope != null, 'No ZoomDrawerScope found in context');
    return scope!.controller;
  }

  static ZoomDrawerController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ZoomDrawerScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(ZoomDrawerScope oldWidget) =>
      controller != oldWidget.controller;
}

/// A zoom-style side drawer that scales + translates the main content to reveal
/// the [menuScreen] underneath.  Fully RTL-aware, theme-integrated, and manages
/// its own [AnimationController] internally.
///
/// Workarounds for common `flutter_zoom_drawer` package bugs:
/// - #153  Widget tree is kept STABLE — GestureDetector callbacks are toggled
///         to `null` instead of conditionally wrapping/unwrapping widgets.
/// - #146  `dragOffset` capped at 65 % of screen width (not full width).
/// - #147  Uses [ZoomDrawerScope] InheritedWidget instead of static lookup.
class ZoomDrawerWrapper extends StatefulWidget {
  const ZoomDrawerWrapper({
    super.key,
    required this.menuScreen,
    required this.mainScreen,
    this.controller,
    this.slideWidth,
    this.mainScreenScale = 0.85,
    this.borderRadius = 24.0,
    this.duration = const Duration(milliseconds: 300),
    this.menuBackgroundColor,
    this.shadowColor,
    this.showShadow = true,
    this.disableDragGesture = false,
    this.mainScreenTapClose = true,
  });

  /// Content shown behind the main screen when the drawer is open.
  final Widget menuScreen;

  /// The main app content (typically a [Scaffold] with bottom-nav).
  final Widget mainScreen;

  /// Optional external controller.
  final ZoomDrawerController? controller;

  /// How many logical pixels the main screen slides aside.
  /// Defaults to 65 % of screen width at first build.
  final double? slideWidth;

  /// Scale factor applied to the main content when the drawer is fully open.
  final double mainScreenScale;

  /// Corner radius applied to [mainScreen] when the drawer is open.
  final double borderRadius;

  /// Open/close animation duration.
  final Duration duration;

  /// Drawer background colour — defaults to `scaffoldBackgroundColor`.
  final Color? menuBackgroundColor;

  /// Shadow behind the main screen edge.
  final Color? shadowColor;

  /// Whether to paint a drop-shadow behind the main screen.
  final bool showShadow;

  /// Disable horizontal drag-to-open / close.
  final bool disableDragGesture;

  /// Tap anywhere on the main screen scrim to close the drawer.
  final bool mainScreenTapClose;

  @override
  State<ZoomDrawerWrapper> createState() => _ZoomDrawerWrapperState();
}

class _ZoomDrawerWrapperState extends State<ZoomDrawerWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final ZoomDrawerController _controller;

  bool get _isOpen => _animationController.value > 0.5;

  // Drag bookkeeping
  double _dragStart = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller = widget.controller ?? ZoomDrawerController();
    _controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant ZoomDrawerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller._detach();
      (_controller = widget.controller!)._attach(this);
    }
    if (widget.duration != oldWidget.duration) {
      _animationController.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller._detach();
    _animationController.dispose();
    super.dispose();
  }

  // ── Public API for ZoomDrawerController ────────────────────────────────

  void _toggle() {
    if (_animationController.isAnimating) return;
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _animationController.forward();
  }

  void _close() {
    _animationController.reverse();
  }

  // ── Drag handling ──────────────────────────────────────────────────────

  double get _effectiveSlideWidth =>
      widget.slideWidth ?? MediaQuery.of(context).size.width * 0.65;

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition.dx;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final dx = details.globalPosition.dx - _dragStart;
    final slideWidth = _effectiveSlideWidth;

    double progress;
    if (_isRtl) {
      // RTL: drag to the LEFT to open, to the RIGHT to close.
      progress = _isOpen ? 1.0 + dx / slideWidth : -dx / slideWidth;
    } else {
      // LTR: drag to the RIGHT to open, to the LEFT to close.
      progress = _isOpen ? 1.0 + dx / slideWidth : dx / slideWidth;
    }
    _animationController.value = progress.clamp(0.0, 1.0);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
    final velocity = details.primaryVelocity ?? 0;

    // Velocity-based snap: fast swipe completes regardless of position.
    if (_isRtl) {
      if (velocity < -400) {
        _open();
      } else if (velocity > 400) {
        _close();
      } else {
        _animationController.value > 0.5 ? _open() : _close();
      }
    } else {
      if (velocity > 400) {
        _open();
      } else if (velocity < -400) {
        _close();
      } else {
        _animationController.value > 0.5 ? _open() : _close();
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.menuBackgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    return ZoomDrawerScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          final animValue = Curves.easeOutCubic.transform(
            _animationController.value,
          );
          return _buildDrawerLayout(context, animValue, bgColor);
        },
      ),
    );
  }

  Widget _buildDrawerLayout(
    BuildContext context,
    double animValue,
    Color bgColor,
  ) {
    final slideWidth = _effectiveSlideWidth;
    final scale = 1.0 - (1.0 - widget.mainScreenScale) * animValue;
    final slideOffset = slideWidth * animValue;
    final radius = widget.borderRadius * animValue;

    // Build the translation for the main screen.
    final mainScreenTranslateX = _isRtl ? -slideOffset : slideOffset;

    return ColoredBox(
      color: bgColor,
      child: Stack(
        children: [
          // ── Menu layer (behind main screen) ──
          Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: SizedBox(
              width: slideWidth,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: widget.menuScreen,
              ),
            ),
          ),

          // ── Main screen layer (scaled + translated) ──
          GestureDetector(
            // #153 fix: always keep GestureDetector, null-out callbacks.
            onHorizontalDragStart: widget.disableDragGesture
                ? null
                : _onHorizontalDragStart,
            onHorizontalDragUpdate: widget.disableDragGesture
                ? null
                : _onHorizontalDragUpdate,
            onHorizontalDragEnd: widget.disableDragGesture
                ? null
                : _onHorizontalDragEnd,
            onTap: (widget.mainScreenTapClose && _isOpen) ? _close : null,
            child: Transform(
              alignment: AlignmentDirectional.centerStart,
              transform: Matrix4.identity()
                ..translate(mainScreenTranslateX, 0.0)
                ..scale(scale),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: ColoredBox(
                  color: widget.showShadow && animValue > 0
                      ? Colors.transparent
                      : Colors.transparent,
                  child: Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: _isOpen,
                        child: widget.mainScreen,
                      ),
                      // ── Scrim overlay ──
                      if (animValue > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_isOpen,
                            child: ColoredBox(
                              color: Theme.of(context)
                                  .colorScheme
                                  .scrim
                                  .withValues(alpha: 0.4 * animValue),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
