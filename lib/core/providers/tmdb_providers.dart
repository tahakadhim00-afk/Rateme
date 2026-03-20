import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/tv_detail.dart';
import '../models/actor_detail.dart';
import '../models/genre.dart';
import '../services/tmdb_service.dart';

final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService());

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getTrending();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final nowPlayingProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getNowPlaying();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getPopular();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final topRatedProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getTopRated();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final upcomingProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getUpcoming();
  return results.where((m) => m.voteAverage < 10.0).toList();
});

final movieDetailProvider =
    FutureProvider.family<MovieDetail, int>((ref, movieId) async {
  return ref.watch(tmdbServiceProvider).getMovieDetail(movieId);
});

final movieCastProvider =
    FutureProvider.family<List<Cast>, int>((ref, movieId) async {
  final raw = await ref.watch(tmdbServiceProvider).getMovieCredits(movieId);
  return raw
      .take(20)
      .map((e) => Cast.fromJson(e as Map<String, dynamic>))
      .toList();
});

final movieRecommendationsProvider =
    FutureProvider.family<List<Movie>, int>((ref, movieId) async {
  final results = await ref.watch(tmdbServiceProvider).getMovieRecommendations(movieId);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final results = await ref.watch(tmdbServiceProvider).searchMulti(query);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final searchPeopleProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.watch(tmdbServiceProvider).searchPeople(query);
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return ref.watch(tmdbServiceProvider).getGenres();
});

final selectedGenreProvider = StateProvider<int?>((ref) => null);

// ── Paginated genre discover
class GenreMoviesState {
  final List<Movie> movies;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalPages;

  const GenreMoviesState({
    this.movies = const [],
    this.currentPage = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.totalPages = 1,
  });

  GenreMoviesState copyWith({
    List<Movie>? movies,
    int? currentPage,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalPages,
  }) =>
      GenreMoviesState(
        movies: movies ?? this.movies,
        currentPage: currentPage ?? this.currentPage,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        totalPages: totalPages ?? this.totalPages,
      );
}

class GenreMoviesNotifier extends StateNotifier<AsyncValue<GenreMoviesState>> {
  final Ref _ref;
  final int genreId;

  GenreMoviesNotifier(this._ref, this.genreId)
      : super(const AsyncValue.loading()) {
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    try {
      final service = _ref.read(tmdbServiceProvider);
      final (raw, totalPages) =
          await service.discoverByGenrePaged(genreId, page: page);
      final fresh =
          raw.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
      final hasMore = page < totalPages;

      state = state.when(
        data: (s) => AsyncValue.data(s.copyWith(
          movies: [...s.movies, ...fresh],
          currentPage: page,
          isLoadingMore: false,
          hasMore: hasMore,
          totalPages: totalPages,
        )),
        loading: () => AsyncValue.data(GenreMoviesState(
          movies: fresh,
          currentPage: page,
          isLoadingMore: false,
          hasMore: hasMore,
          totalPages: totalPages,
        )),
        error: (_, _) => AsyncValue.data(GenreMoviesState(
          movies: fresh,
          currentPage: page,
          isLoadingMore: false,
          hasMore: hasMore,
          totalPages: totalPages,
        )),
      );
    } catch (e, st) {
      if (state is AsyncLoading) {
        state = AsyncValue.error(e, st);
      } else {
        state = state.when(
          data: (s) => AsyncValue.data(s.copyWith(isLoadingMore: false)),
          loading: () => AsyncValue.error(e, st),
          error: (e2, st2) => AsyncValue.error(e, st),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    await _loadPage(current.currentPage + 1);
  }
}

final genreMoviesProvider = StateNotifierProvider.family<GenreMoviesNotifier,
    AsyncValue<GenreMoviesState>, int>((ref, genreId) {
  return GenreMoviesNotifier(ref, genreId);
});

class GenreTvMoviesNotifier extends StateNotifier<AsyncValue<GenreMoviesState>> {
  final Ref _ref;
  final int genreId;

  GenreTvMoviesNotifier(this._ref, this.genreId)
      : super(const AsyncValue.loading()) {
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    try {
      final service = _ref.read(tmdbServiceProvider);
      final (raw, totalPages) =
          await service.discoverTvByGenrePaged(genreId, page: page);
      final fresh =
          raw.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
      final hasMore = page < totalPages;

      state = state.when(
        data: (s) => AsyncValue.data(s.copyWith(
          movies: [...s.movies, ...fresh],
          currentPage: page,
          isLoadingMore: false,
          hasMore: hasMore,
          totalPages: totalPages,
        )),
        loading: () => AsyncValue.data(GenreMoviesState(
          movies: fresh,
          currentPage: page,
          isLoadingMore: false,
          hasMore: hasMore,
          totalPages: totalPages,
        )),
        error: (_, _) => AsyncValue.data(GenreMoviesState(
          movies: fresh,
          currentPage: page,
          isLoadingMore: false,
          hasMore: hasMore,
          totalPages: totalPages,
        )),
      );
    } catch (e, st) {
      if (state is AsyncLoading) {
        state = AsyncValue.error(e, st);
      } else {
        state = state.when(
          data: (s) => AsyncValue.data(s.copyWith(isLoadingMore: false)),
          loading: () => AsyncValue.error(e, st),
          error: (e2, st2) => AsyncValue.error(e, st),
        );
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    await _loadPage(current.currentPage + 1);
  }
}

final genreTvMoviesProvider = StateNotifierProvider.family<GenreTvMoviesNotifier,
    AsyncValue<GenreMoviesState>, int>((ref, genreId) {
  return GenreTvMoviesNotifier(ref, genreId);
});

// ── TV Shows ──────────────────────────────────────────────────────────────

final trendingTvProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getTrendingTv();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final popularTvProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getPopularTv();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final topRatedTvProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getTopRatedTv();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

final airingTodayProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getAiringToday();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// ── Infinite scroll paginated sections ────────────────────────────────────
// Key: (category, page) — category matches TmdbService.getPage() switch keys

final paginatedSectionProvider =
    FutureProvider.family<List<Movie>, (String, int)>((ref, params) async {
  final (category, page) = params;
  final results = await ref.watch(tmdbServiceProvider).getPage(category, page);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// ── TV Show detail ─────────────────────────────────────────────────────────

final tvDetailProvider =
    FutureProvider.family<TvDetail, int>((ref, tvId) async {
  return ref.watch(tmdbServiceProvider).getTvDetail(tvId);
});

final tvSeasonDetailProvider =
    FutureProvider.family<TvSeasonDetail, (int, int)>((ref, params) async {
  final (tvId, seasonNumber) = params;
  return ref.watch(tmdbServiceProvider).getTvSeasonDetail(tvId, seasonNumber);
});

final tvRecommendationsProvider =
    FutureProvider.family<List<Movie>, int>((ref, tvId) async {
  final results = await ref.watch(tmdbServiceProvider).getTvRecommendations(tvId);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// ── Videos (trailers) ────────────────────────────────────────────────────

final movieVideosProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, movieId) async {
  return ref.watch(tmdbServiceProvider).getMovieVideos(movieId);
});

final tvVideosProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, tvId) async {
  return ref.watch(tmdbServiceProvider).getTvVideos(tvId);
});

// ── Actor / Person ────────────────────────────────────────────────────────

final personDetailProvider =
    FutureProvider.family<ActorDetail, int>((ref, personId) async {
  final data = await ref.watch(tmdbServiceProvider).getPersonDetail(personId);
  return ActorDetail.fromJson(data);
});

