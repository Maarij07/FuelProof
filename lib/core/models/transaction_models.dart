import 'package:json_annotation/json_annotation.dart';

part 'transaction_models.g.dart';

// ============================================================================
// ENUMS FOR TRANSACTIONS
// ============================================================================

enum FuelType {
  @JsonValue('petrol')
  petrol,
  @JsonValue('diesel')
  diesel,
  @JsonValue('premium')
  premium,
  @JsonValue('cng')
  cng,
  @JsonValue('lpg')
  lpg,
}

enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('card')
  card,
  @JsonValue('wallet')
  wallet,
  @JsonValue('qr_pay')
  qrPay,
}

enum TransactionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}

// ============================================================================
// TRANSACTION MODEL
// ============================================================================

@JsonSerializable()
class Transaction {
  final String id;

  @JsonKey(name: 'session_id')
  final String sessionId;

  @JsonKey(name: 'nozzle_id')
  final String nozzleId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;

  @JsonKey(name: 'fuel_type')
  final FuelType fuelType;

  @JsonKey(name: 'litres_dispensed')
  final double litresDispensed;

  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;

  @JsonKey(name: 'total_amount')
  final double totalAmount;

  @JsonKey(name: 'payment_method')
  final PaymentMethod paymentMethod;

  final TransactionStatus status;

  @JsonKey(name: 'employee_id')
  final String? employeeId;

  @JsonKey(name: 'station_id')
  final String? stationId;

  @JsonKey(name: 'receipt_url')
  final String? receiptUrl;

  @JsonKey(name: 'evidence_url')
  final String? evidenceUrl;

  @JsonKey(name: 'is_flagged')
  final bool isFlagged;

  @JsonKey(name: 'created_at')
  final String createdAt;

  Transaction({
    required this.id,
    required this.sessionId,
    required this.nozzleId,
    required this.userId,
    this.vehicleId,
    required this.fuelType,
    required this.litresDispensed,
    required this.pricePerLitre,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.employeeId,
    this.stationId,
    this.receiptUrl,
    this.evidenceUrl,
    required this.isFlagged,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}

// ============================================================================
// TRANSACTION LIST RESPONSE
// ============================================================================

@JsonSerializable()
class TransactionListResponse {
  final int total;
  final List<Transaction> items;

  TransactionListResponse({required this.total, required this.items});

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionListResponseToJson(this);
}

// ============================================================================
// FUEL PRICE MODEL
// ============================================================================

@JsonSerializable()
class FuelPrice {
  @JsonKey(name: 'fuel_type')
  final FuelType fuelType;

  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;

  @JsonKey(name: 'station_id')
  final String? stationId;

  @JsonKey(name: 'effective_from')
  final String effectiveFrom;

  FuelPrice({
    required this.fuelType,
    required this.pricePerLitre,
    this.stationId,
    required this.effectiveFrom,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) =>
      _$FuelPriceFromJson(json);

  Map<String, dynamic> toJson() => _$FuelPriceToJson(this);
}

// ============================================================================
// FRAUD FLAG MODEL
// ============================================================================

enum FraudSeverity {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
}

@JsonSerializable()
class FraudFlagResponse {
  @JsonKey(name: 'alert_id')
  final String alertId;

  final String message;

  FraudFlagResponse({required this.alertId, required this.message});

  factory FraudFlagResponse.fromJson(Map<String, dynamic> json) =>
      _$FraudFlagResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FraudFlagResponseToJson(this);
}
