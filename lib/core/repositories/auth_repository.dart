import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/auth_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';
import '../services/token_manager.dart';

class AuthRepository {
  final ApiClient apiClient;
  final TokenManager tokenManager;

  AuthRepository({required this.apiClient, required this.tokenManager});

  /// Sign up — Firebase Auth handles credentials, backend stores the profile.
  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // 1. Create Firebase Auth account (Firebase manages the password).
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final idToken = await credential.user!.getIdToken();

      // 2. Register the profile in the backend using the Firebase ID token.
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/signup',
        data: {
          'firebase_id_token': idToken,
          'full_name': fullName,
          'phone': phone,
          'role': 'customer',
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      await tokenManager.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.uid,
        role: authResponse.role,
      );

      return authResponse;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Log in — Firebase Auth verifies credentials, backend issues its JWT.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign into Firebase Auth.
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final idToken = await credential.user!.getIdToken();

      // 2. Exchange the Firebase ID token for a backend JWT pair.
      final response = await apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'firebase_id_token': idToken},
      );

      final authResponse = AuthResponse.fromJson(response);
      await tokenManager.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.uid,
        role: authResponse.role,
      );

      return authResponse;
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
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

  /// Send password reset email directly via Firebase — no backend call needed.
  Future<void> forgotPassword({required String email}) async {
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
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

  /// Reloads the Firebase Auth user and returns whether their email is verified.
  ///
  /// When [expectedEmail] is provided, the currently signed-in Firebase user
  /// must match that email (case-insensitive) to be considered verified.
  Future<bool> isAccountVerified({String? expectedEmail}) async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      await user.reload();
      final refreshedUser = fb.FirebaseAuth.instance.currentUser;
      if (refreshedUser == null || !(refreshedUser.emailVerified)) {
        return false;
      }

      final expected = expectedEmail?.trim().toLowerCase();
      if (expected == null || expected.isEmpty) {
        return true;
      }

      final currentEmail = refreshedUser.email?.trim().toLowerCase();
      return currentEmail == expected;
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

  AppError _handleFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AppError(
          message: 'Email already registered',
          detail: 'This email is already in use. Please sign in instead.',
        );
      case 'weak-password':
        return AppError(
          message: 'Weak password',
          detail: 'Password must be at least 6 characters.',
        );
      case 'invalid-email':
        return AppError(
          message: 'Invalid email',
          detail: 'Please enter a valid email address.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppError(
          message: 'Invalid credentials',
          detail: 'Invalid email or password.',
        );
      case 'user-disabled':
        return AppError(
          message: 'Account disabled',
          detail: 'Account is deactivated. Contact support.',
        );
      case 'too-many-requests':
        return AppError(
          message: 'Too many attempts',
          detail: 'Too many failed attempts. Please try again later.',
        );
      case 'network-request-failed':
        return AppError(
          message: 'No internet',
          detail: 'Check your internet connection and try again.',
        );
      default:
        return AppError(
          message: e.message ?? 'Authentication failed',
          detail: e.message,
        );
    }
  }
}
