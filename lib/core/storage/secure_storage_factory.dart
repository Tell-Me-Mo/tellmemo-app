import 'secure_storage.dart';
import 'secure_storage_mobile.dart' as mobile;
import 'secure_storage_web.dart' as web;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Factory for creating platform-specific SecureStorage implementations
class SecureStorageFactory {
  static SecureStorage create() {
    if (kIsWeb) {
      return web.SecureStorageWeb();
    } else {
      return mobile.SecureStorageMobile();
    }
  }
}
