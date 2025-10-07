import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../storage/secure_storage_factory.dart';

class OrganizationInterceptor extends Interceptor {
  static const String _storageKey = 'current_organization_id';
  final SecureStorage _storage = SecureStorageFactory.create();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add organization context to headers if available
    try {
      final organizationId = await _storage.read(_storageKey);
      if (organizationId != null && organizationId.isNotEmpty) {
        options.headers['X-Organization-ID'] = organizationId;
      }
    } catch (e) {
      // If we can't read from storage, continue without organization header
    }

    handler.next(options);
  }
}