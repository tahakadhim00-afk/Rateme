import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../models/tv_detail.dart';
import '../models/genre.dart';
class TmdbService {
  late final Dio _dio;

  TmdbService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.tmdbBaseUrl,
      headers: {
        'Authorization': 'Bearer ${AppConstants.tmdbReadToken}',
        'Accept': 'application/json',
      },
      queryParameters: {'include_adult': false},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  // Genre IDs to always exclude (10749 = Romance used for AV, 27 = Horror borderline,
  // but most importantly we block the known AV-genre combos via vote threshold)
  static const _blockedGenres = <int>{};

  // Common AV title patterns (case-insensitive)
  static final _avPattern = RegExp(
    r'\b(uncensored|jav|av idol|gravure|hentai|xxx|porn|adult video)\b',
    caseSensitive: false,
  );

  bool _isSafe(Movie m) {
    if (!m.isVisible) return false;
    // Require a minimum number of votes — AV films on TMDB almost always
    // have 0-2 votes since real audiences don't rate them there.
    if (m.voteCount < 5) return false;
    // Block if the title matches known AV keywords
    if (_avPattern.hasMatch(m.title)) return false;
    if (m.originalTitle != null && _avPattern.hasMatch(m.originalTitle!)) return false;
    // Block by genre if needed
    if (m.genreIds.any(_blockedGenres.contains)) return false;
    return true;
  }

  List<Movie> _clean(List<Movie> movies) => movies.where(_isSafe).toList();

  Future<List<Movie>> getTrending({String timeWindow = 'week'}) async {
    final resp = await _dio.get('/trending/movie/$timeWindow');
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<Movie>> getNowPlaying({int page = 1}) async {
    final resp = await _dio.get('/movie/now_playing', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<Movie>> getPopular({int page = 1}) async {
    final resp = await _dio.get('/movie/popular', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<Movie>> getTopRated({int page = 1}) async {
    final resp = await _dio.get('/movie/top_rated', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<Movie>> getUpcoming({int page = 1}) async {
    final resp = await _dio.get('/movie/upcoming', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    // Upcoming films may have 0 votes legitimately — use a lighter filter
    return results
        .map((e) => Movie.fromJson(e as Map<String, dynamic>))
        .where((m) =>
            !m.adult &&
            m.hasPoster &&
            m.title.trim().isNotEmpty &&
            !_avPattern.hasMatch(m.title))
        .toList();
  }

  Future<List<Movie>> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final resp = await _dio.get('/search/movie', queryParameters: {
      'query': query,
      'page': page,
    });
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<MovieDetail> getMovieDetail(int movieId) async {
    final resp = await _dio.get('/movie/$movieId',
        queryParameters: {'append_to_response': 'credits'});
    return MovieDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<dynamic>> getMovieCredits(int movieId) async {
    final resp = await _dio.get('/movie/$movieId/credits');
    return resp.data['cast'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPersonDetail(int personId) async {
    final resp = await _dio.get('/person/$personId',
        queryParameters: {'append_to_response': 'movie_credits'});
    return resp.data as Map<String, dynamic>;
  }

  Future<List<Movie>> getMovieRecommendations(int movieId) async {
    final resp = await _dio.get('/movie/$movieId/recommendations');
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<Movie>> discoverByGenre(int genreId, {int page = 1}) async {
    final resp = await _dio.get('/discover/movie', queryParameters: {
      'with_genres': genreId,
      'page': page,
      'sort_by': 'popularity.desc',
    });
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList());
  }

  Future<List<Genre>> getGenres() async {
    final resp = await _dio.get('/genre/movie/list');
    final genres = resp.data['genres'] as List<dynamic>;
    return genres.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── TV Shows (lists) ──────────────────────────────────────────────────────

  Future<List<Movie>> getTrendingTv({String timeWindow = 'week'}) async {
    final resp = await _dio.get('/trending/tv/$timeWindow');
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>, mediaType: 'tv')).toList());
  }

  Future<List<Movie>> getPopularTv({int page = 1}) async {
    final resp = await _dio.get('/tv/popular', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>, mediaType: 'tv')).toList());
  }

  Future<List<Movie>> getTopRatedTv({int page = 1}) async {
    final resp = await _dio.get('/tv/top_rated', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>, mediaType: 'tv')).toList());
  }

  Future<List<Movie>> getAiringToday({int page = 1}) async {
    final resp = await _dio.get('/tv/airing_today', queryParameters: {'page': page});
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>, mediaType: 'tv')).toList());
  }

  // ── TV Show detail ─────────────────────────────────────────────────────────

  Future<TvDetail> getTvDetail(int tvId) async {
    final resp = await _dio.get('/tv/$tvId',
        queryParameters: {'append_to_response': 'credits'});
    return TvDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<TvSeasonDetail> getTvSeasonDetail(int tvId, int seasonNumber) async {
    final resp = await _dio.get('/tv/$tvId/season/$seasonNumber');
    return TvSeasonDetail.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Movie>> getTvRecommendations(int tvId) async {
    final resp = await _dio.get('/tv/$tvId/recommendations');
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results.map((e) => Movie.fromJson(e as Map<String, dynamic>, mediaType: 'tv')).toList());
  }

  // ── Videos (trailers & teasers) ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMovieVideos(int movieId) async {
    final resp = await _dio.get('/movie/$movieId/videos');
    final results = resp.data['results'] as List<dynamic>;
    return results
        .cast<Map<String, dynamic>>()
        .where((v) =>
            v['site'] == 'YouTube' &&
            (v['type'] == 'Trailer' || v['type'] == 'Teaser'))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTvVideos(int tvId) async {
    final resp = await _dio.get('/tv/$tvId/videos');
    final results = resp.data['results'] as List<dynamic>;
    return results
        .cast<Map<String, dynamic>>()
        .where((v) =>
            v['site'] == 'YouTube' &&
            (v['type'] == 'Trailer' || v['type'] == 'Teaser'))
        .toList();
  }

  // ── Person search ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchPeople(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final resp = await _dio.get('/search/person', queryParameters: {
      'query': query,
      'page': page,
    });
    final results = resp.data['results'] as List<dynamic>;
    return results
        .cast<Map<String, dynamic>>()
        .where((e) =>
            (e['id'] as int?) != null &&
            (e['name'] as String?)?.isNotEmpty == true)
        .toList();
  }

  // ── Multi-search (movies + TV) ─────────────────────────────────────────────

  Future<List<Movie>> searchMulti(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];
    final resp = await _dio.get('/search/multi', queryParameters: {
      'query': query,
      'page': page,
    });
    final results = resp.data['results'] as List<dynamic>;
    return _clean(results
        .map((e) => e as Map<String, dynamic>)
        .where((e) => e['media_type'] == 'movie' || e['media_type'] == 'tv')
        .map((e) => Movie.fromJson(e))
        .toList());
  }

  // ── Images (backdrops) ─────────────────────────────────────────────────────

  Future<List<String>> getBackdrops(int id, String mediaType) async {
    final endpoint = mediaType == 'tv' ? '/tv/$id/images' : '/movie/$id/images';
    final resp = await _dio.get(endpoint);
    final backdrops = resp.data['backdrops'] as List<dynamic>? ?? [];
    return backdrops
        .map((e) => e['file_path'] as String)
        .where((p) => p.isNotEmpty)
        .take(20)
        .toList();
  }

  // ── Paginated dispatcher (used by infinite-scroll sections) ───────────────

  Future<List<Movie>> getPage(String category, int page) async {
    switch (category) {
      case 'popular_movies':
        return getPopular(page: page);
      case 'top_rated_movies':
        return getTopRated(page: page);
      case 'now_playing':
        return getNowPlaying(page: page);
      case 'upcoming':
        return getUpcoming(page: page);
      case 'popular_tv':
        return getPopularTv(page: page);
      case 'top_rated_tv':
        return getTopRatedTv(page: page);
      case 'airing_today':
        return getAiringToday(page: page);
      case 'trending_movies':
        return getTrending();
      case 'trending_tv':
        return getTrendingTv();
      default:
        return [];
    }
  }
}
