import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

/// Where the SportyQo backend lives.
///
/// Override per environment:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/v1
/// (Android emulators can't see the host's `localhost`, hence 10.0.2.2.)
class ApiConfig {
  static const _fromEnv = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/v1';
    }
    return 'http://localhost:8000/v1';
  }

  static String get wsUrl =>
      '${baseUrl.replaceFirst('http', 'ws')}/ws';
}

/// Persists the JWT pair. The refresh token ROTATES on every refresh —
/// always store the newest one the server returns.
class TokenStore {
  static const _kAccess = 'sportyqo_access_token';
  static const _kRefresh = 'sportyqo_refresh_token';
  static const _kRole = 'sportyqo_role';

  static String? accessToken;
  static String? refreshToken;
  static String? role;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_kAccess);
    refreshToken = prefs.getString(_kRefresh);
    role = prefs.getString(_kRole);
  }

  static Future<void> save(
      {required String access, required String refresh, String? userRole}) async {
    accessToken = access;
    refreshToken = refresh;
    if (userRole != null) role = userRole;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
    if (userRole != null) await prefs.setString(_kRole, userRole);
  }

  static Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kRole);
  }

  static bool get hasSession =>
      refreshToken != null && refreshToken!.isNotEmpty;
}

/// In-memory cache of the logged-in user (from register/login/GET /users/me).
class Session {
  static Map<String, dynamic>? user;

  static String get userId => (user?['id'] ?? '') as String;
  static String get fullName => (user?['full_name'] ?? '') as String;
  static String get firstName =>
      fullName.isEmpty ? '' : fullName.split(' ').first;
  static String? get playerId => user?['player_id'] as String?;
  static String? get avatarUrl => user?['avatar_url'] as String?;
  static String get role => (user?['role'] ?? TokenStore.role ?? 'player') as String;
}
