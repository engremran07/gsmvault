import 'package:flutter/material.dart';

/// Responsive breakpoints and helpers to prevent overflow on
/// different Android phone brands (small 5", normal 6", tablet 8"+).
class Responsive {
  Responsive._();

  static const double mobileSmall = 360;
  static const double mobileNormal = 400;
  static const double tablet = 600;

  static bool isSmall(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileNormal;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Standard horizontal screen padding — tighter on small phones.
  static EdgeInsets screenPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileSmall) return const EdgeInsets.symmetric(horizontal: 12);
    if (w < tablet) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  /// Scaled font size for stat cards etc. that overflow on tiny screens.
  static double scaledFontSize(BuildContext context, double base) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < mobileSmall) return base * 0.85;
    return base;
  }

  /// Max content width for tablets to avoid overly-wide layouts.
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tablet) return 600;
    return w;
  }
}

/// A wrapper that constrains content width on tablets and centers it.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? Responsive.screenPadding(context),
          child: child,
        ),
      ),
    );
  }
}
