class UserPreference {
  final int personId;
  final String personName;
  final String personType; // 'actor' | 'director'
  final String? profilePath;
  final DateTime addedAt;

  const UserPreference({
    required this.personId,
    required this.personName,
    required this.personType,
    this.profilePath,
    required this.addedAt,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      personId: json['person_id'] as int,
      personName: json['person_name'] as String,
      personType: json['person_type'] as String,
      profilePath: json['profile_path'] as String?,
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
}
