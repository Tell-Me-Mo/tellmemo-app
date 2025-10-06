import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/models/api_response.dart';

void main() {
  group('ApiResponse', () {
    group('fromJson', () {
      test('creates valid ApiResponse from complete JSON', () {
        // Arrange
        final json = {
          'status': 'success',
          'message': 'Operation completed successfully',
          'data': {
            'id': '123',
            'name': 'Test Item',
            'count': 42,
          },
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, 'success');
        expect(response.message, 'Operation completed successfully');
        expect(response.data, isNotNull);
        expect(response.data!['id'], '123');
        expect(response.data!['name'], 'Test Item');
        expect(response.data!['count'], 42);
      });

      test('creates ApiResponse with minimal required fields', () {
        // Arrange
        final json = {
          'status': 'success',
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, 'success');
        expect(response.message, isNull);
        expect(response.data, isNull);
      });

      test('creates ApiResponse with error status', () {
        // Arrange
        final json = {
          'status': 'error',
          'message': 'Something went wrong',
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, 'error');
        expect(response.message, 'Something went wrong');
        expect(response.data, isNull);
      });

      test('creates ApiResponse with empty data object', () {
        // Arrange
        final json = {
          'status': 'success',
          'data': <String, dynamic>{},
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, 'success');
        expect(response.data, isNotNull);
        expect(response.data, isEmpty);
      });

      test('creates ApiResponse with nested data structure', () {
        // Arrange
        final json = {
          'status': 'success',
          'data': {
            'user': {
              'id': '123',
              'name': 'Test User',
              'roles': ['admin', 'user'],
            },
            'permissions': ['read', 'write'],
          },
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, 'success');
        expect(response.data!['user']['id'], '123');
        expect(response.data!['user']['roles'], ['admin', 'user']);
        expect(response.data!['permissions'], ['read', 'write']);
      });

      test('creates ApiResponse with list data', () {
        // Arrange
        final json = {
          'status': 'success',
          'data': {
            'items': [
              {'id': '1', 'name': 'Item 1'},
              {'id': '2', 'name': 'Item 2'},
            ],
          },
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, 'success');
        expect(response.data!['items'], isA<List>());
        expect(response.data!['items'].length, 2);
      });
    });

    group('toJson', () {
      test('serializes complete ApiResponse to JSON', () {
        // Arrange
        final response = ApiResponse(
          status: 'success',
          message: 'Operation completed',
          data: {
            'id': '123',
            'name': 'Test Item',
          },
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['status'], 'success');
        expect(json['message'], 'Operation completed');
        expect(json['data'], isNotNull);
        expect(json['data']['id'], '123');
        expect(json['data']['name'], 'Test Item');
      });

      test('serializes ApiResponse with null fields', () {
        // Arrange
        final response = ApiResponse(
          status: 'success',
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['status'], 'success');
        expect(json['message'], isNull);
        expect(json['data'], isNull);
      });

      test('serializes ApiResponse with empty data', () {
        // Arrange
        final response = ApiResponse(
          status: 'success',
          data: {},
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['status'], 'success');
        expect(json['data'], isEmpty);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'status': 'success',
          'message': 'Operation completed',
          'data': {
            'id': '123',
            'name': 'Test Item',
            'nested': {
              'key': 'value',
            },
          },
        };

        // Act
        final response = ApiResponse.fromJson(originalJson);
        final finalJson = response.toJson();

        // Assert
        expect(finalJson['status'], originalJson['status']);
        expect(finalJson['message'], originalJson['message']);
        final originalData = originalJson['data'] as Map<String, dynamic>;
        expect(finalJson['data']['id'], originalData['id']);
        expect(finalJson['data']['name'], originalData['name']);
        expect(finalJson['data']['nested'], originalData['nested']);
      });
    });

    group('edge cases', () {
      test('handles very long status string', () {
        // Arrange
        final longStatus = 'status_' * 100;
        final json = {
          'status': longStatus,
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, longStatus);
      });

      test('handles very long message', () {
        // Arrange
        final longMessage = 'A' * 10000;
        final json = {
          'status': 'error',
          'message': longMessage,
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.message, longMessage);
      });

      test('handles special characters in message', () {
        // Arrange
        final json = {
          'status': 'error',
          'message': 'Error: <invalid> "input" & special chars 🔥',
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.message, 'Error: <invalid> "input" & special chars 🔥');
      });

      test('handles empty strings', () {
        // Arrange
        final json = {
          'status': '',
          'message': '',
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.status, '');
        expect(response.message, '');
      });

      test('handles deeply nested data', () {
        // Arrange
        final json = {
          'status': 'success',
          'data': {
            'level1': {
              'level2': {
                'level3': {
                  'level4': {
                    'value': 'deep',
                  },
                },
              },
            },
          },
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(
          response.data!['level1']['level2']['level3']['level4']['value'],
          'deep',
        );
      });

      test('handles various data types in data map', () {
        // Arrange
        final json = {
          'status': 'success',
          'data': {
            'string': 'text',
            'number': 42,
            'double': 3.14,
            'bool': true,
            'null': null,
            'list': [1, 2, 3],
            'map': {'key': 'value'},
          },
        };

        // Act
        final response = ApiResponse.fromJson(json);

        // Assert
        expect(response.data!['string'], 'text');
        expect(response.data!['number'], 42);
        expect(response.data!['double'], 3.14);
        expect(response.data!['bool'], true);
        expect(response.data!['null'], isNull);
        expect(response.data!['list'], [1, 2, 3]);
        expect(response.data!['map'], {'key': 'value'});
      });
    });
  });

  group('HealthCheckResponse', () {
    group('fromJson', () {
      test('creates valid HealthCheckResponse from complete JSON', () {
        // Arrange
        final json = {
          'status': 'healthy',
          'services': {
            'database': {'status': 'up', 'response_time_ms': 5},
            'redis': {'status': 'up', 'response_time_ms': 2},
            'elasticsearch': {'status': 'up', 'response_time_ms': 10},
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.status, 'healthy');
        expect(response.services, isNotNull);
        expect(response.services['database']['status'], 'up');
        expect(response.services['database']['response_time_ms'], 5);
        expect(response.services['redis']['status'], 'up');
        expect(response.services['elasticsearch']['status'], 'up');
      });

      test('creates HealthCheckResponse with unhealthy status', () {
        // Arrange
        final json = {
          'status': 'unhealthy',
          'services': {
            'database': {'status': 'down', 'error': 'Connection refused'},
            'redis': {'status': 'up'},
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.status, 'unhealthy');
        expect(response.services['database']['status'], 'down');
        expect(response.services['database']['error'], 'Connection refused');
      });

      test('creates HealthCheckResponse with empty services', () {
        // Arrange
        final json = {
          'status': 'healthy',
          'services': <String, dynamic>{},
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.status, 'healthy');
        expect(response.services, isEmpty);
      });

      test('creates HealthCheckResponse with additional metadata', () {
        // Arrange
        final json = {
          'status': 'healthy',
          'services': {
            'api': {
              'status': 'up',
              'version': '1.0.0',
              'uptime': 3600,
              'checks': ['disk', 'memory', 'cpu'],
            },
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.services['api']['status'], 'up');
        expect(response.services['api']['version'], '1.0.0');
        expect(response.services['api']['uptime'], 3600);
        expect(response.services['api']['checks'], ['disk', 'memory', 'cpu']);
      });
    });

    group('toJson', () {
      test('serializes complete HealthCheckResponse to JSON', () {
        // Arrange
        final response = HealthCheckResponse(
          status: 'healthy',
          services: {
            'database': {'status': 'up', 'response_time_ms': 5},
            'redis': {'status': 'up', 'response_time_ms': 2},
          },
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['status'], 'healthy');
        expect(json['services']['database']['status'], 'up');
        expect(json['services']['database']['response_time_ms'], 5);
        expect(json['services']['redis']['status'], 'up');
      });

      test('serializes HealthCheckResponse with empty services', () {
        // Arrange
        final response = HealthCheckResponse(
          status: 'healthy',
          services: {},
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['status'], 'healthy');
        expect(json['services'], isEmpty);
      });
    });

    group('round-trip conversion', () {
      test('JSON -> Model -> JSON preserves data', () {
        // Arrange
        final originalJson = {
          'status': 'healthy',
          'services': {
            'database': {
              'status': 'up',
              'response_time_ms': 5,
              'version': '14.0',
            },
            'redis': {
              'status': 'up',
              'response_time_ms': 2,
            },
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(originalJson);
        final finalJson = response.toJson();

        // Assert
        expect(finalJson['status'], originalJson['status']);
        final originalServices = originalJson['services'] as Map<String, dynamic>;
        final originalDatabase = originalServices['database'] as Map<String, dynamic>;
        expect(
          finalJson['services']['database']['status'],
          originalDatabase['status'],
        );
        expect(
          finalJson['services']['database']['response_time_ms'],
          originalDatabase['response_time_ms'],
        );
        expect(
          finalJson['services']['database']['version'],
          originalDatabase['version'],
        );
        expect(
          finalJson['services']['redis'],
          originalServices['redis'],
        );
      });
    });

    group('edge cases', () {
      test('handles many services', () {
        // Arrange
        final services = <String, dynamic>{};
        for (var i = 0; i < 50; i++) {
          services['service_$i'] = {
            'status': i % 2 == 0 ? 'up' : 'down',
            'response_time_ms': i * 10,
          };
        }

        final json = {
          'status': 'degraded',
          'services': services,
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.services.length, 50);
        expect(response.services['service_0']['status'], 'up');
        expect(response.services['service_1']['status'], 'down');
      });

      test('handles special characters in service names', () {
        // Arrange
        final json = {
          'status': 'healthy',
          'services': {
            'service-with-dashes': {'status': 'up'},
            'service_with_underscores': {'status': 'up'},
            'service.with.dots': {'status': 'up'},
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.services['service-with-dashes']['status'], 'up');
        expect(response.services['service_with_underscores']['status'], 'up');
        expect(response.services['service.with.dots']['status'], 'up');
      });

      test('handles nested service information', () {
        // Arrange
        final json = {
          'status': 'healthy',
          'services': {
            'complex_service': {
              'status': 'up',
              'details': {
                'connections': {
                  'active': 10,
                  'idle': 5,
                  'max': 100,
                },
                'metrics': {
                  'cpu': 45.5,
                  'memory': 78.2,
                },
              },
            },
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        expect(response.services['complex_service']['status'], 'up');
        expect(
          response.services['complex_service']['details']['connections']['active'],
          10,
        );
        expect(
          response.services['complex_service']['details']['metrics']['cpu'],
          45.5,
        );
      });

      test('handles various data types in service info', () {
        // Arrange
        final json = {
          'status': 'healthy',
          'services': {
            'service': {
              'string': 'text',
              'number': 42,
              'double': 3.14,
              'bool': true,
              'null': null,
              'list': [1, 2, 3],
              'map': {'key': 'value'},
            },
          },
        };

        // Act
        final response = HealthCheckResponse.fromJson(json);

        // Assert
        final service = response.services['service'];
        expect(service['string'], 'text');
        expect(service['number'], 42);
        expect(service['double'], 3.14);
        expect(service['bool'], true);
        expect(service['null'], isNull);
        expect(service['list'], [1, 2, 3]);
        expect(service['map'], {'key': 'value'});
      });
    });
  });
}
