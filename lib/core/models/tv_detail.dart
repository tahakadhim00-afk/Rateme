import 'genre.dart';
import 'movie_detail.dart'; // for Cast

class TvSeason {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final String? airDate;

  const TvSeason({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    required this.episodeCount,
    this.airDate,
  });

  factory TvSeason.fromJson(Map<String, dynamic> json) {
    return TvSeason(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Season ${json['season_number']}',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
      airDate: json['air_date'] as String?,
    );
  }

  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;

  String get year {
    if (airDate == null || airDate!.length < 4) return '';
    return airDate!.substring(0, 4);
  }
}

class Episode {
  final int id;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final int? runtime;
  final double voteAverage;

  const Episode({
    required this.id,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
    this.voteAverage = 0.0,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      airDate: json['air_date'] as String?,
      runtime: json['runtime'] as int?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get hasStill => stillPath != null && stillPath!.isNotEmpty;

  String get runtimeFormatted {
    if (runtime == null || runtime == 0) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  String get year {
    if (airDate == null || airDate!.length < 4) return '';
    return airDate!.substring(0, 4);
  }
}

class TvSeasonDetail {
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? airDate;
  final List<Episode> episodes;

  const TvSeasonDetail({
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    this.airDate,
    this.episodes = const [],
  });

  factory TvSeasonDetail.fromJson(Map<String, dynamic> json) {
    return TvSeasonDetail(
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      airDate: json['air_date'] as String?,
      episodes: (json['episodes'] as List<dynamic>?)
              ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
}

class TvDetail {
  final int id;
  final String title;
  final String? tagline;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? firstAirDate;
  final String? lastAirDate;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final List<int> episodeRunTime;
  final String? status;
  final List<Genre> genres;
  final List<Cast> cast;
  final List<TvSeason> seasons;
  final String? originalLanguage;

  const TvDetail({
    required this.id,
    required this.title,
    this.tagline,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.firstAirDate,
    this.lastAirDate,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.episodeRunTime = const [],
    this.status,
    this.genres = const [],
    this.cast = const [],
    this.seasons = const [],
    this.originalLanguage,
  });

  factory TvDetail.fromJson(Map<String, dynamic> json) {
    return TvDetail(
      id: json['id'] as int,
      title: json['name'] as String? ?? '',
      tagline: json['tagline'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      firstAirDate: json['first_air_date'] as String?,
      lastAirDate: json['last_air_date'] as String?,
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
      episodeRunTime: (json['episode_run_time'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      status: json['status'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cast: ((json['credits'] as Map<String, dynamic>?)?['cast']
                  as List<dynamic>?)
              ?.take(20)
              .map((e) => Cast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seasons: (json['seasons'] as List<dynamic>?)
              ?.map((e) => TvSeason.fromJson(e as Map<String, dynamic>))
              .where((s) => s.seasonNumber > 0)
              .toList() ??
          [],
      originalLanguage: json['original_language'] as String?,
    );
  }

  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
  bool get hasBackdrop => backdropPath != null && backdropPath!.isNotEmpty;
  bool get isEnded => status == 'Ended' || status == 'Canceled';

  String get year {
    if (firstAirDate == null || firstAirDate!.length < 4) return '';
    return firstAirDate!.substring(0, 4);
  }

  String get ratingFormatted => voteAverage.toStringAsFixed(1);

  String get episodeRuntimeFormatted {
    if (episodeRunTime.isEmpty) return '';
    final mins = episodeRunTime.first;
    if (mins == 0) return '';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}m/ep';
    if (m == 0) return '${h}h/ep';
    return '${h}h ${m}m/ep';
  }
}
