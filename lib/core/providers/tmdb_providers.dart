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
  return ref.watch(tmdbServiceProvider).getTrending();
});

// Now playing
final nowPlayingProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getNowPlaying();
});

// Popular movies
final popularMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getPopular();
});

// Top rated
final topRatedProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getTopRated();
});

// Upcoming
final upcomingProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getUpcoming();
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
  return ref.watch(tmdbServiceProvider).getMovieRecommendations(movieId);
});

// Search (multi: movies + TV)
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.watch(tmdbServiceProvider).searchMulti(query);
});

// Genres
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  return ref.watch(tmdbServiceProvider).getGenres();
});

// Selected genre
final selectedGenreProvider = StateProvider<int?>((ref) => null);

final discoverByGenreProvider =
    FutureProvider.family<List<Movie>, int>((ref, genreId) async {
  return ref.watch(tmdbServiceProvider).discoverByGenre(genreId);
});

// ── TV Shows ──────────────────────────────────────────────────────────────

final trendingTvProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getTrendingTv();
});

final popularTvProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getPopularTv();
});

final topRatedTvProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getTopRatedTv();
});

final airingTodayProvider = FutureProvider<List<Movie>>((ref) async {
  return ref.watch(tmdbServiceProvider).getAiringToday();
});

// ── Infinite scroll paginated sections ────────────────────────────────────
// Key: (category, page) — category matches TmdbService.getPage() switch keys

final paginatedSectionProvider =
    FutureProvider.family<List<Movie>, (String, int)>((ref, params) async {
  final (category, page) = params;
  return ref.watch(tmdbServiceProvider).getPage(category, page);
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
  return ref.watch(tmdbServiceProvider).getTvRecommendations(tvId);
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

