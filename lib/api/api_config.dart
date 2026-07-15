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
      return 'https://backendforsportsapp.onrender.com/v1';
    }
    return 'https://backendforsportsapp.onrender.com/v1';
  }

  static String get wsUrl =>
      '${baseUrl.replaceFirst('http', 'ws')}/ws';

  /// Media URLs from the backend are built with the server's BASE_URL,
  /// which in dev defaults to `http://localhost:8000`. A phone or
  /// emulator can't reach the host machine via `localhost`, so rewrite
  /// such URLs to use the same host/port the app already uses for the
  /// API (e.g. 10.0.2.2 on the Android emulator, or your LAN IP when
  /// running with --dart-define=API_BASE_URL=...).
  static String? resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return url;
    final u = Uri.tryParse(url);
    if (u == null || !u.hasScheme) return url;
    const localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
    if (!localHosts.contains(u.host)) return url;
    final api = Uri.parse(baseUrl);
    if (localHosts.contains(api.host) && u.host == api.host) return url;
    return u
        .replace(scheme: api.scheme, host: api.host, port: api.port)
        .toString();
  }
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
