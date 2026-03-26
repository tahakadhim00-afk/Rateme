import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:palette_generator/palette_generator.dart';
import 'auth_provider.dart';

class CoverNotifier extends StateNotifier<String?> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final String? _userId;

  CoverNotifier(this._userId) : super(null) {
    _load();
  }

  String get _key =>
      _userId != null ? 'profile_cover_url_$_userId' : 'profile_cover_url_guest';

  Future<void> _load() async {
    state = await _storage.read(key: _key);
  }

  Future<void> setCover(String url) async {
    state = url;
    await _storage.write(key: _key, value: url);
  }
}

final coverProvider = StateNotifierProvider<CoverNotifier, String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return CoverNotifier(user?.id);
});

/// Extracts the dominant color from the user's profile cover image.
/// Returns null if no cover is set or extraction fails.
final coverColorProvider = FutureProvider<Color?>((ref) async {
  final url = ref.watch(coverProvider);
  if (url == null) return null;
  try {
    final generator = await PaletteGenerator.fromImageProvider(
      NetworkImage(url),
      size: const Size(200, 150),
    );
    return generator.dominantColor?.color;
  } catch (_) {
    return null;
  }
});
