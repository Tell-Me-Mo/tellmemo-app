import 'package:freezed_annotation/freezed_annotation.dart';

part 'integration.freezed.dart';
part 'integration.g.dart';

enum IntegrationType {
  aiBrain,
  fireflies,
  slack,
  teams,
  zoom,
  transcription,
}

enum IntegrationStatus {
  notConnected,
  connecting,
  connected,
  error,
  disconnected,
}

@freezed
class Integration with _$Integration {
  const factory Integration({
    required String id,
    required IntegrationType type,
    required String name,
    required String description,
    required String iconUrl,
    required IntegrationStatus status,
    Map<String, dynamic>? configuration,
    DateTime? connectedAt,
    DateTime? lastSyncAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) = _Integration;

  factory Integration.fromJson(Map<String, dynamic> json) =>
      _$IntegrationFromJson(json);
}

@freezed
class IntegrationConfig with _$IntegrationConfig {
  const factory IntegrationConfig({
    required String integrationId,
    required IntegrationType type,
    String? apiKey,
    String? apiSecret,
    String? webhookUrl,
    String? webhookSecret,
    Map<String, String>? customSettings,
    bool? autoSync,
    int? syncIntervalMinutes,
    List<String>? allowedProjects,
  }) = _IntegrationConfig;

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) =>
      _$IntegrationConfigFromJson(json);
}

@freezed
class FirefliesData with _$FirefliesData {
  const factory FirefliesData({
    required String transcriptId,
    required String title,
    required String transcript,
    required DateTime meetingDate,
    required int duration,
    List<String>? participants,
    String? meetingUrl,
    String? recordingUrl,
    Map<String, dynamic>? metadata,
  }) = _FirefliesData;

  factory FirefliesData.fromJson(Map<String, dynamic> json) =>
      _$FirefliesDataFromJson(json);
}