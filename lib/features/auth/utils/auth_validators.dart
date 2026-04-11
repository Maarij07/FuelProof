class AuthValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
  static final RegExp _phonePattern = RegExp(r'^\+?[1-9]\d{7,14}$');

  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecial = RegExp(r'[^A-Za-z0-9]');

  static String? validateEmail(String? value) {
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Email is required.';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? validateFullName(String? value) {
    final fullName = (value ?? '').trim();

    if (fullName.isEmpty) {
      return 'Full name is required.';
    }

    if (fullName.length < 2) {
      return 'Enter your full name.';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    final phone = (value ?? '').trim();

    if (phone.isEmpty) {
      return null;
    }

    if (!_phonePattern.hasMatch(phone)) {
      return 'Enter a valid phone number in international format.';
    }

    return null;
  }

  static String? validatePasswordForSignIn(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    return null;
  }

  static String? validatePasswordForCreateAccount(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }

    if (!_hasUppercase.hasMatch(password)) {
      return 'Include at least one uppercase letter.';
    }

    if (!_hasLowercase.hasMatch(password)) {
      return 'Include at least one lowercase letter.';
    }

    if (!_hasDigit.hasMatch(password)) {
      return 'Include at least one number.';
    }

    if (!_hasSpecial.hasMatch(password)) {
      return 'Include at least one special character.';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String? confirmPassword,
    String password,
  ) {
    final confirm = confirmPassword ?? '';

    if (confirm.isEmpty) {
      return 'Please confirm your password.';
    }

    if (confirm != password) {
      return 'Passwords do not match.';
    }

    return null;
  }
}
