import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_list_item.dart';
import '../models/person_preference.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  User? get currentUser => client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.rateme://login-callback/',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Calls the SECURITY DEFINER function which deletes user_lists rows
      // and the auth.users record in one transaction.
      await client.rpc('delete_user');
    } finally {
      // Always sign out locally so the app reflects the deleted state,
      // even if the RPC partially failed.
      await client.auth.signOut();
    }
  }

  // ── User Lists ────────────────────────────────────────────────────────────

  Future<List<UserListItem>> fetchUserLists() async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('user_lists')
        .select()
        .eq('user_id', user.id)
        .order('added_at', ascending: false);

    return (data as List)
        .map((row) => UserListItem.fromJson(row))
        .toList();
  }

  Future<void> addToList(UserListItem item) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('user_lists').upsert({
      'user_id': user.id,
      'media_id': item.mediaId,
      'title': item.title,
      'poster_path': item.posterPath,
      'release_date': item.releaseDate,
      'vote_average': item.voteAverage,
      'list_type': item.listType.name,
      'media_type': item.mediaType,
      'added_at': item.addedAt.toIso8601String(),
      'user_rating': item.userRating,
      'runtime': item.runtime,
      'genre_ids': item.genreIds.isEmpty ? null : item.genreIds,
    }, onConflict: 'user_id,media_id,list_type');
  }

  Future<void> removeFromList(ListType type, int mediaId) async {
    final user = currentUser;
    if (user == null) return;

    await client
        .from('user_lists')
        .delete()
        .eq('user_id', user.id)
        .eq('media_id', mediaId)
        .eq('list_type', type.name);
  }

  Future<void> updateRating(int mediaId, double rating) async {
    final user = currentUser;
    if (user == null) return;

    await client
        .from('user_lists')
        .update({'user_rating': rating})
        .eq('user_id', user.id)
        .eq('media_id', mediaId);
  }

  Future<void> updateGenreIds(int mediaId, List<int> genreIds) async {
    final user = currentUser;
    if (user == null) return;

    await client
        .from('user_lists')
        .update({'genre_ids': genreIds})
        .eq('user_id', user.id)
        .eq('media_id', mediaId);
  }

  // ── User Preferences (onboarding) ─────────────────────────────────────────

  Future<List<PersonPreference>> fetchPreferences() async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('user_preferences')
        .select()
        .eq('user_id', user.id)
        .order('added_at');

    return (data as List)
        .map((row) => PersonPreference.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePreferences(List<PersonPreference> prefs) async {
    final user = currentUser;
    if (user == null) return;

    final rows = prefs
        .map((p) => {
              'user_id': user.id,
              ...p.toJson(),
            })
        .toList();

    await client
        .from('user_preferences')
        .upsert(rows, onConflict: 'user_id,person_id,person_type');
  }

  Future<void> clearPreferences() async {
    final user = currentUser;
    if (user == null) return;

    await client
        .from('user_preferences')
        .delete()
        .eq('user_id', user.id);
  }
}

final supabaseService = SupabaseService();
