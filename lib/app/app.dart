import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import '../features/auth/presentation/widgets/auth_initialization_wrapper.dart';
import '../core/widgets/notifications/notification_overlay.dart';

class PMasterApp extends ConsumerWidget {
  const PMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return AuthInitializationWrapper(
      child: NotificationOverlay(
        child: MaterialApp.router(
          title: 'TellMeMo - Meeting Intelligence System',
          debugShowCheckedModeBanner: false,

          // Theme configuration
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,

          // Router configuration
          routerConfig: router,

          // Firebase Analytics observer is added to GoRouter
          // See app_router.dart for analytics tracking configuration

          // Localization (for future internationalization)
          // locale: const Locale('en', 'US'),
          // supportedLocales: const [
          //   Locale('en', 'US'),
          // ],
        ),
      ),
    );
  }
}