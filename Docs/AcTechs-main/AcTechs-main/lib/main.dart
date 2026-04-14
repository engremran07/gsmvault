import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:ac_techs/core/theme/arctic_theme.dart';
import 'package:ac_techs/core/providers/locale_provider.dart';
import 'package:ac_techs/core/providers/theme_provider.dart';
import 'package:ac_techs/core/widgets/widgets.dart';
import 'package:ac_techs/routing/app_router.dart';
import 'package:ac_techs/l10n/app_localizations.dart';

const _kClearFirestoreCacheOnLaunchKey = 'clear_firestore_cache_on_launch';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Firestore will still work in offline mode via cached data;
    // auth will fail gracefully when user tries to sign in.
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final shouldClearFirestoreCache =
      prefs.getBool(_kClearFirestoreCacheOnLaunchKey) ?? false;
  if (shouldClearFirestoreCache) {
    try {
      await FirebaseFirestore.instance.clearPersistence();
    } catch (e) {
      debugPrint('Firestore persistence clear skipped: $e');
    } finally {
      await prefs.remove(_kClearFirestoreCacheOnLaunchKey);
    }
  }

  // Configure Firestore: enable offline persistence with a size limit
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
  );

  // Edge-to-edge system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ProviderScope(child: AcTechsApp()));
}

class AcTechsApp extends ConsumerWidget {
  const AcTechsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final goRouter = ref.watch(routerProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    return MaterialApp.router(
      title: 'AC Techs',
      debugShowCheckedModeBanner: false,
      theme: ArcticTheme.themeForMode(
        themeMode,
        locale,
        systemBrightness: systemBrightness,
      ),
      locale: Locale(locale),
      routerConfig: goRouter,
      builder: (context, child) {
        final routedChild = child ?? const SizedBox.shrink();
        return Stack(children: [routedChild, const NetworkStatusBanner()]);
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ur'), Locale('ar')],
    );
  }
}
