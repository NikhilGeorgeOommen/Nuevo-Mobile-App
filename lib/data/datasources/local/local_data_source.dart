import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';

/// Local Data Source
/// Handles secure storage for tokens and preferences
/// HIPAA/GDPR Compliant: Sensitive data in Secure Storage, preferences in SharedPreferences
class LocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;
  String? _cachedAccessToken;
  
  LocalDataSource({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences preferences,
  })  : _secureStorage = secureStorage,
        _preferences = preferences;
  
  // ============================================
  // Secure Storage (Sensitive Data)
  // ============================================
  
  /// Save access token (SECURE)
  Future<void> saveAccessToken(String token) async {
    _cachedAccessToken = token;
    try {
      await _secureStorage.write(
        key: StorageKeys.accessToken,
        value: token,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save access token',
        code: null,
      );
    }
  }
  
  /// Get access token (SECURE)
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) {
      return _cachedAccessToken;
    }
    try {
      final token = await _secureStorage.read(key: StorageKeys.accessToken);
      _cachedAccessToken = token;
      return token;
    } catch (e) {
      throw CacheException(
        message: 'Failed to retrieve access token',
        code: null,
      );
    }
  }
  
  /// Save refresh token (SECURE)
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(
        key: StorageKeys.refreshToken,
        value: token,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save refresh token',
        code: null,
      );
    }
  }
  
  /// Get refresh token (SECURE)
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: StorageKeys.refreshToken);
    } catch (e) {
      throw CacheException(
        message: 'Failed to retrieve refresh token',
        code: null,
      );
    }
  }
  
  /// Save user ID (SECURE)
  Future<void> saveUserId(String userId) async {
    try {
      await _secureStorage.write(
        key: StorageKeys.userId,
        value: userId,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save user ID',
        code: null,
      );
    }
  }
  
  /// Get user ID (SECURE)
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: StorageKeys.userId);
    } catch (e) {
      throw CacheException(
        message: 'Failed to retrieve user ID',
        code: null,
      );
    }
  }
  
  /// Clear all secure data (on logout)
  Future<void> clearSecureData() async {
    _cachedAccessToken = null;
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear secure data',
        code: null,
      );
    }
  }
  
  // ============================================
  // Shared Preferences (Non-Sensitive Data)
  // ============================================
  
  /// Check if first launch
  bool isFirstLaunch() {
    return _preferences.getBool(StorageKeys.isFirstLaunch) ?? true;
  }
  
  /// Set first launch flag
  Future<void> setFirstLaunchComplete() async {
    try {
      await _preferences.setBool(StorageKeys.isFirstLaunch, false);
    } catch (e) {
      throw CacheException(
        message: 'Failed to update first launch flag',
        code: null,
      );
    }
  }
  
  /// Get theme mode
  String? getThemeMode() {
    return _preferences.getString(StorageKeys.themeMode);
  }
  
  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    try {
      await _preferences.setString(StorageKeys.themeMode, mode);
    } catch (e) {
      throw CacheException(
        message: 'Failed to save theme mode',
        code: null,
      );
    }
  }
  
  /// Get language
  String? getLanguage() {
    return _preferences.getString(StorageKeys.language);
  }
  
  /// Set language
  Future<void> setLanguage(String language) async {
    try {
      await _preferences.setString(StorageKeys.language, language);
    } catch (e) {
      throw CacheException(
        message: 'Failed to save language',
        code: null,
      );
    }
  }
  
  /// Get last sync time
  DateTime? getLastSyncTime() {
    final timestamp = _preferences.getString(StorageKeys.lastSyncTime);
    return timestamp != null ? DateTime.tryParse(timestamp) : null;
  }
  
  /// Set last sync time
  Future<void> setLastSyncTime(DateTime time) async {
    try {
      await _preferences.setString(
        StorageKeys.lastSyncTime,
        time.toIso8601String(),
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to save last sync time',
        code: null,
      );
    }
  }
  
  /// Clear all preferences (keep secure data)
  Future<void> clearPreferences() async {
    try {
      await _preferences.clear();
    } catch (e) {
      throw CacheException(
        message: 'Failed to clear preferences',
        code: null,
      );
    }
  }
  
  /// Handle first launch logic
  /// Check if it's the first time the app is running (or after reinstall)
  /// If so, clear secure storage to prevent stale tokens from persisting (iOS Keychain issue)
  Future<void> handleFirstLaunch() async {
    if (isFirstLaunch()) {
      // DISABLED FOR DEVELOPMENT: This aggressive cache clearing prevents stale iOS tokens 
      // on fresh production installs, but causes 'flutter run' to aggressively log developers out.
      // await clearSecureData();
      await setFirstLaunchComplete();
    }
  }

  /// Check if user is logged in (has access token)
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
