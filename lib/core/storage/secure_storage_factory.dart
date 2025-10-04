import 'secure_storage.dart';
import 'secure_storage_mobile.dart'
    if (dart.library.js_interop) 'secure_storage_web.dart'
    as platform_storage;

/// Factory for creating platform-specific SecureStorage implementations
class SecureStorageFactory {
  static SecureStorage create() {
    return platform_storage.createSecureStorage();
  }
}
