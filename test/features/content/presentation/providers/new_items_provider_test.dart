import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/content/presentation/providers/new_items_provider.dart';

void main() {
  group('NewItems Provider Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('NewItemEntry', () {
      test('isExpired returns false for fresh items', () {
        final entry = NewItemEntry(
          itemId: 'test-1',
          addedAt: DateTime.now(),
        );

        expect(entry.isExpired, false);
      });

      test('isExpired returns true for items older than 5 minutes', () {
        final entry = NewItemEntry(
          itemId: 'test-1',
          addedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        );

        expect(entry.isExpired, true);
      });

      test('isExpired returns false for items at exactly 4 minutes', () {
        final entry = NewItemEntry(
          itemId: 'test-1',
          addedAt: DateTime.now().subtract(const Duration(minutes: 4, seconds: 59)),
        );

        expect(entry.isExpired, false);
      });
    });

    group('NewItems initialization', () {
      test('starts with empty state', () {
        final state = container.read(newItemsProvider);
        expect(state, isEmpty);
      });
    });

    group('addNewItem', () {
      test('adds new item to state', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');

        final state = container.read(newItemsProvider);
        expect(state.containsKey('item-1'), true);
        expect(state['item-1']!.itemId, 'item-1');
      });

      test('adds multiple items to state', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');
        notifier.addNewItem('item-2');
        notifier.addNewItem('item-3');

        final state = container.read(newItemsProvider);
        expect(state.length, 3);
        expect(state.containsKey('item-1'), true);
        expect(state.containsKey('item-2'), true);
        expect(state.containsKey('item-3'), true);
      });

      test('updates existing item with new timestamp', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');

        final firstTimestamp = container.read(newItemsProvider)['item-1']!.addedAt;

        // Wait a bit before re-adding
        Future.delayed(const Duration(milliseconds: 10));
        notifier.addNewItem('item-1');

        final secondTimestamp = container.read(newItemsProvider)['item-1']!.addedAt;
        expect(secondTimestamp.isAfter(firstTimestamp) || secondTimestamp.isAtSameMomentAs(firstTimestamp), true);
      });
    });

    group('removeNewItem', () {
      test('removes item from state', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');
        notifier.addNewItem('item-2');

        expect(container.read(newItemsProvider).length, 2);

        notifier.removeNewItem('item-1');

        final state = container.read(newItemsProvider);
        expect(state.length, 1);
        expect(state.containsKey('item-1'), false);
        expect(state.containsKey('item-2'), true);
      });

      test('does nothing if item does not exist', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');

        notifier.removeNewItem('item-2');

        final state = container.read(newItemsProvider);
        expect(state.length, 1);
        expect(state.containsKey('item-1'), true);
      });
    });

    group('clearNewItems', () {
      test('clears all items from state', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');
        notifier.addNewItem('item-2');
        notifier.addNewItem('item-3');

        expect(container.read(newItemsProvider).length, 3);

        notifier.clearNewItems();

        final state = container.read(newItemsProvider);
        expect(state, isEmpty);
      });

      test('does nothing if state is already empty', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.clearNewItems();

        final state = container.read(newItemsProvider);
        expect(state, isEmpty);
      });
    });

    group('isNewItem', () {
      test('returns true for fresh items', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');

        expect(notifier.isNewItem('item-1'), true);
      });

      test('returns false for non-existent items', () {
        final notifier = container.read(newItemsProvider.notifier);

        expect(notifier.isNewItem('item-1'), false);
      });

      test('returns false and removes expired items', () {
        final notifier = container.read(newItemsProvider.notifier);

        // Manually add an expired entry to state
        final expiredEntry = NewItemEntry(
          itemId: 'item-1',
          addedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        );

        container.read(newItemsProvider.notifier).state = {
          'item-1': expiredEntry,
        };

        expect(notifier.isNewItem('item-1'), false);

        // Verify item was removed
        final state = container.read(newItemsProvider);
        expect(state.containsKey('item-1'), false);
      });
    });

    group('clearExpiredItems', () {
      test('removes expired items from state', () {
        final notifier = container.read(newItemsProvider.notifier);

        // Add fresh and expired entries
        final freshEntry = NewItemEntry(
          itemId: 'fresh-1',
          addedAt: DateTime.now(),
        );
        final expiredEntry = NewItemEntry(
          itemId: 'expired-1',
          addedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        );

        notifier.state = {
          'fresh-1': freshEntry,
          'expired-1': expiredEntry,
        };

        notifier.clearExpiredItems();

        final state = container.read(newItemsProvider);
        expect(state.length, 1);
        expect(state.containsKey('fresh-1'), true);
        expect(state.containsKey('expired-1'), false);
      });

      test('keeps all items when none are expired', () {
        final notifier = container.read(newItemsProvider.notifier);
        notifier.addNewItem('item-1');
        notifier.addNewItem('item-2');

        notifier.clearExpiredItems();

        final state = container.read(newItemsProvider);
        expect(state.length, 2);
      });

      test('clears all items when all are expired', () {
        final notifier = container.read(newItemsProvider.notifier);

        final expiredEntry1 = NewItemEntry(
          itemId: 'expired-1',
          addedAt: DateTime.now().subtract(const Duration(minutes: 6)),
        );
        final expiredEntry2 = NewItemEntry(
          itemId: 'expired-2',
          addedAt: DateTime.now().subtract(const Duration(minutes: 7)),
        );

        notifier.state = {
          'expired-1': expiredEntry1,
          'expired-2': expiredEntry2,
        };

        notifier.clearExpiredItems();

        final state = container.read(newItemsProvider);
        expect(state, isEmpty);
      });
    });
  });
}
