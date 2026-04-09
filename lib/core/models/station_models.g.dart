// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'station_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Station _$StationFromJson(Map<String, dynamic> json) => Station(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  city: json['city'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  fuelTypesAvailable: (json['fuel_types_available'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  operatingHours: json['operating_hours'] as String?,
  contactPhone: json['contact_phone'] as String?,
  isActive: json['is_active'] as bool,
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
  distanceFromRouteKm: (json['distance_from_route_km'] as num?)?.toDouble(),
  currentPrices: json['current_prices'],
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$StationToJson(Station instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'city': instance.city,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'fuel_types_available': instance.fuelTypesAvailable,
  'operating_hours': instance.operatingHours,
  'contact_phone': instance.contactPhone,
  'is_active': instance.isActive,
  'distance_km': instance.distanceKm,
  'distance_from_route_km': instance.distanceFromRouteKm,
  'current_prices': instance.currentPrices,
  'created_at': instance.createdAt,
};

PriceComparison _$PriceComparisonFromJson(Map<String, dynamic> json) =>
    PriceComparison(
      stationId: json['station_id'] as String,
      stationName: json['station_name'] as String,
      fuelType: json['fuel_type'] as String,
      pricePerLitre: (json['price_per_litre'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      lastUpdated: json['last_updated'] as String?,
    );

Map<String, dynamic> _$PriceComparisonToJson(PriceComparison instance) =>
    <String, dynamic>{
      'station_id': instance.stationId,
      'station_name': instance.stationName,
      'fuel_type': instance.fuelType,
      'price_per_litre': instance.pricePerLitre,
      'distance_km': instance.distanceKm,
      'last_updated': instance.lastUpdated,
    };

CheapestFuel _$CheapestFuelFromJson(Map<String, dynamic> json) => CheapestFuel(
  stationId: json['station_id'] as String,
  stationName: json['station_name'] as String,
  fuelType: json['fuel_type'] as String,
  pricePerLitre: (json['price_per_litre'] as num).toDouble(),
  distanceKm: (json['distance_km'] as num).toDouble(),
  address: json['address'] as String,
);

Map<String, dynamic> _$CheapestFuelToJson(CheapestFuel instance) =>
    <String, dynamic>{
      'station_id': instance.stationId,
      'station_name': instance.stationName,
      'fuel_type': instance.fuelType,
      'price_per_litre': instance.pricePerLitre,
      'distance_km': instance.distanceKm,
      'address': instance.address,
    };

PriceHistory _$PriceHistoryFromJson(Map<String, dynamic> json) => PriceHistory(
  id: json['id'] as String,
  stationId: json['station_id'] as String,
  fuelType: json['fuel_type'] as String,
  pricePerLitre: (json['price_per_litre'] as num).toDouble(),
  updatedBy: json['updated_by'] as String?,
  effectiveFrom: json['effective_from'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$PriceHistoryToJson(PriceHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'station_id': instance.stationId,
      'fuel_type': instance.fuelType,
      'price_per_litre': instance.pricePerLitre,
      'updated_by': instance.updatedBy,
      'effective_from': instance.effectiveFrom,
      'created_at': instance.createdAt,
    };

PriceAlert _$PriceAlertFromJson(Map<String, dynamic> json) => PriceAlert(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  stationId: json['station_id'] as String,
  fuelType: json['fuel_type'] as String,
  targetPrice: (json['target_price'] as num).toDouble(),
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$PriceAlertToJson(PriceAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'station_id': instance.stationId,
      'fuel_type': instance.fuelType,
      'target_price': instance.targetPrice,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };
