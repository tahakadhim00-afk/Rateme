import 'genre.dart';

class Cast {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  const Cast({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory Cast.fromJson(Map<String, dynamic> json) {
    return Cast(
      id: json['id'] as int,
      name: json['name'] as String,
      character: json['character'] as String?,
      profilePath: json['profile_path'] as String?,
    );
  }
}

class MovieDetail {
  final int id;
  final String title;
  final String? tagline;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final int? runtime;
  final List<Genre> genres;
  final List<Cast> cast;
  final String? status;
  final String? originalLanguage;
  final double popularity;
  final String? homepage;

  const MovieDetail({
    required this.id,
    required this.title,
    this.tagline,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    this.runtime,
    this.genres = const [],
    this.cast = const [],
    this.status,
    this.originalLanguage,
    this.popularity = 0.0,
    this.homepage,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    return MovieDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      tagline: json['tagline'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: json['release_date'] as String?,
      runtime: json['runtime'] as int?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cast: ((json['credits'] as Map<String, dynamic>?)?['cast'] as List<dynamic>?)
              ?.take(20)
              .map((e) => Cast.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String?,
      originalLanguage: json['original_language'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      homepage: json['homepage'] as String?,
    );
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }

  String get ratingFormatted => voteAverage.toStringAsFixed(1);

  String get runtimeFormatted {
    if (runtime == null) return '';
    final h = runtime! ~/ 60;
    final m = runtime! % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
  bool get hasBackdrop => backdropPath != null && backdropPath!.isNotEmpty;
}
