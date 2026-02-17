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

  // Screenshot Prevention
  bool isScreenshotPreventionEnabled() =>
      _box.get(kScreenshotPrevention, defaultValue: false) as bool;
  Future<void> setScreenshotPrevention(bool enabled) =>
      _box.put(kScreenshotPrevention, enabled);

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

  // Secure mode (encrypt clipboard values)
  bool isSecureModeEnabled() =>
      _box.get(kSecureModeEnabled, defaultValue: false) as bool;
  Future<void> setSecureModeEnabled(bool enabled) =>
      _box.put(kSecureModeEnabled, enabled);

  // First launch
  bool isFirstLaunch() => _box.get(kIsFirstLaunch, defaultValue: true) as bool;
  Future<void> setFirstLaunch(bool value) => _box.put(kIsFirstLaunch, value);

  // Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'pinEnabled': isPinEnabled(),
      'biometricEnabled': isBiometricEnabled(),
      'screenshotPrevention': isScreenshotPreventionEnabled(),
      'autoLockTimeout': getAutoLockTimeout(),
      'themeMode': getThemeMode(),
      'autoDeleteDays': getAutoDeleteDays(),
      'secureModeEnabled': isSecureModeEnabled(),
      'isFirstLaunch': isFirstLaunch(),
    };
  }
}
