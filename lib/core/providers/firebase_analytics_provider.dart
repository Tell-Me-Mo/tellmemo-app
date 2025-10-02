import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_analytics_service.dart';

/// Provider for Firebase Analytics service
final firebaseAnalyticsServiceProvider = Provider<FirebaseAnalyticsService>(
  (ref) => FirebaseAnalyticsService(),
);
