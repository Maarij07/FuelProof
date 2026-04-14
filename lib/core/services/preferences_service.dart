import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class PreferencesService {
  static const String _boxName = 'fuelguard_preferences';
  static const String _darkModeKey = 'dark_mode_enabled';

  static late Box<dynamic> _box;
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      _box = await Hive.openBox(_boxName);
      _initialized = true;
    }
  }

  static Future<void> _ensureInitialized() async {
    if (!_initialized) {
      try {
        await init();
      } catch (_) {
        // If initialization fails (e.g., in tests), continue with defaults
      }
    }
  }

  // Dark Mode
  static bool isDarkModeEnabled() {
    if (!_initialized) {
      return false; // Default fallback
    }
    try {
      return _box.get(_darkModeKey, defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setDarkMode(bool enabled) async {
    await _ensureInitialized();
    if (_initialized) {
      try {
        await _box.put(_darkModeKey, enabled);
      } catch (_) {
        // Silently fail if storage isn't available
      }
    }
  }

  static ThemeMode getThemeMode() {
    return isDarkModeEnabled() ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    await setDarkMode(mode == ThemeMode.dark);
  }

  static Future<void> clear() async {
    if (_initialized) {
      await _box.clear();
    }
  }
}
