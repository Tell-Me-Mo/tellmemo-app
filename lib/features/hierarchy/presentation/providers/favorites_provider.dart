import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Model for storing favorite items
class FavoriteItem {
  final String id;
  final String type; // 'portfolio', 'program', or 'project'
  final DateTime markedAt;

  FavoriteItem({
    required this.id,
    required this.type,
    required this.markedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'markedAt': markedAt.toIso8601String(),
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    id: json['id'],
    type: json['type'],
    markedAt: DateTime.parse(json['markedAt']),
  );
}

// State notifier for managing favorites
class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _storageKey = 'favorite_items';
  final Ref ref;

  FavoritesNotifier(this.ref) : super({}) {
    _loadFavorites();
  }

  // Load favorites from local storage
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_storageKey);

      print('Loading favorites: $favoritesJson');

      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        // Handle both old format (list of IDs) and new format (list of objects)
        if (decoded.isNotEmpty) {
          if (decoded.first is String) {
            // Old format: just IDs
            state = decoded.cast<String>().toSet();
          } else {
            // New format: FavoriteItem objects
            final favorites = decoded
                .map((item) => FavoriteItem.fromJson(item))
                .map((item) => item.id)
                .toSet();
            state = favorites;
          }
        }
        print('Loaded favorites: $state');
      } else {
        print('No favorites found in storage');
      }
    } catch (e) {
      // If there's an error loading favorites, start with empty set
      print('Error loading favorites: $e');
      state = {};
    }
  }

  // Save favorites to local storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store as a simple list of IDs for simplicity
      final favoritesList = state.toList();
      await prefs.setString(_storageKey, json.encode(favoritesList));
      print('Saved favorites: $favoritesList');
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Toggle favorite status for an item
  Future<void> toggleFavorite(String itemId) async {
    if (state.contains(itemId)) {
      // Remove from favorites
      state = {...state}..remove(itemId);
    } else {
      // Add to favorites
      state = {...state, itemId};
    }

    await _saveFavorites();
  }

  // Check if an item is marked as favorite
  bool isFavorite(String itemId) {
    return state.contains(itemId);
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    state = {};
    await _saveFavorites();
  }

  // Get all favorite IDs
  Set<String> getFavorites() {
    return state;
  }
}

// Provider for the favorites notifier
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref);
});

// Provider to check if a specific item is favorited
final isFavoriteProvider = Provider.family<bool, String>((ref, itemId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.contains(itemId);
});