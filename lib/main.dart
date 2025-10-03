import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/config/supabase_config.dart';
import 'core/services/firebase_analytics_service.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration first to read flags
  await EnvConfig.initialize();

  // Initialize Sentry if enabled
  if (EnvConfig.sentryEnabled && EnvConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvConfig.sentryDsn;
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
  // Initialize Firebase if analytics is enabled
  if (EnvConfig.firebaseAnalyticsEnabled) {
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
  if (EnvConfig.sentryEnabled) {
    runApp(SentryWidget(child: const ProviderScope(child: PMasterApp())));
  } else {
    runApp(const ProviderScope(child: PMasterApp()));
  }
}
