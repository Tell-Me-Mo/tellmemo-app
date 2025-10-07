import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/core/network/organization_interceptor.dart';
import 'package:pm_master_v2/core/storage/secure_storage.dart';
import 'package:pm_master_v2/core/storage/secure_storage_factory.dart';

@GenerateMocks([SecureStorage, RequestInterceptorHandler])
import 'organization_interceptor_test.mocks.dart';

void main() {
  group('OrganizationInterceptor', () {
    late OrganizationInterceptor interceptor;
    late MockSecureStorage mockStorage;
    late MockRequestInterceptorHandler mockHandler;
    late RequestOptions requestOptions;

    setUp(() {
      mockStorage = MockSecureStorage();
      SecureStorageFactory.overrideForTesting(mockStorage);
      interceptor = OrganizationInterceptor();
      mockHandler = MockRequestInterceptorHandler();
      requestOptions = RequestOptions(path: '/test');
    });

    tearDown(() {
      SecureStorageFactory.reset();
    });

    test('adds X-Organization-ID header when organization ID is available', () async {
      // Arrange
      when(mockStorage.read('current_organization_id'))
          .thenAnswer((_) async => 'org-123');

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.microtask(() {}); // Allow async to start

      // Assert - async operation should eventually read storage and add header
      await Future.delayed(Duration(milliseconds: 50));
      expect(requestOptions.headers['X-Organization-ID'], 'org-123');
    });

    test('does not add header when organization ID is null', () async {
      // Arrange
      when(mockStorage.read('current_organization_id'))
          .thenAnswer((_) async => null);

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.microtask(() {});

      // Assert
      await Future.delayed(Duration(milliseconds: 50));
      expect(requestOptions.headers.containsKey('X-Organization-ID'), false);
    });

    test('does not add header when organization ID is empty', () async {
      // Arrange
      when(mockStorage.read('current_organization_id'))
          .thenAnswer((_) async => '');

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.microtask(() {});

      // Assert
      await Future.delayed(Duration(milliseconds: 50));
      expect(requestOptions.headers.containsKey('X-Organization-ID'), false);
    });

    test('handles storage read error gracefully', () async {
      // Arrange
      when(mockStorage.read('current_organization_id'))
          .thenThrow(Exception('Storage error'));

      // Act & Assert - should not throw, continues without header
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.microtask(() {});
      await Future.delayed(Duration(milliseconds: 50));

      expect(requestOptions.headers.containsKey('X-Organization-ID'), false);
    });

    test('preserves existing headers', () async {
      // Arrange
      requestOptions.headers['Authorization'] = 'Bearer token';
      when(mockStorage.read('current_organization_id'))
          .thenAnswer((_) async => 'org-456');

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.microtask(() {});
      await Future.delayed(Duration(milliseconds: 50));

      // Assert
      expect(requestOptions.headers['Authorization'], 'Bearer token');
      expect(requestOptions.headers['X-Organization-ID'], 'org-456');
    });

    test('overwrites existing X-Organization-ID header', () async {
      // Arrange
      requestOptions.headers['X-Organization-ID'] = 'old-org-id';
      when(mockStorage.read('current_organization_id'))
          .thenAnswer((_) async => 'new-org-id');

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.microtask(() {});
      await Future.delayed(Duration(milliseconds: 50));

      // Assert
      expect(requestOptions.headers['X-Organization-ID'], 'new-org-id');
    });
  });
}
