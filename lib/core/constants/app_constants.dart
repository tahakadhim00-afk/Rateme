import '../config/secrets.dart';

class AppConstants {
  static const String tmdbApiKey = Secrets.tmdbApiKey;
  static const String tmdbReadToken = Secrets.tmdbReadToken;
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  static const String posterW342 = '/w342';
  static const String posterW500 = '/w500';
  static const String posterOriginal = '/original';
  static const String backdropW780 = '/w780';
  static const String backdropW1280 = '/w1280';
  static const String backdropOriginal = '/original';

  static String posterUrl(String path, {String size = '/w342'}) =>
      '$tmdbImageBaseUrl$size$path';

  static String backdropUrl(String path, {String size = '/w780'}) =>
      '$tmdbImageBaseUrl$size$path';
}
