import 'package:flutter/material.dart';

class AppColors {
  static bool _isDarkMode = false;

  static void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  // ========== NEUTRALS (Pinterest Aesthetic) ==========
  // Clean, minimal white foundations with subtle grays
  static Color get white =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFFFFFFF);
  static Color get offWhite =>
      _isDarkMode ? const Color(0xFF182334) : const Color(0xFFFAFAFA);
  static Color get lightGray =>
      _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF5F5F5);
  static Color get mediumGray =>
      _isDarkMode ? const Color(0xFF243244) : const Color(0xFFEEEEEE);
  static Color get softGray =>
      _isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE0E0E0);
  static Color get divider =>
      _isDarkMode ? const Color(0xFF2A364A) : const Color(0xFFD9D9D9);

  // ========== TEXT ==========
  static Color get primaryText =>
      _isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF111111);
  static Color get secondaryText =>
      _isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF767676);
  static Color get tertiaryText =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFFA0A0A0);

  // ========== BACKGROUND ==========
  static Color get primaryBackground =>
      _isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFFFFBF8);
  static Color get secondaryBackground =>
      _isDarkMode ? const Color(0xFF111827) : const Color(0xFFF9F9F9);

  // ========== BRAND (Subtle Accents) ==========
  // Teal as primary accent - used sparingly
  static const Color accentTeal = Color(0xFF0CA7A0);
  static Color get tealLight =>
      _isDarkMode ? const Color(0xFF123D3A) : const Color(0xFFC8F0EC);

  // Navy as secondary accent
  static const Color brandNavy = Color(0xFF1E3154);
  static Color get navyLight =>
      _isDarkMode ? const Color(0xFF1A2536) : const Color(0xFFE8EEF5);

  // ========== SEMANTIC COLORS ==========
  static const Color success = Color(0xFF10B981);
  static Color get successLight =>
      _isDarkMode ? const Color(0xFF103228) : const Color(0xFFD1FAE5);
  static const Color alert = Color(0xFFEF4444);
  static Color get alertLight =>
      _isDarkMode ? const Color(0xFF3A1A1A) : const Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static Color get warningLight =>
      _isDarkMode ? const Color(0xFF3A2F13) : const Color(0xFFFEF3C7);

  // ========== OPACITY VARIANTS ==========
  // Use these with .withOpacity() for dynamic opacity
  // Example: accentTeal.withOpacity(0.08)
  static const Color accentTealOpacity = accentTeal;
  static const Color brandNavyOpacity = brandNavy;
}
