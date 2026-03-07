class AppConstants {
  // TMDb API
  static const String tmdbApiKey = 'TMDB_API_KEY_REMOVED';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String tmdbReadToken =
      'TMDB_READ_TOKEN_REMOVED';

  // Image sizes
  static const String posterW342 = '/w342';
  static const String posterW500 = '/w500';
  static const String backdropW780 = '/w780';
  static const String backdropOriginal = '/original';

  static String posterUrl(String path, {String size = '/w342'}) =>
      '$tmdbImageBaseUrl$size$path';

  static String backdropUrl(String path, {String size = '/w780'}) =>
      '$tmdbImageBaseUrl$size$path';
}
