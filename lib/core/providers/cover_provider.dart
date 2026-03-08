import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';

class CoverNotifier extends StateNotifier<String?> {
  final String? _userId;

  CoverNotifier(this._userId) : super(null) {
    _load();
  }

  String get _key =>
      _userId != null ? 'profile_cover_url_$_userId' : 'profile_cover_url_guest';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setCover(String url) async {
    state = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
}

final coverProvider = StateNotifierProvider<CoverNotifier, String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return CoverNotifier(user?.id);
});
