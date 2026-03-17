import 'package:flutter/material.dart';

class AwardCeremony {
  final String id;
  final String name;
  final String edition;      // e.g. "97th Edition"
  final String dateLabel;    // e.g. "March 2, 2025"
  final int eligibleYear;    // release year of eligible works
  final Color accentColor;
  final String emoji;
  final String mediaType;    // 'movie', 'tv', or 'both'
  final String description;

  const AwardCeremony({
    required this.id,
    required this.name,
    required this.edition,
    required this.dateLabel,
    required this.eligibleYear,
    required this.accentColor,
    required this.emoji,
    required this.mediaType,
    required this.description,
  });
}

/// Static list of major award ceremonies — ordered by prestige / recency.
const List<AwardCeremony> kAwardCeremonies = [
  AwardCeremony(
    id: 'oscars',
    name: 'Academy Awards',
    edition: '97th Edition',
    dateLabel: 'March 2, 2025',
    eligibleYear: 2024,
    accentColor: Color(0xFFFFD700),
    emoji: '🏆',
    mediaType: 'movie',
    description: 'The most prestigious film awards in the world',
  ),
  AwardCeremony(
    id: 'golden_globe',
    name: 'Golden Globe Awards',
    edition: '82nd Edition',
    dateLabel: 'January 5, 2025',
    eligibleYear: 2024,
    accentColor: Color(0xFFFFC107),
    emoji: '🌐',
    mediaType: 'both',
    description: 'Celebrating the best in film and television',
  ),
  AwardCeremony(
    id: 'bafta',
    name: 'BAFTA Film Awards',
    edition: '78th Edition',
    dateLabel: 'February 16, 2025',
    eligibleYear: 2024,
    accentColor: Color(0xFFE53935),
    emoji: '🎭',
    mediaType: 'movie',
    description: 'British Academy of Film and Television Arts',
  ),
  AwardCeremony(
    id: 'emmys',
    name: 'Emmy Awards',
    edition: '76th Edition',
    dateLabel: 'September 22, 2024',
    eligibleYear: 2023,
    accentColor: Color(0xFF1976D2),
    emoji: '📺',
    mediaType: 'tv',
    description: 'Recognizing excellence in the television industry',
  ),
  AwardCeremony(
    id: 'sag',
    name: 'SAG Awards',
    edition: '31st Edition',
    dateLabel: 'February 23, 2025',
    eligibleYear: 2024,
    accentColor: Color(0xFF00897B),
    emoji: '🎬',
    mediaType: 'both',
    description: 'Screen Actors Guild — voted by actors, for actors',
  ),
  AwardCeremony(
    id: 'critics_choice',
    name: "Critics' Choice Awards",
    edition: '30th Edition',
    dateLabel: 'February 7, 2025',
    eligibleYear: 2024,
    accentColor: Color(0xFF8E24AA),
    emoji: '✍️',
    mediaType: 'both',
    description: 'Voted by the Broadcast Film Critics Association',
  ),
  AwardCeremony(
    id: 'cannes',
    name: 'Cannes Film Festival',
    edition: '77th Edition',
    dateLabel: 'May 14–25, 2024',
    eligibleYear: 2024,
    accentColor: Color(0xFFFF6F00),
    emoji: '🌴',
    mediaType: 'movie',
    description: 'The world\'s most prestigious film festival',
  ),
  AwardCeremony(
    id: 'sundance',
    name: 'Sundance Film Festival',
    edition: '2025 Edition',
    dateLabel: 'January 23–February 2, 2025',
    eligibleYear: 2024,
    accentColor: Color(0xFFFF5722),
    emoji: '🎞️',
    mediaType: 'movie',
    description: 'Launching ground for independent cinema',
  ),
];
