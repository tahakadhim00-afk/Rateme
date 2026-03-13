class PersonPreference {
  final int personId;
  final String personName;
  final String personType; // 'actor' | 'director'
  final String? profilePath;
  final DateTime addedAt;

  const PersonPreference({
    required this.personId,
    required this.personName,
    required this.personType,
    this.profilePath,
    required this.addedAt,
  });

  factory PersonPreference.fromJson(Map<String, dynamic> json) =>
      PersonPreference(
        personId: json['person_id'] as int,
        personName: json['person_name'] as String,
        personType: json['person_type'] as String,
        profilePath: json['profile_path'] as String?,
        addedAt: DateTime.parse(json['added_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'person_name': personName,
        'person_type': personType,
        'profile_path': profilePath,
        'added_at': addedAt.toIso8601String(),
      };
}

/// Lightweight model used during the onboarding search/grid.
class PersonResult {
  final int id;
  final String name;
  final String? profilePath;
  final String knownForDepartment; // 'Acting' | 'Directing'

  const PersonResult({
    required this.id,
    required this.name,
    this.profilePath,
    required this.knownForDepartment,
  });

  factory PersonResult.fromJson(Map<String, dynamic> json) => PersonResult(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        profilePath: json['profile_path'] as String?,
        knownForDepartment:
            json['known_for_department'] as String? ?? 'Acting',
      );

  bool get hasProfile => profilePath != null && profilePath!.isNotEmpty;

  bool get isActor => knownForDepartment == 'Acting';

  bool get isDirector => knownForDepartment == 'Directing';
}
