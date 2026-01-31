import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// v4.0: Theme provider for managing app theme state
/// Uses ChangeNotifier for reactive updates across the app
class ThemeProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;

  /// Check if current theme is dark
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    final savedTheme = await _settingsService.getThemeMode();
    _themeMode = savedTheme;
    _isInitialized = true;
    notifyListeners();
  }

  /// Set theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _settingsService.setThemeMode(mode);
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Get display name for current theme mode
  String getThemeModeName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Acik';
      case ThemeMode.dark:
        return 'Koyu';
      case ThemeMode.system:
        return 'Sistem';
    }
  }

  /// Get icon for current theme mode
  IconData getThemeModeIcon() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
