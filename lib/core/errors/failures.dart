import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server({
    required String message,
    String? code,
  }) = ServerFailure;

  const factory Failure.network({
    required String message,
    String? code,
  }) = NetworkFailure;

  const factory Failure.cache({
    required String message,
    String? code,
  }) = CacheFailure;

  const factory Failure.validation({
    required String message,
    String? code,
  }) = ValidationFailure;

  const factory Failure.unknown({
    required String message,
    String? code,
  }) = UnknownFailure;
}