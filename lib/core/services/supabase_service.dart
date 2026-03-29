import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_list_item.dart';
import '../models/custom_list.dart';
import '../models/user_preference.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

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
      await client.rpc('delete_user');
    } finally {
      await client.auth.signOut();
    }
  }

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

  Future<List<CustomList>> fetchCustomLists() async {
    final user = currentUser;
    if (user == null) return [];
    final row = await client
        .from('custom_lists')
        .select('data')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return [];
    return (row['data'] as List<dynamic>)
        .map((e) => CustomList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCustomLists(List<CustomList> lists) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('custom_lists').upsert({
      'user_id': user.id,
      'data': lists.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  Future<List<UserPreference>> fetchUserPreferences() async {
    final user = currentUser;
    if (user == null) return [];
    final data = await client
        .from('user_preferences')
        .select()
        .eq('user_id', user.id)
        .order('added_at', ascending: false);
    return (data as List)
        .map((row) => UserPreference.fromJson(row))
        .toList();
  }

  Future<void> addPreference(UserPreference pref) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('user_preferences').upsert({
      'user_id': user.id,
      'person_id': pref.personId,
      'person_name': pref.personName,
      'person_type': pref.personType,
      'profile_path': pref.profilePath,
      'added_at': pref.addedAt.toIso8601String(),
    }, onConflict: 'user_id,person_id,person_type');
  }

  Future<void> removePreference(int personId, String personType) async {
    final user = currentUser;
    if (user == null) return;
    await client
        .from('user_preferences')
        .delete()
        .eq('user_id', user.id)
        .eq('person_id', personId)
        .eq('person_type', personType);
  }
}

final supabaseService = SupabaseService();
