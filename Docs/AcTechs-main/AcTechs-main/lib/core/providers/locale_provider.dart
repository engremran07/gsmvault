import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ac_techs/features/auth/data/auth_repository.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

const _kLocaleKey = 'app_locale';

/// App locale as a Notifier — works pre-login (SharedPreferences)
/// and syncs with Firestore user doc after login.
final appLocaleProvider = NotifierProvider<LocaleNotifier, String>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<String> {
  bool _hydratedFromPrefs = false;
  String _currentLocale = 'en';

  @override
  String build() {
    if (!_hydratedFromPrefs) {
      _hydratedFromPrefs = true;
      unawaited(_loadFromPrefs());
    }

    final user = ref.watch(currentUserProvider).value;
    if (user != null &&
        user.language.isNotEmpty &&
        user.language != _currentLocale) {
      _currentLocale = user.language;
      unawaited(_saveLocaleToPrefs(user.language));
      if (state != user.language) {
        state = user.language;
      }
    }

    return _currentLocale;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null && saved != _currentLocale) {
      _currentLocale = saved;
      state = saved;
    }
  }

  Future<void> setLocale(String locale) async {
    final normalizedLocale = locale.trim().toLowerCase();
    _currentLocale = normalizedLocale;
    state = normalizedLocale;
    await _saveLocaleToPrefs(normalizedLocale);

    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      try {
        await ref.read(authRepositoryProvider).updateLanguage(normalizedLocale);
      } catch (_) {
        // Keep local selection even if cloud sync fails.
      }
    }
  }

  Future<void> _saveLocaleToPrefs(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale);
  }
}
