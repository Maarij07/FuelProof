// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      nozzleId: json['nozzle_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      vehicleId: json['vehicle_id'] as String?,
      fuelType: $enumDecodeNullable(_$FuelTypeEnumMap, json['fuel_type']) ??
          FuelType.petrol,
      litresDispensed: (json['litres_dispensed'] as num?)?.toDouble() ?? 0.0,
      pricePerLitre: (json['price_per_litre'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod:
          $enumDecodeNullable(_$PaymentMethodEnumMap, json['payment_method']) ??
              PaymentMethod.cash,
      status:
          $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']) ??
              TransactionStatus.completed,
      employeeId: json['employee_id'] as String?,
      stationId: json['station_id'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      evidenceUrl: json['evidence_url'] as String?,
      isFlagged: json['is_flagged'] as bool? ?? false,
      createdAt: json['created_at']?.toString() ?? '',
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'nozzle_id': instance.nozzleId,
      'user_id': instance.userId,
      'vehicle_id': instance.vehicleId,
      'fuel_type': _$FuelTypeEnumMap[instance.fuelType]!,
      'litres_dispensed': instance.litresDispensed,
      'price_per_litre': instance.pricePerLitre,
      'total_amount': instance.totalAmount,
      'payment_method': _$PaymentMethodEnumMap[instance.paymentMethod]!,
      'status': _$TransactionStatusEnumMap[instance.status]!,
      'employee_id': instance.employeeId,
      'station_id': instance.stationId,
      'receipt_url': instance.receiptUrl,
      'evidence_url': instance.evidenceUrl,
      'is_flagged': instance.isFlagged,
      'created_at': instance.createdAt,
    };

const _$FuelTypeEnumMap = {
  FuelType.petrol: 'petrol',
  FuelType.diesel: 'diesel',
  FuelType.premium: 'premium',
  FuelType.cng: 'cng',
  FuelType.lpg: 'lpg',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.card: 'card',
  PaymentMethod.wallet: 'wallet',
  PaymentMethod.qrPay: 'qr_pay',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.pending: 'pending',
  TransactionStatus.completed: 'completed',
  TransactionStatus.failed: 'failed',
  TransactionStatus.refunded: 'refunded',
};

TransactionListResponse _$TransactionListResponseFromJson(
        Map<String, dynamic> json) =>
    TransactionListResponse(
      total: (json['total'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TransactionListResponseToJson(
        TransactionListResponse instance) =>
    <String, dynamic>{
      'total': instance.total,
      'items': instance.items,
    };

FuelPrice _$FuelPriceFromJson(Map<String, dynamic> json) => FuelPrice(
      fuelType: $enumDecode(_$FuelTypeEnumMap, json['fuel_type']),
      pricePerLitre: (json['price_per_litre'] as num).toDouble(),
      stationId: json['station_id'] as String?,
      effectiveFrom: json['effective_from'] as String,
    );

Map<String, dynamic> _$FuelPriceToJson(FuelPrice instance) => <String, dynamic>{
      'fuel_type': _$FuelTypeEnumMap[instance.fuelType]!,
      'price_per_litre': instance.pricePerLitre,
      'station_id': instance.stationId,
      'effective_from': instance.effectiveFrom,
    };

FraudFlagResponse _$FraudFlagResponseFromJson(Map<String, dynamic> json) =>
    FraudFlagResponse(
      alertId: json['alert_id'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$FraudFlagResponseToJson(FraudFlagResponse instance) =>
    <String, dynamic>{
      'alert_id': instance.alertId,
      'message': instance.message,
    };
