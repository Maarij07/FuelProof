import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/transaction_models.dart';
import 'api_client.dart';
import 'app_logger.dart';

// ── Sensor data model ─────────────────────────────────────────────────────────

enum DeviceState { idle, running, finished }

class SensorReading {
  final double flowmeter;
  final double dispenser;
  final DeviceState state;
  final bool tamper;

  const SensorReading({
    required this.flowmeter,
    required this.dispenser,
    required this.state,
    required this.tamper,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
    flowmeter: (json['flowmeter'] as num).toDouble(),
    dispenser: (json['dispenser'] as num).toDouble(),
    state: _parseState(json['state'] as String),
    tamper: json['tamper'] as bool,
  );

  static DeviceState _parseState(String s) {
    switch (s) {
      case 'running':
        return DeviceState.running;
      case 'finished':
        return DeviceState.finished;
      default:
        return DeviceState.idle;
    }
  }

  /// Positive = dispenser over-reported. Negative = dispenser under-reported.
  double get discrepancy => dispenser - flowmeter;

  /// True if the absolute discrepancy exceeds the 0.05 L tolerance.
  bool get hasDiscrepancy => discrepancy.abs() > 0.05;
}

// ── Session result model ──────────────────────────────────────────────────────

class HardwareSessionResult {
  final double flowmeterLitres;
  final double dispenserLitres;
  final double discrepancy;
  final bool tamperDetected;
  final Uint8List? capturedImage;

  /// Set after background sync completes. Null while sync is pending.
  final String? transactionId;

  /// Set after background sync completes.
  final bool fraudFlagged;

  const HardwareSessionResult({
    required this.flowmeterLitres,
    required this.dispenserLitres,
    required this.discrepancy,
    required this.tamperDetected,
    this.capturedImage,
    this.transactionId,
    this.fraudFlagged = false,
  });

  HardwareSessionResult withSyncResult({
    required String transactionId,
    required bool fraudFlagged,
  }) => HardwareSessionResult(
    flowmeterLitres: flowmeterLitres,
    dispenserLitres: dispenserLitres,
    discrepancy:     discrepancy,
    tamperDetected:  tamperDetected,
    capturedImage:   capturedImage,
    transactionId:   transactionId,
    fraudFlagged:    fraudFlagged,
  );
}

// ── Internal enum helpers ─────────────────────────────────────────────────────

extension _FuelTypeBackend on FuelType {
  // All FuelType.name values match backend strings (petrol, diesel, premium, cng, lpg)
  String get backendValue => name;
}

extension _FraudSeverityBackend on FraudSeverity {
  String get backendValue {
    switch (this) {
      case FraudSeverity.low:      return 'low';
      case FraudSeverity.medium:   return 'medium';
      case FraudSeverity.high:     return 'high';
      case FraudSeverity.critical: return 'critical';
    }
  }
}

extension _PaymentMethodBackend on PaymentMethod {
  String get backendValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.wallet:
        return 'wallet';
      case PaymentMethod.qrPay:
        return 'qr_pay';
    }
  }
}

// ── Hardware Service ──────────────────────────────────────────────────────────

/// Manages the full lifecycle of a hardware dispensing session.
///
/// Communication split:
///   - ESP32 at 192.168.4.1  → dedicated [_deviceDio] (no auth, short timeout)
///   - Backend (Railway)     → [apiClient] (auth interceptor, standard timeout)
///
/// The phone may reach the backend via mobile data while on the FuelMonitor
/// WiFi (Android/iOS route internet-bound traffic over cellular when the
/// connected WiFi has no internet gateway). If backend calls fail during
/// polling they are retried at [_finalise] which runs after the poll stops.
class HardwareService {
  static const String _deviceBase = 'http://192.168.4.1';
  static const double _discrepancyTolerance = 0.05;

  final ApiClient apiClient;
  final String sessionId;
  final String nozzleId;
  final String userId;
  final FuelType fuelType;
  final double pricePerLitre;
  final PaymentMethod paymentMethod;
  final String? vehicleId;

  /// Called every second with the latest sensor reading.
  final void Function(SensorReading reading) onReading;

  /// Called ONCE, immediately when tamper=true is first detected.
  final void Function() onTamperDetected;

  /// Called after photo capture and local save — backend sync happens separately.
  final void Function(HardwareSessionResult result) onComplete;

  /// Called on unrecoverable errors (device unreachable).
  final void Function(String error) onError;

  late final Dio _deviceDio;
  Timer? _pollTimer;
  bool _tamperAlertFired = false;
  bool _sessionFinished = false;

  HardwareService({
    required this.apiClient,
    required this.sessionId,
    required this.nozzleId,
    required this.userId,
    required this.fuelType,
    required this.pricePerLitre,
    this.paymentMethod = PaymentMethod.cash,
    this.vehicleId,
    required this.onReading,
    required this.onTamperDetected,
    required this.onComplete,
    required this.onError,
  }) {
    _deviceDio = Dio(
      BaseOptions(
        baseUrl: _deviceBase,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );
  }

  /// Triggers session start on the ESP32, then begins 1-second polling.
  Future<void> start() async {
    AppLogger.log('HW', 'Attempting to reach ESP32 at $_deviceBase ...');
    try {
      // GET / starts the session on hardware; response body is HTML — discard it.
      await _deviceDio.get('/');
      AppLogger.log('HW', 'ESP32 reachable — starting poll loop');
    } catch (e) {
      AppLogger.error('HW', 'ESP32 unreachable: $e');
      onError(
        'Cannot reach device at 192.168.4.1.\n'
        'Make sure the phone is connected to the FuelMonitor WiFi network.',
      );
      return;
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final response = await _deviceDio.get<Map<String, dynamic>>('/data');
      final reading = SensorReading.fromJson(response.data!);

      AppLogger.debug(
        'HW',
        'poll: state=${reading.state.name} '
        'flow=${reading.flowmeter.toStringAsFixed(3)}L '
        'disp=${reading.dispenser.toStringAsFixed(3)}L '
        'tamper=${reading.tamper}',
      );

      onReading(reading);

      // Tamper: fire backend alert immediately on first detection.
      // unawaited — never blocks the poll loop.
      if (reading.tamper && !_tamperAlertFired) {
        _tamperAlertFired = true;
        AppLogger.warn('HW', 'TAMPER detected — firing alert to backend');
        onTamperDetected();
        _fireTamperAlertNow();
      }

      // Session end: stop polling and process results.
      if (reading.state == DeviceState.finished && !_sessionFinished) {
        _sessionFinished = true;
        _pollTimer?.cancel();
        AppLogger.log(
          'HW',
          'Session FINISHED — flow=${reading.flowmeter.toStringAsFixed(3)}L '
          'disp=${reading.dispenser.toStringAsFixed(3)}L '
          'discrepancy=${reading.discrepancy.toStringAsFixed(3)}L',
        );
        await _finalise(reading);
      }
    } catch (e) {
      AppLogger.warn('HW', 'Poll error (transient): $e');
    }
  }

  /// Fires tamper alert to the backend without awaiting (best-effort).
  /// If this fails (no internet while on FuelMonitor WiFi), the fraud flag
  /// in TransactionSyncService will capture it with full transaction context.
  void _fireTamperAlertNow() {
    apiClient
        .post<dynamic>(
          '/nozzles/$nozzleId/tamper-alert',
          data: {
            'nozzle_id':  nozzleId,
            'alert_type': 'hardware_tamper',
            'description':
                'Tamper flag armed before session start. '
                'Dispenser reading may be artificially inflated.',
          },
        )
        .catchError((_) {});
  }

  Future<void> _finalise(SensorReading finalReading) async {
    // ── Capture photo from ESP32 (still on FuelMonitor WiFi — this always works) ──
    AppLogger.log('HW', 'Finalise: capturing photo from /capture');
    Uint8List? photo;
    try {
      final response = await _deviceDio.get<List<int>>(
        '/capture',
        options: Options(responseType: ResponseType.bytes),
      );
      photo = Uint8List.fromList(response.data!);
      AppLogger.log('HW', 'Photo captured: ${photo.length} bytes');
    } catch (e) {
      AppLogger.warn('HW', 'Photo capture failed (non-fatal): $e');
    }

    // Deliver result immediately — backend sync is handled by TransactionSyncService.
    onComplete(
      HardwareSessionResult(
        flowmeterLitres: finalReading.flowmeter,
        dispenserLitres: finalReading.dispenser,
        discrepancy:     finalReading.discrepancy,
        tamperDetected:  finalReading.tamper,
        capturedImage:   photo,
      ),
    );
  }

/// Resets the ESP32 for a new session. Call before [start] on subsequent sessions.
  Future<void> resetDevice() async {
    _pollTimer?.cancel();
    _tamperAlertFired = false;
    _sessionFinished = false;
    try {
      await _deviceDio.get('/reset');
    } catch (_) {}
  }

  void dispose() {
    _pollTimer?.cancel();
    _deviceDio.close();
  }
}
