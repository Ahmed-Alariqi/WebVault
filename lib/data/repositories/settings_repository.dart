import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants.dart';

class SettingsRepository {
  Box get _box => Hive.box(kSettingsBox);

  // PIN
  String? getPin() => _box.get(kPinCode) as String?;
  Future<void> setPin(String pin) => _box.put(kPinCode, pin);
  Future<void> removePin() => _box.delete(kPinCode);

  bool isPinEnabled() => _box.get(kPinEnabled, defaultValue: false) as bool;
  Future<void> setPinEnabled(bool enabled) => _box.put(kPinEnabled, enabled);

  // Biometrics
  bool isBiometricEnabled() =>
      _box.get(kBiometricEnabled, defaultValue: false) as bool;
  Future<void> setBiometricEnabled(bool enabled) =>
      _box.put(kBiometricEnabled, enabled);

  // Auto-lock timeout (in seconds, 0 = immediate)
  int getAutoLockTimeout() =>
      _box.get(kAutoLockTimeout, defaultValue: 0) as int;
  Future<void> setAutoLockTimeout(int seconds) =>
      _box.put(kAutoLockTimeout, seconds);

  // Theme
  String getThemeMode() =>
      _box.get(kThemeMode, defaultValue: 'system') as String;
  Future<void> setThemeMode(String mode) => _box.put(kThemeMode, mode);

  // Auto-delete days for clipboard (-1 = never)
  int getAutoDeleteDays() => _box.get(kAutoDeleteDays, defaultValue: -1) as int;
  Future<void> setAutoDeleteDays(int days) => _box.put(kAutoDeleteDays, days);

  // Advanced Smart Copy
  bool isAdvancedCopyEnabled() =>
      _box.get(kAdvancedCopyEnabled, defaultValue: false) as bool;
  Future<void> setAdvancedCopyEnabled(bool enabled) =>
      _box.put(kAdvancedCopyEnabled, enabled);

  // First launch
  bool isFirstLaunch() => _box.get(kIsFirstLaunch, defaultValue: true) as bool;
  Future<void> setFirstLaunch(bool value) => _box.put(kIsFirstLaunch, value);

  // Onboarding
  bool isOnboardingCompleted() =>
      _box.get(kOnboardingCompleted, defaultValue: false) as bool;
  Future<void> setOnboardingCompleted(bool value) =>
      _box.put(kOnboardingCompleted, value);

  // Welcome Screen
  bool hasSeenWelcomeScreen() =>
      _box.get(kHasSeenWelcomeScreen, defaultValue: false) as bool;
  Future<void> setHasSeenWelcomeScreen(bool value) =>
      _box.put(kHasSeenWelcomeScreen, value);

  // Tutorial
  bool hasSeenTutorial() =>
      _box.get(kHasSeenTutorial, defaultValue: false) as bool;
  Future<void> setHasSeenTutorial(bool value) =>
      _box.put(kHasSeenTutorial, value);

  bool hasSeenClipboardTutorial() =>
      _box.get('has_seen_clipboard_tutorial', defaultValue: false) as bool;
  Future<void> setHasSeenClipboardTutorial(bool value) =>
      _box.put('has_seen_clipboard_tutorial', value);

  bool hasSeenPagesTutorial() =>
      _box.get('has_seen_pages_tutorial', defaultValue: false) as bool;
  Future<void> setHasSeenPagesTutorial(bool value) =>
      _box.put('has_seen_pages_tutorial', value);

  bool hasSeenBrowserTutorial() =>
      _box.get('has_seen_browser_tutorial', defaultValue: false) as bool;
  Future<void> setHasSeenBrowserTutorial(bool value) =>
      _box.put('has_seen_browser_tutorial', value);

  // Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'pinEnabled': isPinEnabled(),
      'biometricEnabled': isBiometricEnabled(),
      'autoLockTimeout': getAutoLockTimeout(),
      'themeMode': getThemeMode(),
      'autoDeleteDays': getAutoDeleteDays(),
      'isAdvancedCopyEnabled': isAdvancedCopyEnabled(),
      'isFirstLaunch': isFirstLaunch(),
      'hasSeenTutorial': hasSeenTutorial(),
      'hasSeenClipboardTutorial': hasSeenClipboardTutorial(),
      'hasSeenPagesTutorial': hasSeenPagesTutorial(),
      'hasSeenBrowserTutorial': hasSeenBrowserTutorial(),
      'locale': getLocale(),
    };
  }

  // Locale
  String getLocale() => _box.get(kLocale, defaultValue: 'ar') as String;
  Future<void> setLocale(String locale) => _box.put(kLocale, locale);
}
