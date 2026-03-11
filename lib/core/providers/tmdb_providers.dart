import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/tv_detail.dart';
import '../models/actor_detail.dart';
import '../models/genre.dart';
import '../services/tmdb_service.dart';

final tmdbServiceProvider = Provider<TmdbService>((ref) => TmdbService());

// Trending movies
final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getTrending();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Now playing
final nowPlayingProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getNowPlaying();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Popular movies
final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getPopular();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Top rated
final topRatedProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getTopRated();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Upcoming
final upcomingProvider = FutureProvider<List<Movie>>((ref) async {
  final results = await ref.watch(tmdbServiceProvider).getUpcoming();
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Movie detail
final movieDetailProvider =
    FutureProvider.family<MovieDetail, int>((ref, movieId) async {
  return ref.watch(tmdbServiceProvider).getMovieDetail(movieId);
});

// Movie cast
final movieCastProvider =
    FutureProvider.family<List<Cast>, int>((ref, movieId) async {
  final raw = await ref.watch(tmdbServiceProvider).getMovieCredits(movieId);
  return raw
      .take(20)
      .map((e) => Cast.fromJson(e as Map<String, dynamic>))
      .toList();
});

// Movie recommendations
final movieRecommendationsProvider =
    FutureProvider.family<List<Movie>, int>((ref, movieId) async {
  final results = await ref.watch(tmdbServiceProvider).getMovieRecommendations(movieId);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Search (multi: movies + TV)
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final results = await ref.watch(tmdbServiceProvider).searchMulti(query);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
});

// Genres
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return ref.watch(tmdbServiceProvider).getGenres();
});

// Selected genre
final selectedGenreProvider = StateProvider<int?>((ref) => null);

final discoverByGenreProvider =
    FutureProvider.family<List<Movie>, int>((ref, genreId) async {
  final results = await ref.watch(tmdbServiceProvider).discoverByGenre(genreId);
  return results.where((m) => m.voteAverage > 0.0 && m.voteAverage < 10.0).toList();
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

