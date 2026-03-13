import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../models/person_preference.dart';
import '../services/supabase_service.dart';
import 'tmdb_providers.dart';

// ── Saved preferences ─────────────────────────────────────────────────────────

final userPreferencesProvider =
    FutureProvider<List<PersonPreference>>((ref) async {
  return supabaseService.fetchPreferences();
});

// ── Onboarding people search ───────────────────────────────────────────────────

final peopleSearchQueryProvider = StateProvider<String>((ref) => '');

final popularPeopleProvider =
    FutureProvider.family<List<PersonResult>, int>((ref, page) async {
  return ref.watch(tmdbServiceProvider).getPopularPeople(page: page);
});

final peopleSearchResultsProvider =
    FutureProvider<List<PersonResult>>((ref) async {
  final query = ref.watch(peopleSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.watch(tmdbServiceProvider).searchPeople(query);
});

// ── Personalized home rows ─────────────────────────────────────────────────────

/// Fetches movies for a single person preference (actor or director).
final personMoviesProvider =
    FutureProvider.family<List<Movie>, PersonPreference>((ref, pref) async {
  final service = ref.watch(tmdbServiceProvider);
  final results = pref.personType == 'director'
      ? await service.discoverByDirector(pref.personId)
      : await service.discoverByActor(pref.personId);
  return results.where((m) => m.voteAverage > 0.0).toList();
});
