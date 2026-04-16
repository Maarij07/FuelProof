import 'dart:typed_data';

import '../models/auth_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';
import '../services/token_manager.dart';

class AuthRepository {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  AuthRepository({required this.apiClient, required this.tokenManager});

  /// Sign up with email, password, and name
  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'role': 'customer',
        },
      );

      final authResponse = AuthResponse.fromJson(response);

      // Save tokens
      await tokenManager.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.uid,
        role: authResponse.role,
      );

      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Log in with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response);

      // Save tokens
      await tokenManager.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.uid,
        role: authResponse.role,
      );

      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
      await tokenManager.clearTokens();
    } catch (e) {
      // Clear tokens even if API call fails
      await tokenManager.clearTokens();
      throw _handleError(e);
    }
  }

  /// Send forgot password OTP to email
  Future<void> forgotPassword({required String email}) async {
    try {
      await apiClient.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Reset password using a Firebase ID token and the new password.
  Future<void> resetPassword({
    required String firebaseIdToken,
    required String newPassword,
  }) async {
    try {
      await apiClient.post(
        '/auth/reset-password',
        data: {
          'firebase_id_token': firebaseIdToken,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Refresh access token
  Future<AuthResponse> refreshToken() async {
    try {
      final refreshToken = await tokenManager.getRefreshToken();
      if (refreshToken == null) {
        throw AppError(message: 'No refresh token available');
      }

      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
      );

      final authResponse = AuthResponse.fromJson(response);

      // Update access token
      await tokenManager.updateAccessToken(authResponse.accessToken);

      return authResponse;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current user profile
  Future<User> getCurrentUser() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Returns true only when backend explicitly marks the account/email verified.
  Future<bool> isAccountVerified() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>('/users/me');

      const boolKeys = <String>[
        'is_verified',
        'email_verified',
        'is_email_verified',
        'verified',
      ];

      for (final key in boolKeys) {
        final value = response[key];
        if (value is bool) {
          return value;
        }
      }

      final verificationStatus = response['verification_status'];
      if (verificationStatus is String) {
        return verificationStatus.toLowerCase() == 'verified';
      }

      final status = response['status'];
      if (status is String) {
        return status.toLowerCase() == 'verified';
      }

      return false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (avatarUrl != null) data['avatar_url'] = avatarUrl;

      final response = await apiClient.put<Map<String, dynamic>>(
        '/users/me',
        data: data,
      );
      return User.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload avatar image — sends raw bytes as multipart, backend stores on Cloudinary
  Future<User> uploadAvatar(Uint8List bytes, String filename) async {
    try {
      final response = await apiClient.uploadMultipart<Map<String, dynamic>>(
        '/users/me/avatar',
        fileBytes: bytes,
        filename: filename,
        mimeType: 'image/jpeg',
      );
      return User.fromJson(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiClient.put(
        '/users/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
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
