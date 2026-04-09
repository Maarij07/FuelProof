import 'package:json_annotation/json_annotation.dart';

part 'error_models.g.dart';

// ============================================================================
// API ERROR MODEL
// ============================================================================

@JsonSerializable()
class ApiErrorResponse {
  final String detail;

  ApiErrorResponse({required this.detail});

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);
}

// ============================================================================
// APP ERROR CLASS (for UI handling)
// ============================================================================

class AppError implements Exception {
  final String message;
  final int? statusCode;
  final String? detail;

  AppError({required this.message, this.statusCode, this.detail});

  @override
  String toString() => message;
}
