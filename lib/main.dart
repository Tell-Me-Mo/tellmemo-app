import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/services/firebase_analytics_service.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

void main() async {
  // Initialize Sentry if enabled
  if (AppConfig.sentryEnabled && AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.sendDefaultPii = true;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
        options.replay.sessionSampleRate = 0.1;
        options.replay.onErrorSampleRate = 1.0;
        options.attachStacktrace = true;
      },
      appRunner: () => _runApp(),
    );
  } else {
    await _runApp();
  }
}

Future<void> _runApp() async {
  // Ensure bindings are initialized in the same zone as runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Print config in debug mode
  if (kDebugMode) {
    AppConfig.debugPrint();
  }

  // Initialize Firebase if analytics is enabled
  if (AppConfig.firebaseAnalyticsEnabled) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase Analytics
    await FirebaseAnalyticsService().initialize();

    // Log app open
    await FirebaseAnalyticsService().logAppOpen();
  }

  // Initialize Supabase (only if using Supabase auth)
  await SupabaseConfig.initialize();

  // Wrap in SentryWidget only if Sentry is enabled
  if (AppConfig.sentryEnabled) {
    runApp(SentryWidget(child: const ProviderScope(child: PMasterApp())));
  } else {
    runApp(const ProviderScope(child: PMasterApp()));
  }
}
