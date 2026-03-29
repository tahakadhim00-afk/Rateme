import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_preference.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

class PreferencesNotifier extends StateNotifier<List<UserPreference>> {
  final Ref _ref;

  PreferencesNotifier(this._ref) : super([]) {
    _ref.listen<bool>(
      isSignedInProvider,
      (_, next) => next ? _load() : _clear(),
      fireImmediately: true,
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await supabaseService.fetchUserPreferences();
      if (mounted) state = prefs;
    } catch (e, st) {
      debugPrint('PreferencesNotifier._load error: $e\n$st');
    }
  }

  void _clear() => state = [];

  bool isFavorite(int personId, String personType) =>
      state.any((p) => p.personId == personId && p.personType == personType);

  Future<void> toggle({
    required int personId,
    required String personName,
    required String personType,
    String? profilePath,
  }) async {
    if (!supabaseService.isSignedIn) return;
    if (isFavorite(personId, personType)) {
      state = state
          .where((p) => !(p.personId == personId && p.personType == personType))
          .toList();
      try {
        await supabaseService.removePreference(personId, personType);
      } catch (e, st) {
        debugPrint('PreferencesNotifier.removePreference error: $e\n$st');
      }
    } else {
      final pref = UserPreference(
        personId: personId,
        personName: personName,
        personType: personType,
        profilePath: profilePath,
        addedAt: DateTime.now(),
      );
      state = [...state, pref];
      try {
        await supabaseService.addPreference(pref);
      } catch (e, st) {
        debugPrint('PreferencesNotifier.addPreference error: $e\n$st');
      }
    }
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, List<UserPreference>>(
  (ref) => PreferencesNotifier(ref),
);

final isFavoritePersonProvider =
    Provider.family<bool, (int, String)>((ref, params) {
  final (personId, personType) = params;
  return ref
      .watch(preferencesProvider)
      .any((p) => p.personId == personId && p.personType == personType);
});
