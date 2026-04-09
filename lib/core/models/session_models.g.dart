// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
      id: json['id'] as String,
      nozzleId: json['nozzle_id'] as String,
      userId: json['user_id'] as String,
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      qrData: json['qr_data'] as String,
      startedAt: json['started_at'] as String?,
      endedAt: json['ended_at'] as String?,
      expiresAt: json['expires_at'] as String?,
      totalLitres: (json['total_litres'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      transactionId: json['transaction_id'] as String?,
    );

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
      'id': instance.id,
      'nozzle_id': instance.nozzleId,
      'user_id': instance.userId,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'qr_data': instance.qrData,
      'started_at': instance.startedAt,
      'ended_at': instance.endedAt,
      'expires_at': instance.expiresAt,
      'total_litres': instance.totalLitres,
      'total_amount': instance.totalAmount,
      'transaction_id': instance.transactionId,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.pending: 'pending',
  SessionStatus.active: 'active',
  SessionStatus.completed: 'completed',
  SessionStatus.timedOut: 'timed_out',
  SessionStatus.cancelled: 'cancelled',
};

SessionScanResponse _$SessionScanResponseFromJson(Map<String, dynamic> json) =>
    SessionScanResponse(
      sessionId: json['session_id'] as String,
      status: $enumDecode(_$SessionStatusEnumMap, json['status']),
      nozzleId: json['nozzle_id'] as String,
    );

Map<String, dynamic> _$SessionScanResponseToJson(
        SessionScanResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'status': _$SessionStatusEnumMap[instance.status]!,
      'nozzle_id': instance.nozzleId,
    };
