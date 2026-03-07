import 'movie.dart';

class ActorDetail {
  final int id;
  final String name;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? profilePath;
  final String knownForDepartment;
  final double popularity;
  final List<String> alsoKnownAs;
  final List<Movie> knownForMovies;

  const ActorDetail({
    required this.id,
    required this.name,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment = 'Acting',
    this.popularity = 0.0,
    this.alsoKnownAs = const [],
    this.knownForMovies = const [],
  });

  factory ActorDetail.fromJson(Map<String, dynamic> json) {
    final credits = json['movie_credits'] as Map<String, dynamic>?;
    List<Movie> movies = [];
    if (credits != null) {
      final cast = credits['cast'] as List<dynamic>?;
      if (cast != null) {
        movies = cast
            .map((e) => Movie.fromJson(e as Map<String, dynamic>))
            .where((m) => m.hasPoster && m.releaseDate != null)
            .toList()
          ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        if (movies.length > 20) movies = movies.sublist(0, 20);
      }
    }

    return ActorDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      biography: json['biography'] as String?,
      birthday: json['birthday'] as String?,
      deathday: json['deathday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      profilePath: json['profile_path'] as String?,
      knownForDepartment: json['known_for_department'] as String? ?? 'Acting',
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      alsoKnownAs: (json['also_known_as'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      knownForMovies: movies,
    );
  }

  bool get hasProfile => profilePath != null && profilePath!.isNotEmpty;

  String get age {
    if (birthday == null) return '';
    try {
      final dob = DateTime.parse(birthday!);
      final end =
          deathday != null ? DateTime.parse(deathday!) : DateTime.now();
      int a = end.year - dob.year;
      if (end.month < dob.month ||
          (end.month == dob.month && end.day < dob.day)) {
        a--;
      }
      return a.toString();
    } catch (_) {
      return '';
    }
  }

  String get birthYear {
    if (birthday == null || birthday!.length < 4) return '';
    return birthday!.substring(0, 4);
  }
}
