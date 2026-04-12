import '../models/session_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';

class SessionRepository {
  final ApiClient apiClient;

  SessionRepository({required this.apiClient});

  /// Scan QR code and initiate session
  Future<SessionScanResponse> scanQrCode(String qrData) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/sessions/scan',
        data: {'qr_data': qrData},
      );

      return SessionScanResponse.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get active session details (for polling)
  Future<Session> getSession(String sessionId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/sessions/$sessionId',
      );

      return Session.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Close/End session
  Future<void> closeSession({
    required String sessionId,
    String reason = 'manual',
  }) async {
    try {
      await apiClient.post(
        '/sessions/$sessionId/close',
        data: {'reason': reason},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Device-initiated session — called after connecting to ESP32 WiFi and
  /// querying /info for the nozzle_id. No QR scan involved.
  Future<SessionScanResponse> startDeviceSession(String nozzleId) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/sessions/start',
        data: {'nozzle_id': nozzleId},
      );
      return SessionScanResponse(
        sessionId: response['session_id'] as String,
        nozzleId:  response['nozzle_id']  as String,
        status:    SessionStatus.active,
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
