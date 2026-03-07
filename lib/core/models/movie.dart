class Movie {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? releaseDate;
  final List<int> genreIds;
  final String? originalLanguage;
  final double popularity;
  final bool adult;
  final bool video;
  final String mediaType;

  const Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.releaseDate,
    this.genreIds = const [],
    this.originalLanguage,
    this.popularity = 0.0,
    this.adult = false,
    this.video = false,
    this.mediaType = 'movie',
  });

  factory Movie.fromJson(Map<String, dynamic> json, {String? mediaType}) {
    return Movie(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      releaseDate: json['release_date'] as String? ?? json['first_air_date'] as String?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      originalLanguage: json['original_language'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      adult: json['adult'] as bool? ?? false,
      video: json['video'] as bool? ?? false,
      mediaType: mediaType ?? json['media_type'] as String? ?? 'movie',
    );
  }

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }

  String get ratingFormatted => voteAverage.toStringAsFixed(1);

  bool get hasPoster => posterPath != null && posterPath!.isNotEmpty;
  bool get hasBackdrop => backdropPath != null && backdropPath!.isNotEmpty;

  /// Returns false for adult content, untitled items, or items without a poster.
  bool get isVisible => !adult && hasPoster && title.trim().isNotEmpty;
}
