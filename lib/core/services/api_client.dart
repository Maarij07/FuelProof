import 'package:dio/dio.dart';
import '../models/error_models.dart';
import 'app_logger.dart';
import 'token_manager.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://web-production-0cb0e.up.railway.app/api/v1',
  );
  static const int _connectionTimeout = 30000;
  static const int _receiveTimeout = 30000;

  final Dio _dio;
  final TokenManager tokenManager;

  ApiClient({required this.tokenManager, Dio? dio}) : _dio = dio ?? Dio() {
    AppLogger.log('ApiClient', 'Base URL: $baseUrl');
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: _connectionTimeout),
      receiveTimeout: const Duration(milliseconds: _receiveTimeout),
      headers: {'Content-Type': 'application/json'},
    );

    // Logging interceptor — must be added before the auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.log('API', '→ ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.log(
            'API',
            '← ${response.statusCode} ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          final status = error.response?.statusCode ?? '?';
          final body = error.response?.data?.toString() ?? error.message;
          AppLogger.error(
            'API',
            '✗ $status ${error.requestOptions.path} — $body',
          );
          return handler.next(error);
        },
      ),
    );

    // Add request interceptor for token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenManager.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 - Try to refresh token
          if (error.response?.statusCode == 401) {
            try {
              final refreshToken = await tokenManager.getRefreshToken();
              if (refreshToken != null) {
                final newTokens = await _refreshToken(refreshToken);
                if (newTokens != null) {
                  // Update token and retry request
                  await tokenManager.updateAccessToken(
                    newTokens['access_token'],
                  );
                  final options = error.requestOptions;
                  options.headers['Authorization'] =
                      'Bearer ${newTokens['access_token']}';
                  return handler.resolve(
                    await _dio.request(
                      options.path,
                      data: options.data,
                      queryParameters: options.queryParameters,
                      options: Options(
                        method: options.method,
                        headers: options.headers,
                        responseType: options.responseType,
                        contentType: options.contentType,
                        followRedirects: options.followRedirects,
                        validateStatus: options.validateStatus,
                        receiveDataWhenStatusError:
                            options.receiveDataWhenStatusError,
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              // Refresh failed - will be handled in UI layer
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Refresh access token using refresh token
  Future<Map<String, dynamic>?> _refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return response.data;
    } catch (e) {
      return null;
    }
  }

  /// GET request
  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request
  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
      );
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<T> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
      );
      if (parser != null) {
        return parser(response.data);
      }
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Multipart file upload (for evidence photos)
  Future<T> uploadMultipart<T>(
    String endpoint, {
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
    Map<String, String>? queryParams,
    T Function(dynamic)? parser,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParams,
      );
      if (parser != null) return parser(response.data);
      return response.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Download file (for receipts)
  Future<List<int>> downloadFile(String endpoint) async {
    try {
      final response = await _dio.get(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Error handling
  AppError _handleError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final detail = error.response?.data?['detail'] as String?;

      switch (statusCode) {
        case 400:
          return AppError(
            message: detail ?? 'Bad request - please check your inputs',
            statusCode: 400,
            detail: detail,
          );
        case 401:
          return AppError(
            message: 'Session expired - please login again',
            statusCode: 401,
            detail: detail,
          );
        case 403:
          return AppError(
            message: 'Access denied',
            statusCode: 403,
            detail: detail,
          );
        case 404:
          return AppError(
            message: 'Not found',
            statusCode: 404,
            detail: detail,
          );
        case 422:
          return AppError(
            message: 'Validation error',
            statusCode: 422,
            detail: detail,
          );
        case 500:
          return AppError(
            message: 'Server error - please try again later',
            statusCode: 500,
            detail: detail,
          );
        default:
          return AppError(
            message: error.message ?? 'Unknown error occurred',
            statusCode: statusCode,
            detail: detail,
          );
      }
    }

    return AppError(message: 'An unexpected error occurred');
  }
}
