import 'package:json_annotation/json_annotation.dart';

part 'station_models.g.dart';

// ============================================================================
// STATION MODEL
// ============================================================================

@JsonSerializable()
class Station {
  final String id;

  final String name;

  final String address;

  final String city;

  final double latitude;

  final double longitude;

  @JsonKey(name: 'fuel_types_available')
  final List<String> fuelTypesAvailable;

  @JsonKey(name: 'operating_hours')
  final String? operatingHours;

  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  @JsonKey(name: 'distance_from_route_km')
  final double? distanceFromRouteKm;

  @JsonKey(name: 'current_prices')
  final dynamic currentPrices;

  @JsonKey(name: 'created_at')
  final String createdAt;

  Station({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.fuelTypesAvailable,
    this.operatingHours,
    this.contactPhone,
    required this.isActive,
    this.distanceKm,
    this.distanceFromRouteKm,
    this.currentPrices,
    required this.createdAt,
  });

  factory Station.fromJson(Map<String, dynamic> json) =>
      _$StationFromJson(json);

  Map<String, dynamic> toJson() => _$StationToJson(this);
}

// ============================================================================
// PRICE COMPARISON MODEL
// ============================================================================

@JsonSerializable()
class PriceComparison {
  @JsonKey(name: 'station_id')
  final String stationId;

  @JsonKey(name: 'station_name')
  final String stationName;

  @JsonKey(name: 'fuel_type')
  final String fuelType;

  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;

  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  @JsonKey(name: 'last_updated')
  final String? lastUpdated;

  PriceComparison({
    required this.stationId,
    required this.stationName,
    required this.fuelType,
    required this.pricePerLitre,
    this.distanceKm,
    this.lastUpdated,
  });

  factory PriceComparison.fromJson(Map<String, dynamic> json) =>
      _$PriceComparisonFromJson(json);

  Map<String, dynamic> toJson() => _$PriceComparisonToJson(this);
}

// ============================================================================
// CHEAPEST FUEL MODEL
// ============================================================================

@JsonSerializable()
class CheapestFuel {
  @JsonKey(name: 'station_id')
  final String stationId;

  @JsonKey(name: 'station_name')
  final String stationName;

  @JsonKey(name: 'fuel_type')
  final String fuelType;

  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;

  @JsonKey(name: 'distance_km')
  final double distanceKm;

  final String address;

  CheapestFuel({
    required this.stationId,
    required this.stationName,
    required this.fuelType,
    required this.pricePerLitre,
    required this.distanceKm,
    required this.address,
  });

  factory CheapestFuel.fromJson(Map<String, dynamic> json) =>
      _$CheapestFuelFromJson(json);

  Map<String, dynamic> toJson() => _$CheapestFuelToJson(this);
}

// ============================================================================
// PRICE HISTORY MODEL
// ============================================================================

@JsonSerializable()
class PriceHistory {
  final String id;

  @JsonKey(name: 'station_id')
  final String stationId;

  @JsonKey(name: 'fuel_type')
  final String fuelType;

  @JsonKey(name: 'price_per_litre')
  final double pricePerLitre;

  @JsonKey(name: 'updated_by')
  final String? updatedBy;

  @JsonKey(name: 'effective_from')
  final String effectiveFrom;

  @JsonKey(name: 'created_at')
  final String createdAt;

  PriceHistory({
    required this.id,
    required this.stationId,
    required this.fuelType,
    required this.pricePerLitre,
    this.updatedBy,
    required this.effectiveFrom,
    required this.createdAt,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) =>
      _$PriceHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PriceHistoryToJson(this);
}

// ============================================================================
// PRICE ALERT MODEL
// ============================================================================

@JsonSerializable()
class PriceAlert {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'station_id')
  final String stationId;

  @JsonKey(name: 'fuel_type')
  final String fuelType;

  @JsonKey(name: 'target_price')
  final double targetPrice;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final String createdAt;

  PriceAlert({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.fuelType,
    required this.targetPrice,
    required this.isActive,
    required this.createdAt,
  });

  factory PriceAlert.fromJson(Map<String, dynamic> json) =>
      _$PriceAlertFromJson(json);

  Map<String, dynamic> toJson() => _$PriceAlertToJson(this);
}
