import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/network/network_info.dart';

void main() {
  group('NetworkInfoImpl', () {
    late NetworkInfoImpl networkInfo;

    setUp(() {
      networkInfo = NetworkInfoImpl();
    });

    test('isConnected returns true (web assumption)', () async {
      // Act
      final result = await networkInfo.isConnected;

      // Assert
      expect(result, true);
    });

    test('isConnected is consistent', () async {
      // Act
      final result1 = await networkInfo.isConnected;
      final result2 = await networkInfo.isConnected;

      // Assert
      expect(result1, result2);
    });
  });

  group('NetworkInfo abstract class', () {
    test('can be implemented with custom logic', () async {
      // Arrange
      final customNetworkInfo = _CustomNetworkInfo(isConnected: false);

      // Act
      final result = await customNetworkInfo.isConnected;

      // Assert
      expect(result, false);
    });
  });
}

// Custom implementation for testing the abstract class
class _CustomNetworkInfo implements NetworkInfo {
  final bool _isConnected;

  _CustomNetworkInfo({required bool isConnected}) : _isConnected = isConnected;

  @override
  Future<bool> get isConnected async => _isConnected;
}
