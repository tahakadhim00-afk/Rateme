import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_list_item.dart';
import '../models/movie.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

class ListsNotifier extends StateNotifier<Map<ListType, List<UserListItem>>> {
  final Ref _ref;

  ListsNotifier(this._ref)
      : super({
          ListType.favorites: [],
          ListType.watched: [],
          ListType.watchLater: [],
        }) {
    _init();
  }

  void _init() {
    // React to sign-in and sign-out for the lifetime of this notifier.
    // fireImmediately: true also handles the case where the user is already
    // signed in when the provider is first created.
    _ref.listen<bool>(
      isSignedInProvider,
      (previous, next) {
        if (next) {
          loadFromSupabase();
        } else {
          clearAll();
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> loadFromSupabase() async {
    try {
      // Upload any items that were added locally before sign-in
      final localItems = [
        ...state[ListType.watched] ?? [],
        ...state[ListType.watchLater] ?? [],
        ...state[ListType.favorites] ?? [],
      ];
      for (final item in localItems) {
        try {
          await supabaseService.addToList(item);
        } catch (_) {}
      }

      // Load the full merged state from Supabase
      final items = await supabaseService.fetchUserLists();
      final Map<ListType, List<UserListItem>> grouped = {
        ListType.favorites: [],
        ListType.watched: [],
        ListType.watchLater: [],
      };
      for (final item in items) {
        grouped[item.listType]?.add(item);
      }
      state = grouped;
    } catch (_) {}
  }

  void clearAll() {
    state = {
      ListType.favorites: [],
      ListType.watched: [],
      ListType.watchLater: [],
    };
  }

  Future<void> addToList(ListType type, Movie movie,
      {double? userRating, int? runtime, List<int> genreIds = const []}) async {
    if (isInList(type, movie.id)) return;
    final item = UserListItem(
      mediaId: movie.id,
      title: movie.title,
      posterPath: movie.posterPath,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      listType: type,
      mediaType: movie.mediaType,
      addedAt: DateTime.now(),
      userRating: userRating,
      runtime: runtime,
      genreIds: genreIds,
    );
    state = {
      ...state,
      type: [...(state[type] ?? []), item],
    };
    if (supabaseService.isSignedIn) {
      try {
        await supabaseService.addToList(item);
      } catch (e) {
        // ignore: avoid_print
        print('[Lists] addToList failed: $e');
      }
    }
  }

  Future<void> removeFromList(ListType type, int mediaId) async {
    state = {
      ...state,
      type: (state[type] ?? []).where((e) => e.mediaId != mediaId).toList(),
    };
    if (supabaseService.isSignedIn) {
      try {
        await supabaseService.removeFromList(type, mediaId);
      } catch (e) {
        // ignore: avoid_print
        print('[Lists] removeFromList failed: $e');
      }
    }
  }

  Future<void> toggleList(ListType type, Movie movie,
      {int? runtime, List<int> genreIds = const []}) async {
    if (isInList(type, movie.id)) {
      await removeFromList(type, movie.id);
    } else {
      await addToList(type, movie, runtime: runtime, genreIds: genreIds);
    }
  }

  /// Adds to Watched and removes from Watch Later (mutually exclusive).
  Future<void> toggleWatched(Movie movie,
      {int? runtime, List<int> genreIds = const []}) async {
    if (isInList(ListType.watched, movie.id)) {
      await removeFromList(ListType.watched, movie.id);
    } else {
      await removeFromList(ListType.watchLater, movie.id);
      await addToList(ListType.watched, movie,
          runtime: runtime, genreIds: genreIds);
    }
  }

  /// Adds to Watch Later and removes from Watched (mutually exclusive).
  Future<void> toggleWatchLater(Movie movie) async {
    if (isInList(ListType.watchLater, movie.id)) {
      await removeFromList(ListType.watchLater, movie.id);
    } else {
      await removeFromList(ListType.watched, movie.id);
      await addToList(ListType.watchLater, movie);
    }
  }

  bool isInList(ListType type, int mediaId) {
    return (state[type] ?? []).any((e) => e.mediaId == mediaId);
  }

  Future<void> updateRating(int mediaId, double rating) async {
    state = {
      for (final entry in state.entries)
        entry.key: entry.value.map((item) {
          if (item.mediaId == mediaId) return item.copyWith(userRating: rating);
          return item;
        }).toList(),
    };
    if (supabaseService.isSignedIn) {
      await supabaseService.updateRating(mediaId, rating);
    }
  }

  Future<void> updateGenreIds(int mediaId, List<int> genreIds) async {
    if (genreIds.isEmpty) return;
    state = {
      for (final entry in state.entries)
        entry.key: entry.value.map((item) {
          if (item.mediaId == mediaId && item.genreIds.isEmpty) {
            return item.copyWith(genreIds: genreIds);
          }
          return item;
        }).toList(),
    };
    if (supabaseService.isSignedIn) {
      await supabaseService.updateGenreIds(mediaId, genreIds);
    }
  }
}

final listsProvider =
    StateNotifierProvider<ListsNotifier, Map<ListType, List<UserListItem>>>(
  (ref) => ListsNotifier(ref),
);

final favoritesProvider = Provider<List<UserListItem>>((ref) {
  return ref.watch(listsProvider)[ListType.favorites] ?? [];
});

final watchedProvider = Provider<List<UserListItem>>((ref) {
  return ref.watch(listsProvider)[ListType.watched] ?? [];
});

final watchLaterProvider = Provider<List<UserListItem>>((ref) {
  return ref.watch(listsProvider)[ListType.watchLater] ?? [];
});
