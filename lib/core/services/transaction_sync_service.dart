import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';

import '../models/transaction_models.dart';
import 'api_client.dart';
import 'app_logger.dart';
import 'token_manager.dart';

/// Offline-first transaction queue backed by Hive.
///
/// After a hardware session ends (and the photo is captured from the ESP32),
/// this service saves every pending transaction locally so it is never lost
/// even if the phone is still on FuelMonitor WiFi.
///
/// A connectivity listener auto-drains the queue the moment internet returns —
/// even while the app is in the foreground. Call [syncPending] manually any
/// time you want to force a flush attempt.
class TransactionSyncService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final TransactionSyncService instance = TransactionSyncService._();
  TransactionSyncService._();

  static const _boxName = 'pending_tx';

  Box? _box;
  ApiClient? _apiClient;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _syncing = false;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _apiClient = ApiClient(tokenManager: TokenManager());

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasInternet = results.any(
        (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
      );
      if (hasInternet) {
        AppLogger.log('Sync', 'Network changed — draining queue');
        syncPending();
      }
    });

    // Drain any left-overs from previous app runs at startup.
    syncPending();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Persists a completed hardware session locally, then immediately attempts
  /// to sync to the backend. Returns the backend transaction ID if the first
  /// sync attempt succeeds, or null if it was queued for later.
  Future<String?> save({
    required String sessionId,
    required String nozzleId,
    required String userId,
    required FuelType fuelType,
    required double flowmeterLitres,
    required double dispenserLitres,
    required double pricePerLitre,
    required bool tamperDetected,
    String paymentMethod = 'cash',
    String? vehicleId,
    Uint8List? photo,
  }) async {
    final box = _box;
    if (box == null) {
      AppLogger.error('Sync', 'Hive box not initialised — dropping transaction');
      return null;
    }

    // Use sessionId as key — idempotent if saved twice.
    final key = sessionId;
    await box.put(key, {
      'session_id':       sessionId,
      'nozzle_id':        nozzleId,
      'user_id':          userId,
      'fuel_type':        fuelType.name,
      'flowmeter_litres': flowmeterLitres,
      'dispenser_litres': dispenserLitres,
      'price_per_litre':  pricePerLitre,
      'tamper_detected':  tamperDetected,
      'payment_method':   paymentMethod,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      'photo_b64':        photo != null ? base64Encode(photo) : null,
      'queued_at':        DateTime.now().toIso8601String(),
    });
    AppLogger.log('Sync', 'Queued locally: $key (total=${box.length})');

    // Attempt immediate sync (may fail if still on FuelMonitor WiFi).
    return await _syncOne(key);
  }

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Attempts to post all pending transactions to the backend.
  Future<void> syncPending() async {
    if (_syncing) return;
    final box = _box;
    if (box == null || box.isEmpty) return;

    _syncing = true;
    AppLogger.log('Sync', 'Draining ${box.length} pending transaction(s)');

    for (final key in box.keys.toList()) {
      await _syncOne(key as String);
    }

    _syncing = false;
  }

  /// Tries to sync a single queued item. Returns the backend transaction ID on
  /// success, or null on failure (item stays in the queue).
  Future<String?> _syncOne(String key) async {
    final box = _box;
    final apiClient = _apiClient;
    if (box == null || apiClient == null) return null;

    final raw = box.get(key);
    if (raw == null) return null;
    final data = Map<String, dynamic>.from(raw as Map);

    try {
      // ── 1. Create transaction ────────────────────────────────────────────
      final result = await apiClient.post<Map<String, dynamic>>(
        '/transactions',
        data: {
          'session_id':       data['session_id'],
          'nozzle_id':        data['nozzle_id'],
          'user_id':          data['user_id'],
          'fuel_type':        data['fuel_type'],
          'litres_dispensed': data['dispenser_litres'],
          'price_per_litre':  data['price_per_litre'],
          'payment_method':   data['payment_method'],
          if (data['vehicle_id'] != null) 'vehicle_id': data['vehicle_id'],
        },
      );
      final transactionId = result['id'] as String?;
      if (transactionId == null) throw Exception('Backend returned no id');
      AppLogger.log('Sync', 'Transaction synced → $transactionId');

      // ── 2. Upload evidence photo ─────────────────────────────────────────
      final photoB64 = data['photo_b64'] as String?;
      if (photoB64 != null) {
        try {
          await apiClient.uploadMultipart<dynamic>(
            '/evidence',
            fileBytes: base64Decode(photoB64),
            filename: 'evidence_$transactionId.jpg',
            mimeType: 'image/jpeg',
            queryParams: {
              'transaction_id': transactionId,
              'nozzle_id':      data['nozzle_id'],
              'session_id':     data['session_id'],
              'capture_trigger': 'session_end',
            },
          );
        } catch (e) {
          AppLogger.warn('Sync', 'Evidence upload failed (non-fatal): $e');
        }
      }

      // ── 3. Fraud flag ────────────────────────────────────────────────────
      final hasTamper  = data['tamper_detected'] as bool? ?? false;
      final flowmeter  = (data['flowmeter_litres'] as num?)?.toDouble() ?? 0.0;
      final dispenser  = (data['dispenser_litres'] as num?)?.toDouble() ?? 0.0;
      final discrepancy = (dispenser - flowmeter).abs();

      if (hasTamper || discrepancy > 0.05) {
        try {
          await apiClient.post<dynamic>(
            '/fraud/flag',
            data: {
              'transaction_id': transactionId,
              'reason': hasTamper
                  ? 'Tamper flag was armed during session.'
                  : 'Dispenser over-reported by ${discrepancy.toStringAsFixed(3)} L.',
              'severity': hasTamper ? 'critical' : 'high',
            },
          );
        } catch (_) {}
      }

      // Remove from queue — sync complete.
      await box.delete(key);
      return transactionId;
    } catch (e) {
      AppLogger.warn('Sync', 'Sync failed for $key (will retry): $e');
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int get pendingCount => _box?.length ?? 0;

  void dispose() {
    _connectivitySub?.cancel();
  }
}
