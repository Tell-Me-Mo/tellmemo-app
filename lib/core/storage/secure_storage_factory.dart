import 'secure_storage.dart';
import 'secure_storage_mobile.dart'
    if (dart.library.js_interop) 'secure_storage_web.dart'
    as platform_storage;

/// Factory for creating platform-specific SecureStorage implementations
class SecureStorageFactory {
  static SecureStorage? _testInstance;

  static SecureStorage create() {
    if (_testInstance != null) {
      return _testInstance!;
    }
    return platform_storage.createSecureStorage();
  }

  /// Override storage instance for testing
  static void overrideForTesting(SecureStorage storage) {
    _testInstance = storage;
  }

  /// Reset to production implementation
  static void reset() {
    _testInstance = null;
  }
}
