import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_list_item.dart';
import '../models/custom_list.dart';
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

  Future<void> updateDisplayName(String name) async {
    await client.auth.updateUser(UserAttributes(data: {'full_name': name}));
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

  // ── Custom Lists (cloud sync) ─────────────────────────────────────────────
  // Requires a Supabase table:
  //   create table custom_lists (
  //     user_id uuid references auth.users on delete cascade primary key,
  //     data    jsonb not null default '[]',
  //     updated_at timestamptz not null default now()
  //   );
  //   alter table custom_lists enable row level security;
  //   create policy "own" on custom_lists for all using (auth.uid() = user_id);

  Future<List<CustomList>> fetchCustomLists() async {
    final user = currentUser;
    if (user == null) return [];
    try {
      final row = await client
          .from('custom_lists')
          .select('data')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) return [];
      return (row['data'] as List<dynamic>)
          .map((e) => CustomList.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomLists(List<CustomList> lists) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await client.from('custom_lists').upsert({
        'user_id': user.id,
        'data': lists.map((e) => e.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }
}

final supabaseService = SupabaseService();
