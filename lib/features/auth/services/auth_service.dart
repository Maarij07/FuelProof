class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final Map<String, String> _accounts = {'demo@fuelproof.com': 'Fuel@123'};

  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;

  Future<void> signIn({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();
    final storedPassword = _accounts[normalizedEmail];

    if (storedPassword == null || storedPassword != password) {
      throw AuthException('Invalid email or password.');
    }

    _isSignedIn = true;
  }

  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();

    if (_accounts.containsKey(normalizedEmail)) {
      throw AuthException('An account already exists for this email.');
    }

    _accounts[normalizedEmail] = password;
    _isSignedIn = true;
  }

  Future<void> sendPasswordResetLink({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();

    if (!_accounts.containsKey(normalizedEmail)) {
      throw AuthException('No account found for this email.');
    }
  }

  void signOut() {
    _isSignedIn = false;
  }
}
