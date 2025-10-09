import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage.dart';

/// Factory function for platform-specific imports
SecureStorage createSecureStorage() => SecureStorageMobile();

/// Mobile/Desktop implementation of SecureStorage
/// Uses SharedPreferences as fallback since flutter_secure_storage is removed
/// Note: This is not encrypted. For production, consider platform-specific secure storage
class SecureStorageMobile implements SecureStorage {
  static const String _prefix = 'secure_';

  @override
  Future<String?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_prefix$key');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', value);
    } catch (e) {
      // Silently fail if storage is not available
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (e) {
      // Silently fail if storage is not available
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefix)).toList();

      // Remove all matching keys in parallel
      await Future.wait(keys.map((key) => prefs.remove(key)));

      // Force reload to ensure changes are persisted
      await prefs.reload();
    } catch (e) {
      // Silently fail if storage is not available
    }
  }
}
