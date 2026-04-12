import '../models/transaction_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';

class TransactionRepository {
  final ApiClient apiClient;

  TransactionRepository({required this.apiClient});

  /// Create a transaction after a hardware session completes
  Future<Transaction> createTransaction({
    required String sessionId,
    required String nozzleId,
    required String userId,
    required String fuelType,
    required double litresDispensed,
    required double pricePerLitre,
    String paymentMethod = 'cash',
    String? vehicleId,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/transactions',
        data: {
          'session_id': sessionId,
          'nozzle_id': nozzleId,
          'user_id': userId,
          'fuel_type': fuelType,
          'litres_dispensed': litresDispensed,
          'price_per_litre': pricePerLitre,
          'payment_method': paymentMethod,
          if (vehicleId != null) 'vehicle_id': vehicleId,
        },
      );
      return Transaction.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current fuel prices
  Future<List<FuelPrice>> getCurrentPrices({String? stationId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (stationId != null) queryParams['station_id'] = stationId;

      final response = await apiClient.get<List<dynamic>>(
        '/transactions/prices/current',
        queryParameters: queryParams,
      );

      return response
          .map((item) => FuelPrice.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's transactions with pagination
  Future<TransactionListResponse> getMyTransactions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/transactions/my',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      return TransactionListResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get specific transaction details
  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/transactions/$transactionId',
      );

      return Transaction.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Download receipt PDF
  Future<List<int>> downloadReceipt(String transactionId) async {
    try {
      return await apiClient.downloadFile(
        '/transactions/$transactionId/receipt',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Flag transaction as fraudulent
  Future<void> flagTransaction({
    required String transactionId,
    required String reason,
    required String severity, // 'low', 'medium', 'high'
  }) async {
    try {
      await apiClient.post(
        '/fraud/flag',
        data: {
          'transaction_id': transactionId,
          'reason': reason,
          'severity': severity,
        },
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
