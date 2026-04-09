import 'package:json_annotation/json_annotation.dart';

part 'session_models.g.dart';

// ============================================================================
// SESSION ENUMS
// ============================================================================

enum SessionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('timed_out')
  timedOut,
  @JsonValue('cancelled')
  cancelled,
}

// ============================================================================
// SESSION MODEL (Active Session during fueling)
// ============================================================================

@JsonSerializable()
class Session {
  final String id;

  @JsonKey(name: 'nozzle_id')
  final String nozzleId;

  @JsonKey(name: 'user_id')
  final String userId;

  final SessionStatus status;

  @JsonKey(name: 'qr_data')
  final String qrData;

  @JsonKey(name: 'started_at')
  final String? startedAt;

  @JsonKey(name: 'ended_at')
  final String? endedAt;

  @JsonKey(name: 'expires_at')
  final String? expiresAt;

  @JsonKey(name: 'total_litres')
  final double totalLitres;

  @JsonKey(name: 'total_amount')
  final double totalAmount;

  @JsonKey(name: 'transaction_id')
  final String? transactionId;

  Session({
    required this.id,
    required this.nozzleId,
    required this.userId,
    required this.status,
    required this.qrData,
    this.startedAt,
    this.endedAt,
    this.expiresAt,
    required this.totalLitres,
    required this.totalAmount,
    this.transactionId,
  });

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);

  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

// ============================================================================
// SESSION SCAN RESPONSE (From QR scan)
// ============================================================================

@JsonSerializable()
class SessionScanResponse {
  @JsonKey(name: 'session_id')
  final String sessionId;

  final SessionStatus status;

  @JsonKey(name: 'nozzle_id')
  final String nozzleId;

  SessionScanResponse({
    required this.sessionId,
    required this.status,
    required this.nozzleId,
  });

  factory SessionScanResponse.fromJson(Map<String, dynamic> json) =>
      _$SessionScanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionScanResponseToJson(this);
}
