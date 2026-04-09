import '../models/station_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';

class StationRepository {
  final ApiClient apiClient;

  StationRepository({required this.apiClient});

  /// Get all stations with filters
  Future<List<Station>> getStations({
    String? city,
    String? fuelType,
    bool isActive = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{'is_active': isActive};
      if (city != null) queryParams['city'] = city;
      if (fuelType != null) queryParams['fuel_type'] = fuelType;

      final response = await apiClient.get<List<dynamic>>(
        '/stations',
        queryParameters: queryParams,
      );

      return response
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get station by ID
  Future<Station> getStation(String stationId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/stations/$stationId',
      );

      return Station.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get nearby stations
  Future<List<Station>> getNearbyStations({
    required double latitude,
    required double longitude,
    int radiusKm = 10,
    String? fuelType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      };
      if (fuelType != null) queryParams['fuel_type'] = fuelType;

      final response = await apiClient.get<List<dynamic>>(
        '/stations/nearby',
        queryParameters: queryParams,
      );

      return response
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get stations along a route
  Future<List<Station>> getRouteStations({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    String? fuelType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'origin_lat': originLat,
        'origin_lng': originLng,
        'dest_lat': destLat,
        'dest_lng': destLng,
      };
      if (fuelType != null) queryParams['fuel_type'] = fuelType;

      final response = await apiClient.get<List<dynamic>>(
        '/stations/route',
        queryParameters: queryParams,
      );

      return response
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get favorite stations
  Future<List<Station>> getFavoriteStations() async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        '/stations/me/favorites',
      );

      return response
          .map((item) => Station.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Add station to favorites
  Future<void> addFavorite(String stationId) async {
    try {
      await apiClient.post('/stations/me/favorites/$stationId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Remove station from favorites
  Future<void> removeFavorite(String stationId) async {
    try {
      await apiClient.delete('/stations/me/favorites/$stationId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  AppError _handleError(dynamic error) {
    if (error is AppError) return error;
    return AppError(message: 'An unexpected error occurred');
  }
}
