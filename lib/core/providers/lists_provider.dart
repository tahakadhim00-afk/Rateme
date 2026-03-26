import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_list_item.dart';
import '../models/movie.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

class ListsNotifier extends StateNotifier<Map<ListType, List<UserListItem>>> {
  final Ref _ref;

  ListsNotifier(this._ref)
      : super({
          ListType.watched: [],
          ListType.watchLater: [],
        }) {
    _ref.listen<bool>(
      isSignedInProvider,
      (_, next) => next ? loadFromSupabase() : clearAll(),
      fireImmediately: true,
    );
  }

  Future<void> loadFromSupabase() async {
    await Future<void>.value();
    if (!mounted) return;
    _ref.read(listsLoadingProvider.notifier).state = true;
    try {
      await Future.wait([
        for (final item in [
          ...(state[ListType.watched] ?? []),
          ...(state[ListType.watchLater] ?? []),
        ])
          supabaseService.addToList(item).catchError((_) {}),
      ]);

      final items = await supabaseService.fetchUserLists();
      final grouped = <ListType, List<UserListItem>>{
        ListType.watched: [],
        ListType.watchLater: [],
      };
      for (final item in items) {
        grouped[item.listType]?.add(item);
      }
      state = grouped;
    } catch (e, st) {
      debugPrint('ListsNotifier.loadFromSupabase error: $e\n$st');
    } finally {
      if (mounted) _ref.read(listsLoadingProvider.notifier).state = false;
    }
  }

  void clearAll() {
    state = {
      ListType.watched: [],
      ListType.watchLater: [],
    };
  }

  Future<void> addToList(
    ListType type,
    Movie movie, {
    double? userRating,
    int? runtime,
    List<int> genreIds = const [],
  }) async {
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
      } catch (e, st) {
        debugPrint('ListsNotifier.addToList error: $e\n$st');
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
      } catch (e, st) {
        debugPrint('ListsNotifier.removeFromList error: $e\n$st');
      }
    }
  }

  Future<void> toggleList(
    ListType type,
    Movie movie, {
    int? runtime,
    List<int> genreIds = const [],
  }) async {
    if (isInList(type, movie.id)) {
      await removeFromList(type, movie.id);
    } else {
      await addToList(type, movie, runtime: runtime, genreIds: genreIds);
    }
  }

  Future<void> toggleWatched(
    Movie movie, {
    int? runtime,
    List<int> genreIds = const [],
  }) async {
    if (isInList(ListType.watched, movie.id)) {
      await removeFromList(ListType.watched, movie.id);
    } else {
      await removeFromList(ListType.watchLater, movie.id);
      await addToList(ListType.watched, movie, runtime: runtime, genreIds: genreIds);
    }
  }

  Future<void> toggleWatchLater(Movie movie) async {
    if (isInList(ListType.watchLater, movie.id)) {
      await removeFromList(ListType.watchLater, movie.id);
    } else {
      await removeFromList(ListType.watched, movie.id);
      await addToList(ListType.watchLater, movie);
    }
  }

  bool isInList(ListType type, int mediaId) =>
      (state[type] ?? []).any((e) => e.mediaId == mediaId);

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

final listsLoadingProvider = StateProvider<bool>((ref) => false);

final listsProvider =
    StateNotifierProvider<ListsNotifier, Map<ListType, List<UserListItem>>>(
  (ref) => ListsNotifier(ref),
);

final watchedProvider = Provider<List<UserListItem>>(
  (ref) => ref.watch(listsProvider)[ListType.watched] ?? [],
);

final watchLaterProvider = Provider<List<UserListItem>>(
  (ref) => ref.watch(listsProvider)[ListType.watchLater] ?? [],
);

final recentlyRatedProvider = Provider<List<UserListItem>>((ref) {
  final watched = ref.watch(watchedProvider);
  return watched
      .where((i) => i.userRating != null)
      .toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
});
