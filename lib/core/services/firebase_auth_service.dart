import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/error_models.dart';

class FirebaseAuthService {
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (Firebase.apps.isEmpty) {
      throw AppError(
        message:
            'Firebase is not configured yet. Add Firebase project settings before using password reset.',
      );
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<String> signInAndGetIdToken({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw AppError(
        message:
            'Firebase is not configured yet. Add Firebase project settings before using password reset.',
      );
    }

    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw AppError(message: 'Unable to authenticate with Firebase.');
    }

    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw AppError(message: 'Unable to obtain a Firebase ID token.');
    }

    return idToken;
  }

  Future<void> confirmPasswordReset({
    required String oobCode,
    required String newPassword,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw AppError(
        message:
            'Firebase is not configured yet. Add Firebase project settings before using password reset.',
      );
    }

    await FirebaseAuth.instance.confirmPasswordReset(
      code: oobCode,
      newPassword: newPassword,
    );
  }

  Future<String> verifyPasswordResetCode({required String oobCode}) async {
    if (Firebase.apps.isEmpty) {
      throw AppError(
        message:
            'Firebase is not configured yet. Add Firebase project settings before using password reset.',
      );
    }

    return FirebaseAuth.instance.verifyPasswordResetCode(oobCode);
  }
}
