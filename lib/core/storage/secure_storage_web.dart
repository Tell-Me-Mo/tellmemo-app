import 'dart:async';
import 'package:web/web.dart' as web;
import 'secure_storage.dart';

/// Factory function for platform-specific imports
SecureStorage createSecureStorage() => SecureStorageWeb();

/// Web implementation of SecureStorage
/// Uses browser's localStorage (not encrypted, but standard for web)
/// Note: For truly sensitive data on web, consider server-side storage
class SecureStorageWeb implements SecureStorage {
  static const String _prefix = 'secure_';

  @override
  Future<String?> read(String key) async {
    try {
      return web.window.localStorage.getItem('$_prefix$key');
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      web.window.localStorage.setItem('$_prefix$key', value);
    } catch (e) {
      // Silently fail if storage is not available
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      web.window.localStorage.removeItem('$_prefix$key');
    } catch (e) {
      // Silently fail if storage is not available
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      final storage = web.window.localStorage;
      final keysToRemove = <String>[];

      // Collect keys that match our prefix
      for (var i = 0; i < storage.length; i++) {
        final key = storage.key(i);
        if (key != null && key.startsWith(_prefix)) {
          keysToRemove.add(key);
        }
      }

      // Remove collected keys
      for (final key in keysToRemove) {
        storage.removeItem(key);
      }
    } catch (e) {
      // Silently fail if storage is not available
    }
  }
}
