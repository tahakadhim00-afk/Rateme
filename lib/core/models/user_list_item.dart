enum ListType { watched, watchLater, custom }

class UserListItem {
  final int mediaId;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final double voteAverage;
  final ListType listType;
  final String mediaType;
  final DateTime addedAt;
  final double? userRating;
  final String? review;
  final int? runtime;
  final List<int> genreIds;

  const UserListItem({
    required this.mediaId,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.voteAverage = 0.0,
    required this.listType,
    this.mediaType = 'movie',
    required this.addedAt,
    this.userRating,
    this.review,
    this.runtime,
    this.genreIds = const [],
  });

  String get year {
    if (releaseDate == null || releaseDate!.isEmpty) return '';
    return releaseDate!.substring(0, 4);
  }

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['list_type'] as String? ?? 'favorites';
    final listType = ListType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => ListType.watched,
    );
    return UserListItem(
      mediaId: json['media_id'] as int,
      title: json['title'] as String,
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      listType: listType,
      mediaType: json['media_type'] as String? ?? 'movie',
      addedAt: DateTime.parse(json['added_at'] as String),
      userRating: (json['user_rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
      runtime: json['runtime'] as int?,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  UserListItem copyWith({double? userRating, String? review, List<int>? genreIds}) {
    return UserListItem(
      mediaId: mediaId,
      title: title,
      posterPath: posterPath,
      releaseDate: releaseDate,
      voteAverage: voteAverage,
      listType: listType,
      mediaType: mediaType,
      addedAt: addedAt,
      userRating: userRating ?? this.userRating,
      review: review ?? this.review,
      runtime: runtime,
      genreIds: genreIds ?? this.genreIds,
    );
  }
}
