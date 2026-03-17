class Award {
  final int id;
  final String name;
  final String? logoPath;
  final String? assetPath; // local WebP asset, takes priority over logoPath
  final String? overview;
  final String? originCountry;
  final int? latestEventId;
  final String? latestCeremonyDate;

  const Award({
    required this.id,
    required this.name,
    this.logoPath,
    this.assetPath,
    this.overview,
    this.originCountry,
    this.latestEventId,
    this.latestCeremonyDate,
  });

  factory Award.fromJson(Map<String, dynamic> json) {
    final event = json['latest_event'] as Map<String, dynamic>?;
    return Award(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? 'Unknown Award',
      logoPath: json['logo_path'] as String?,
      overview: json['overview'] as String?,
      originCountry: json['origin_country'] as String?,
      latestEventId: event != null ? (event['id'] as num?)?.toInt() : null,
      latestCeremonyDate: event != null
          ? (event['date'] as String?) ?? (event['ceremony_date'] as String?)
          : json['latest_ceremony'] as String?,
    );
  }

  /// TMDB image CDN — award logos live on media.themoviedb.org.
  String? logoUrl({String size = 'h90'}) {
    if (logoPath == null || logoPath!.isEmpty) return null;
    return 'https://media.themoviedb.org/t/p/$size$logoPath';
  }

  bool get hasLogo => assetPath != null || (logoPath != null && logoPath!.isNotEmpty);
  bool get hasLocalAsset => assetPath != null;
  bool get isLogoSvg => logoPath?.endsWith('.svg') == true;
}

// ── Real TMDB awards — IDs + logos ────────────────────────────────────────────

const List<Award> kTmdbAwards = [
  Award(
    id: 1,
    name: 'Academy Awards',
    assetPath: 'assets/awards/AcademyAwards.webp',
    logoPath: '/1mAyfJSMw7WaZr3f6zVpKkCLGb2.svg',
    originCountry: 'United States',
    latestCeremonyDate: '2026-03-15',
  ),
  Award(
    id: 4,
    name: 'Golden Globe Awards',
    assetPath: 'assets/awards/GoldenGlobes.webp',
    logoPath: '/ofPR9818YPpn6hqmXlU6khOnqGI.png',
    originCountry: 'United States',
    latestCeremonyDate: '2026-01-11',
  ),
  Award(
    id: 5,
    name: 'BAFTA Film Awards',
    assetPath: 'assets/awards/BAFTAFilmAwards.webp',
    logoPath: '/9osU4kIvTzZZtcQEEqDKhHqhNNK.png',
    originCountry: 'United Kingdom',
    latestCeremonyDate: '2026-02-22',
  ),
  Award(
    id: 7,
    name: "Critics' Choice Awards",
    assetPath: 'assets/awards/CriticsChoiceAwards.webp',
    logoPath: '/wS8P139CybPMbEgj1WDQnL15e8F.svg',
    originCountry: 'United States',
    latestCeremonyDate: '2026-01-04',
  ),
  Award(
    id: 39,
    name: 'Film Independent Spirit Awards',
    assetPath: 'assets/awards/TheFilmIndependentSpiritAwards.webp',
    logoPath: '/oS8cvbncrxQbQCEjq378JQ9wScG.png',
    originCountry: 'United States',
    latestCeremonyDate: '2026-02-16',
  ),
  Award(
    id: 40,
    name: 'Berlin International Film Festival',
    assetPath: 'assets/awards/BerlinInternational.webp',
    logoPath: '/lmb5ovn73Xk25r0jlzzsce7VqAT.png',
    originCountry: 'Germany',
    latestCeremonyDate: '2026-02-21',
  ),
  Award(
    id: 22,
    name: 'César Awards',
    assetPath: 'assets/awards/CésarAwards.webp',
    logoPath: '/qPEnFPcupa966kLjrKgaMJQS3bx.svg',
    originCountry: 'France',
    latestCeremonyDate: '2026-02-26',
  ),
  Award(
    id: 33,
    name: 'Writers Guild Awards',
    assetPath: 'assets/awards/WritersGuildAwards.webp',
    logoPath: '/20c1g9jQfQTTvVoDgjX9g1vOs1p.png',
    originCountry: 'United States',
    latestCeremonyDate: '2026-03-08',
  ),
  Award(
    id: 13,
    name: 'Japan Academy Film Prize',
    assetPath: 'assets/awards/TheJapanAcademyFilm.webp',
    logoPath: '/rwR6QnXySV3Du0VfNa8zTDL6qqn.png',
    originCountry: 'Japan',
    latestCeremonyDate: '2026-03-13',
  ),
  Award(
    id: 29,
    name: 'Satellite Awards',
    assetPath: 'assets/awards/SatelliteAwards.webp',
    logoPath: '/6H2TMAuthoKd9B74LDr3BboA1FA.png',
    originCountry: 'United States',
    latestCeremonyDate: '2026-03-10',
  ),
  Award(
    id: 37,
    name: 'National Board of Review Awards',
    assetPath: 'assets/awards/TheNationalBoardofReviewofMotionPicture.webp',
    logoPath: '/rp3iaR19tZjAD589raB02BZHPNU.png',
    originCountry: 'United States',
    latestCeremonyDate: '2025-12-03',
  ),
  Award(
    id: 27,
    name: 'Actor Awards',
    assetPath: 'assets/awards/ActorAwards.webp',
    logoPath: '/wt47GBXuRVBbXynv511LpXZLnX6.png',
    originCountry: 'United States',
    latestCeremonyDate: '2026-03-01',
  ),
  Award(
    id: 14,
    name: 'Mainichi Film Awards',
    assetPath: 'assets/awards/MainichiFilmAwards.webp',
    originCountry: 'Japan',
    latestCeremonyDate: '2026-02-01',
  ),
];
