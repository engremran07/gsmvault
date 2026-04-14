import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ac_techs/core/widgets/snackbars.dart';
import 'package:ac_techs/core/widgets/zoom_drawer.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

class ShellBackNavigationScope extends StatefulWidget {
  const ShellBackNavigationScope({
    super.key,
    required this.child,
    required this.isHome,
    required this.homeRoute,
  });

  final Widget child;
  final bool isHome;
  final String homeRoute;

  @override
  State<ShellBackNavigationScope> createState() =>
      _ShellBackNavigationScopeState();
}

class _ShellBackNavigationScopeState extends State<ShellBackNavigationScope> {
  static const _kExitWindow = Duration(seconds: 2);

  DateTime? _lastBackAttemptAt;

  Future<void> _requestAppExit() {
    return SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
  }

  @override
  Widget build(BuildContext context) {
    final canSystemPop =
        ModalRoute.of(context)?.canPop ??
        Navigator.maybeOf(context)?.canPop() ??
        false;

    return PopScope(
      canPop: canSystemPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _lastBackAttemptAt = null;
          return;
        }

        // Close the drawer first if it's open.
        final drawer = ZoomDrawerScope.maybeOf(context);
        if (drawer != null && drawer.isOpen) {
          drawer.close();
          return;
        }

        if (!widget.isHome) {
          _lastBackAttemptAt = null;
          context.go(widget.homeRoute);
          return;
        }

        final now = DateTime.now();
        final shouldExit =
            _lastBackAttemptAt != null &&
            now.difference(_lastBackAttemptAt!) <= _kExitWindow;

        if (shouldExit) {
          HapticFeedback.heavyImpact();
          _requestAppExit();
          return;
        }

        _lastBackAttemptAt = now;
        AppFeedback.info(
          context,
          message: AppLocalizations.of(context)!.pressBackAgainToExit,
        );
      },
      child: widget.child,
    );
  }
}
