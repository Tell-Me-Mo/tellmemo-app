import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/hierarchy/presentation/providers/favorites_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FavoriteItem', () {
    group('fromJson', () {
      test('creates valid FavoriteItem from JSON', () {
        // Arrange
        final json = {
          'id': 'item-123',
          'type': 'portfolio',
          'markedAt': '2024-01-15T10:30:00.000Z',
        };

        // Act
        final item = FavoriteItem.fromJson(json);

        // Assert
        expect(item.id, 'item-123');
        expect(item.type, 'portfolio');
        expect(item.markedAt, isA<DateTime>());
      });

      test('creates FavoriteItem for all types', () {
        final types = ['portfolio', 'program', 'project'];

        for (final type in types) {
          final json = {
            'id': 'item-123',
            'type': type,
            'markedAt': '2024-01-15T10:30:00.000Z',
          };

          final item = FavoriteItem.fromJson(json);
          expect(item.type, type);
        }
      });

      test('parses ISO 8601 timestamp correctly', () {
        final json = {
          'id': 'item-123',
          'type': 'portfolio',
          'markedAt': '2024-01-15T10:30:45.123Z',
        };

        final item = FavoriteItem.fromJson(json);

        expect(item.markedAt.year, 2024);
        expect(item.markedAt.month, 1);
        expect(item.markedAt.day, 15);
        expect(item.markedAt.hour, 10);
        expect(item.markedAt.minute, 30);
        expect(item.markedAt.second, 45);
      });
    });

    group('toJson', () {
      test('serializes FavoriteItem to JSON', () {
        // Arrange
        final item = FavoriteItem(
          id: 'item-123',
          type: 'portfolio',
          markedAt: DateTime(2024, 1, 15, 10, 30, 45),
        );

        // Act
        final json = item.toJson();

        // Assert
        expect(json['id'], 'item-123');
        expect(json['type'], 'portfolio');
        expect(json['markedAt'], isA<String>());
        expect(json['markedAt'], contains('2024-01-15'));
      });

      test('formats DateTime to ISO 8601 string', () {
        final item = FavoriteItem(
          id: 'item-123',
          type: 'portfolio',
          markedAt: DateTime(2024, 1, 15, 10, 30, 45),
        );

        final json = item.toJson();

        // ISO 8601 format
        expect(json['markedAt'], matches(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'));
      });
    });

    group('Round-trip conversion', () {
      test('preserves data through toJson → fromJson', () {
        // Arrange
        final original = FavoriteItem(
          id: 'item-123',
          type: 'portfolio',
          markedAt: DateTime(2024, 1, 15, 10, 30, 0),
        );

        // Act
        final json = original.toJson();
        final restored = FavoriteItem.fromJson(json);

        // Assert
        expect(restored.id, original.id);
        expect(restored.type, original.type);
        expect(restored.markedAt.year, original.markedAt.year);
        expect(restored.markedAt.month, original.markedAt.month);
        expect(restored.markedAt.day, original.markedAt.day);
      });
    });
  });

  group('FavoritesNotifier', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('toggleFavorite', () {
      test('adds item to favorites when not present', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        // Act
        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');

        // Assert
        final state = container.read(favoritesProvider);
        expect(state, contains('item-1'));

        container.dispose();
      });
    });

    group('isFavorite', () {
      test('returns true for favorited item', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');

        final isFavorite = container.read(favoritesProvider.notifier).isFavorite('item-1');
        expect(isFavorite, isTrue);

        container.dispose();
      });

      test('returns false for non-favorited item', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        final isFavorite = container.read(favoritesProvider.notifier).isFavorite('item-2');
        expect(isFavorite, isFalse);

        container.dispose();
      });
    });

    group('clearFavorites', () {
      test('removes all favorites', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        // Add some favorites
        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');
        await container.read(favoritesProvider.notifier).toggleFavorite('item-2');

        // Act
        await container.read(favoritesProvider.notifier).clearFavorites();

        // Assert
        final state = container.read(favoritesProvider);
        expect(state, isEmpty);

        container.dispose();
      });
    });

    group('getFavorites', () {
      test('returns empty set when no favorites', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        final favorites = container.read(favoritesProvider.notifier).getFavorites();
        expect(favorites, isEmpty);

        container.dispose();
      });
    });

    group('isFavoriteProvider', () {
      test('updates when favorites change', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        // Initially not favorited
        expect(container.read(isFavoriteProvider('item-1')), isFalse);

        // Add to favorites
        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');

        // Should now be favorited
        expect(container.read(isFavoriteProvider('item-1')), isTrue);

        container.dispose();
      });
    });

    group('Edge cases', () {
      test('handles multiple toggles of same item', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        // Add, remove, add again
        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');
        expect(container.read(favoritesProvider), contains('item-1'));

        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');
        expect(container.read(favoritesProvider), isNot(contains('item-1')));

        await container.read(favoritesProvider.notifier).toggleFavorite('item-1');
        expect(container.read(favoritesProvider), contains('item-1'));

        container.dispose();
      });

      test('handles empty string IDs', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        await container.read(favoritesProvider.notifier).toggleFavorite('');
        expect(container.read(favoritesProvider), contains(''));

        container.dispose();
      });

      test('handles very long IDs', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        final longId = 'A' * 1000;
        await container.read(favoritesProvider.notifier).toggleFavorite(longId);
        expect(container.read(favoritesProvider), contains(longId));

        container.dispose();
      });

      test('handles special characters in IDs', () async {
        final container = ProviderContainer();

        await Future.delayed(const Duration(milliseconds: 200));

        final specialId = 'item-<>&"\'';
        await container.read(favoritesProvider.notifier).toggleFavorite(specialId);
        expect(container.read(favoritesProvider), contains(specialId));

        container.dispose();
      });
    });
  });
}
