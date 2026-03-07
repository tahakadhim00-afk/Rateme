import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_list_item.dart';

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
}

final supabaseService = SupabaseService();
