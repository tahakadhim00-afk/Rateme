class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

const List<Genre> kMovieGenres = [
  Genre(id: 28, name: 'Action'),
  Genre(id: 12, name: 'Adventure'),
  Genre(id: 16, name: 'Animation'),
  Genre(id: 35, name: 'Comedy'),
  Genre(id: 80, name: 'Crime'),
  Genre(id: 99, name: 'Documentary'),
  Genre(id: 18, name: 'Drama'),
  Genre(id: 10751, name: 'Family'),
  Genre(id: 14, name: 'Fantasy'),
  Genre(id: 36, name: 'History'),
  Genre(id: 27, name: 'Horror'),
  Genre(id: 10402, name: 'Music'),
  Genre(id: 9648, name: 'Mystery'),
  Genre(id: 10749, name: 'Romance'),
  Genre(id: 878, name: 'Sci-Fi'),
  Genre(id: 10770, name: 'TV Movie'),
  Genre(id: 53, name: 'Thriller'),
  Genre(id: 10752, name: 'War'),
  Genre(id: 37, name: 'Western'),
];

// TV-specific genre IDs from TMDB (some IDs overlap with movies above)
const List<Genre> kTvGenres = [
  Genre(id: 10759, name: 'Action & Adventure'),
  Genre(id: 16, name: 'Animation'),
  Genre(id: 35, name: 'Comedy'),
  Genre(id: 80, name: 'Crime'),
  Genre(id: 99, name: 'Documentary'),
  Genre(id: 18, name: 'Drama'),
  Genre(id: 10751, name: 'Family'),
  Genre(id: 10762, name: 'Kids'),
  Genre(id: 9648, name: 'Mystery'),
  Genre(id: 10763, name: 'News'),
  Genre(id: 10764, name: 'Reality'),
  Genre(id: 10765, name: 'Sci-Fi & Fantasy'),
  Genre(id: 10766, name: 'Soap'),
  Genre(id: 10767, name: 'Talk'),
  Genre(id: 10768, name: 'War & Politics'),
  Genre(id: 37, name: 'Western'),
];

/// Merged lookup map covering both movie and TV genre IDs.
final Map<int, String> kGenreNames = {
  for (final g in [...kMovieGenres, ...kTvGenres]) g.id: g.name,
};
