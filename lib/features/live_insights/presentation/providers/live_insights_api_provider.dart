import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/services/live_insights_api_service.dart';

/// Provider for the LiveInsights API service
final liveInsightsApiServiceProvider = Provider<LiveInsightsApiService>((ref) {
  final dio = DioClient.instance;
  return LiveInsightsApiService(dio);
});
