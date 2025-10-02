// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponse _$ApiResponseFromJson(Map<String, dynamic> json) => ApiResponse(
  status: json['status'] as String,
  message: json['message'] as String?,
  data: json['data'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ApiResponseToJson(ApiResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

HealthCheckResponse _$HealthCheckResponseFromJson(Map<String, dynamic> json) =>
    HealthCheckResponse(
      status: json['status'] as String,
      services: json['services'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$HealthCheckResponseToJson(
  HealthCheckResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'services': instance.services,
};
