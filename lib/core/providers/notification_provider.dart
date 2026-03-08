import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tmdb_providers.dart';

class ReadNotifNotifier extends StateNotifier<Set<int>> {
  static const _key = 'read_notification_ids';

  ReadNotifNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    state = ids.map(int.parse).toSet();
  }

  Future<void> markRead(int id) async {
    state = {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((e) => e.toString()).toList());
  }

  Future<void> markAllRead(Iterable<int> ids) async {
    state = {...state, ...ids};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.map((e) => e.toString()).toList());
  }
}

final readNotifProvider = StateNotifierProvider<ReadNotifNotifier, Set<int>>(
  (ref) => ReadNotifNotifier(),
);

/// Derives the unread count from live TMDB data (now playing + airing today).
final unreadNotifCountProvider = Provider<int>((ref) {
  final readIds = ref.watch(readNotifProvider);
  final nowPlaying = ref.watch(nowPlayingProvider);
  final airingToday = ref.watch(airingTodayProvider);

  int count = 0;
  nowPlaying.whenData(
    (movies) => count += movies.take(5).where((m) => !readIds.contains(m.id)).length,
  );
  airingToday.whenData(
    (shows) => count += shows.take(5).where((m) => !readIds.contains(m.id)).length,
  );
  return count;
});
