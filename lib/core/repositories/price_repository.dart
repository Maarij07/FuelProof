import '../models/station_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';

class PriceRepository {
  final ApiClient apiClient;

  PriceRepository({required this.apiClient});

  /// Compare prices for a specific fuel type
  Future<List<PriceComparison>> comparePrices({
    required String fuelType,
    required double latitude,
    required double longitude,
    int radiusKm = 20,
  }) async {
    try {
      final response = await apiClient.get<List<dynamic>>(
        '/prices/compare',
        queryParameters: {
          'fuel_type': fuelType,
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
        },
      );

      return response
          .map((item) => PriceComparison.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get cheapest fuel station
  Future<CheapestFuel> getCheapestFuel({
    required String fuelType,
    required double latitude,
    required double longitude,
    int radiusKm = 20,
  }) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/prices/cheapest',
        queryParameters: {
          'fuel_type': fuelType,
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
        },
      );

      return CheapestFuel.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get price history for a station
  Future<List<PriceHistory>> getPriceHistory({
    required String stationId,
    String? fuelType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fuelType != null) queryParams['fuel_type'] = fuelType;

      final response = await apiClient.get<List<dynamic>>(
        '/prices/$stationId/history',
        queryParameters: queryParams,
      );

      return response
          .map((item) => PriceHistory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create price alert
  Future<PriceAlert> createPriceAlert({
    required String stationId,
    required String fuelType,
    required double targetPrice,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/prices/alerts',
        data: {
          'station_id': stationId,
          'fuel_type': fuelType,
          'target_price': targetPrice,
        },
      );

      return PriceAlert.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get all price alerts
  Future<List<PriceAlert>> getPriceAlerts() async {
    try {
      final response = await apiClient.get<List<dynamic>>('/prices/alerts');

      return response
          .map((item) => PriceAlert.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete price alert
  Future<void> deletePriceAlert(String alertId) async {
    try {
      await apiClient.delete('/prices/alerts/$alertId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update price alert active state
  Future<void> setPriceAlertActive({
    required String alertId,
    required bool isActive,
  }) async {
    try {
      await apiClient.put(
        '/prices/alerts/$alertId',
        data: {'is_active': isActive},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  AppError _handleError(dynamic error) {
    if (error is AppError) return error;
    return AppError(message: 'An unexpected error occurred');
  }
}
