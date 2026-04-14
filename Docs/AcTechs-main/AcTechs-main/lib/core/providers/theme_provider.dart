import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/features/auth/data/auth_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

const _kThemeKey = 'app_theme_mode';

/// Supported theme modes for the app.
enum AppThemeMode { auto, dark, light, highContrast }

/// Provides the current theme mode, synced to SharedPreferences + Firestore.
final appThemeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  bool _hydratedFromPrefs = false;
  AppThemeMode _currentMode = AppThemeMode.dark;

  @override
  AppThemeMode build() {
    if (!_hydratedFromPrefs) {
      _hydratedFromPrefs = true;
      unawaited(_loadFromPrefs());
    }

    final user = ref.watch(currentUserProvider).value;
    if (user != null) {
      final remoteMode = _parse(user.themeMode);
      if (remoteMode != _currentMode) {
        _currentMode = remoteMode;
        unawaited(_saveModeToPrefs(remoteMode));
      }
    }

    return _currentMode;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kThemeKey);
    if (saved != null) {
      final parsed = _parse(saved);
      _currentMode = parsed;
      state = parsed;
    }
  }

  Future<void> _saveModeToPrefs(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }

  Future<void> setMode(AppThemeMode mode) async {
    _currentMode = mode;
    state = mode;
    await _saveModeToPrefs(mode);

    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      try {
        await ref.read(authRepositoryProvider).updateThemeMode(mode.name);
      } catch (_) {
        // Keep local state even if cloud sync fails.
      }
    }
  }

  /// Cycle through modes: auto → dark → light → highContrast → auto
  void cycle() {
    final next = switch (state) {
      AppThemeMode.auto => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.light,
      AppThemeMode.light => AppThemeMode.highContrast,
      AppThemeMode.highContrast => AppThemeMode.auto,
    };
    setMode(next);
  }

  static AppThemeMode _parse(String? raw) {
    return switch (raw) {
      'auto' => AppThemeMode.auto,
      'light' => AppThemeMode.light,
      'highContrast' => AppThemeMode.highContrast,
      _ => AppThemeMode.dark,
    };
  }
}
