import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/error_models.dart';
import '../models/report_models.dart';
import '../models/transaction_models.dart';
import '../services/api_client.dart';
import '../services/app_logger.dart';

class TransactionRepository {
  final ApiClient apiClient;

  static const _cacheBox = 'tx_cache';
  static const _cacheKey = 'my_transactions';

  TransactionRepository({required this.apiClient});

  // ── Create ───────────────────────────────────────────────────────────────────

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
      final payload = <String, dynamic>{
        'session_id': sessionId,
        'nozzle_id': nozzleId,
        'user_id': userId,
        'fuel_type': fuelType,
        'litres_dispensed': litresDispensed,
        'price_per_litre': pricePerLitre,
        'payment_method': paymentMethod,
      };
      if (vehicleId != null) payload['vehicle_id'] = vehicleId;

      final response = await apiClient.post<Map<String, dynamic>>(
        '/transactions',
        data: payload,
      );
      return Transaction.fromJson(response);
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── Current prices ───────────────────────────────────────────────────────────

  Future<List<FuelPrice>> getCurrentPrices({String? stationId}) async {
    try {
      final params = <String, dynamic>{};
      if (stationId != null) params['station_id'] = stationId;
      final response = await apiClient.get<List<dynamic>>(
        '/transactions/prices/current',
        queryParameters: params,
      );
      return response
          .map((item) => FuelPrice.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── My transactions (with cache) ─────────────────────────────────────────────

  /// Returns cached data immediately (if available) while a fresh fetch runs
  /// in the background.  Call [getMyTransactions] when you want the network
  /// result explicitly; call [getCachedTransactions] for an instant render.
  TransactionListResponse? getCachedTransactions() {
    try {
      final box = Hive.box(_cacheBox);
      final raw = box.get(_cacheKey) as String?;
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return _parseListResponse(decoded);
    } catch (e) {
      AppLogger.error('TxRepo', 'Cache read error: $e');
      return null;
    }
  }

  Future<TransactionListResponse> getMyTransactions({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/transactions/my',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final result = _parseListResponse(response);

      // Persist to cache for next session
      _writeCache(response);

      return result;
    } catch (e) {
      AppLogger.error('TxRepo', 'getMyTransactions error: $e');
      throw _wrap(e);
    }
  }

  TransactionListResponse _parseListResponse(Map<String, dynamic> response) {
    final rawItems = (response['items'] as List?) ?? [];
    final items = <Transaction>[];
    for (final raw in rawItems) {
      try {
        items.add(Transaction.fromJson(raw as Map<String, dynamic>));
      } catch (e) {
        // Skip unparseable record rather than crashing the whole list
        AppLogger.error('TxRepo', 'Skipped unparseable transaction: $e');
      }
    }
    final total = (response['total'] as num?)?.toInt() ?? items.length;
    return TransactionListResponse(total: total, items: items);
  }

  void _writeCache(Map<String, dynamic> response) {
    try {
      final box = Hive.box(_cacheBox);
      box.put(_cacheKey, jsonEncode(response));
    } catch (e) {
      AppLogger.error('TxRepo', 'Cache write error: $e');
    }
  }

  // ── Single transaction ───────────────────────────────────────────────────────

  Future<Transaction> getTransaction(String transactionId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/transactions/$transactionId',
      );
      return Transaction.fromJson(response);
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── Receipt ──────────────────────────────────────────────────────────────────

  Future<List<int>> downloadReceipt(String transactionId) async {
    try {
      return await apiClient.downloadFile(
        '/transactions/$transactionId/receipt',
      );
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── Fraud flag ───────────────────────────────────────────────────────────────

  Future<void> flagTransaction({
    required String transactionId,
    required String reason,
    required String severity,
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
      throw _wrap(e);
    }
  }

  // ── Report summary ───────────────────────────────────────────────────────────

  Future<MyReportSummary> getMyReportSummary({String period = 'monthly'}) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/reports/my-summary',
        queryParameters: {'period': period},
      );
      return MyReportSummary.fromJson(response);
    } catch (e) {
      throw _wrap(e);
    }
  }

  Future<MyComparative> getMyComparative({String period = 'monthly'}) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/reports/my-comparative',
        queryParameters: {'period': period},
      );
      return MyComparative.fromJson(response);
    } catch (e) {
      throw _wrap(e);
    }
  }

  Future<List<int>> exportMyReport({
    required String format,
    required String period,
  }) async {
    try {
      return await apiClient.postDownload(
        '/reports/my-export',
        queryParameters: {'format': format, 'period': period},
      );
    } catch (e) {
      throw _wrap(e);
    }
  }

  // ── Error helper ─────────────────────────────────────────────────────────────

  AppError _wrap(dynamic error) {
    if (error is AppError) return error;
    final msg = error.toString().replaceFirst('Exception: ', '');
    AppLogger.error('TxRepo', 'Unexpected error: $msg');
    return AppError(message: msg.isNotEmpty ? msg : 'An unexpected error occurred');
  }
}
