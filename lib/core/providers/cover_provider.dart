import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoverNotifier extends StateNotifier<String?> {
  static const _key = 'profile_cover_url';

  CoverNotifier() : super(null) {
    _load();
  }

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

final coverProvider = StateNotifierProvider<CoverNotifier, String?>(
  (ref) => CoverNotifier(),
);
