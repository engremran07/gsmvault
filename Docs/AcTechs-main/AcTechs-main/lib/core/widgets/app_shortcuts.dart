import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcut intents for the app.
class SubmitIntent extends Intent {
  const SubmitIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class NavigateBackIntent extends Intent {
  const NavigateBackIntent();
}

/// Ctrl+N — trigger a "create new" action on the current screen.
class NewItemIntent extends Intent {
  const NewItemIntent();
}

/// Ctrl+P — trigger a print / PDF-export action on the current screen.
class PrintIntent extends Intent {
  const PrintIntent();
}

/// Ctrl+E — trigger an export (e.g. Excel) action on the current screen.
class ExportIntent extends Intent {
  const ExportIntent();
}

/// Provides app-wide keyboard shortcuts binding.
/// Wrap a screen body with this to add standard shortcuts.
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({
    super.key,
    required this.child,
    this.onSubmit,
    this.onRefresh,
    this.onSearch,
    this.onEscape,
    this.onNewItem,
    this.onPrint,
    this.onExport,
  });

  final Widget child;
  final VoidCallback? onSubmit;
  final VoidCallback? onRefresh;
  final VoidCallback? onSearch;
  final VoidCallback? onEscape;
  final VoidCallback? onNewItem;
  final VoidCallback? onPrint;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            const SubmitIntent(),
        const SingleActivator(LogicalKeyboardKey.f5): const RefreshIntent(),
        const SingleActivator(LogicalKeyboardKey.keyR, control: true):
            const RefreshIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const EscapeIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace, alt: true):
            const NavigateBackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const NewItemIntent(),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            const PrintIntent(),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true):
            const ExportIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          if (onSubmit != null)
            SubmitIntent: CallbackAction<SubmitIntent>(
              onInvoke: (_) => onSubmit!(),
            ),
          if (onRefresh != null)
            RefreshIntent: CallbackAction<RefreshIntent>(
              onInvoke: (_) => onRefresh!(),
            ),
          if (onSearch != null)
            SearchIntent: CallbackAction<SearchIntent>(
              onInvoke: (_) => onSearch!(),
            ),
          if (onEscape != null)
            EscapeIntent: CallbackAction<EscapeIntent>(
              onInvoke: (_) => onEscape!(),
            ),
          if (onNewItem != null)
            NewItemIntent: CallbackAction<NewItemIntent>(
              onInvoke: (_) => onNewItem!(),
            ),
          if (onPrint != null)
            PrintIntent: CallbackAction<PrintIntent>(
              onInvoke: (_) => onPrint!(),
            ),
          if (onExport != null)
            ExportIntent: CallbackAction<ExportIntent>(
              onInvoke: (_) => onExport!(),
            ),
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

/// Wraps a form to enable Tab-based focus traversal between fields.
/// Uses FocusTraversalGroup with ordered traversal policy.
class FormFocusTraversal extends StatelessWidget {
  const FormFocusTraversal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(policy: OrderedTraversalPolicy(), child: child);
  }
}
