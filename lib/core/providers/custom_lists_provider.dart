import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_list.dart';
import '../models/user_list_item.dart';
import 'auth_provider.dart';

// Key scoped to the user — guests get 'guest', signed-in users get their uid.
String _prefsKey(String? userId) =>
    'custom_lists_v1_${userId ?? 'guest'}';

class CustomListsNotifier extends StateNotifier<List<CustomList>> {
  final String _key;

  CustomListsNotifier(String? userId)
      : _key = _prefsKey(userId),
        super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => CustomList.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> createList(String name) async {
    final list = CustomList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    state = [...state, list];
    await _save();
  }

  Future<void> deleteList(String id) async {
    state = state.where((l) => l.id != id).toList();
    await _save();
  }

  Future<void> renameList(String id, String name) async {
    state = state
        .map((l) => l.id == id ? l.copyWith(name: name.trim()) : l)
        .toList();
    await _save();
  }

  Future<void> addItem(String listId, UserListItem item) async {
    state = state.map((l) {
      if (l.id != listId) return l;
      if (l.items.any((e) => e.mediaId == item.mediaId)) return l;
      return l.copyWith(items: [...l.items, item]);
    }).toList();
    await _save();
  }

  Future<void> removeItem(String listId, int mediaId) async {
    state = state.map((l) {
      if (l.id != listId) return l;
      return l.copyWith(
          items: l.items.where((e) => e.mediaId != mediaId).toList());
    }).toList();
    await _save();
  }

  bool isInList(String listId, int mediaId) {
    final list = state.firstWhere(
      (l) => l.id == listId,
      orElse: () =>
          CustomList(id: '', name: '', createdAt: DateTime.now()),
    );
    return list.items.any((e) => e.mediaId == mediaId);
  }
}

// The provider watches the current user so it re-creates automatically
// whenever the user signs in, signs out, or switches accounts.
final customListsProvider =
    StateNotifierProvider<CustomListsNotifier, List<CustomList>>((ref) {
  final userId = ref.watch(currentUserProvider)?.id;
  return CustomListsNotifier(userId);
});
