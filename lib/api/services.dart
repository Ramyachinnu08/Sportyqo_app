import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';

/// Thin, typed-enough wrappers over the backend. Everything returns decoded
/// JSON (`Map<String, dynamic>` / `List`) — screens map these into their
/// existing view structures.
class AuthService {
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role, // 'player' | 'coach'
  }) async {
    final res = await ApiClient.post('/auth/register', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
    }) as Map<String, dynamic>;
    await _storeSession(res, role);
    return res;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await ApiClient.post('/auth/login', body: {
      'email': email,
      'password': password,
      'role': role,
    }) as Map<String, dynamic>;
    await _storeSession(res, role);
    return res;
  }

  static Future<void> _storeSession(
      Map<String, dynamic> res, String role) async {
    await TokenStore.save(
      access: res['access_token'] as String,
      refresh: res['refresh_token'] as String,
      userRole: role,
    );
    Session.user = res['user'] as Map<String, dynamic>?;
  }

  /// Restore a session on app start. Returns the user or null.
  static Future<Map<String, dynamic>?> tryRestore() async {
    await TokenStore.load();
    if (!TokenStore.hasSession) return null;
    try {
      final me = await ApiClient.get('/users/me') as Map<String, dynamic>;
      Session.user = me;
      return me;
    } catch (_) {
      return null; // expired / revoked — fall through to Choose Role
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String phone) async =>
      await ApiClient.post('/auth/otp/send', body: {
        'phone': phone,
        'purpose': 'coach_verification',
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> verifyOtp(
          {required String requestId, required String code}) async =>
      await ApiClient.post('/auth/otp/verify', body: {
        'request_id': requestId,
        'code': code,
      }) as Map<String, dynamic>;

  static Future<void> logout() async {
    try {
      if (TokenStore.hasSession) {
        await ApiClient.post('/auth/logout',
            body: {'refresh_token': TokenStore.refreshToken});
      }
    } catch (_) {
      // best-effort — clear locally regardless
    }
    await TokenStore.clear();
    Session.user = null;
  }
}

class UserService {
  static Future<Map<String, dynamic>> me() async {
    final me = await ApiClient.get('/users/me') as Map<String, dynamic>;
    Session.user = me;
    return me;
  }

  /// PATCH /users/me — JSON-less multipart form (works with or without avatar).
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? dob, // YYYY-MM-DD
    String? rolePosition,
    String? team,
    String? location,
    String? school,
    String? bio,
    http.MultipartFile? avatar,
  }) async =>
      await ApiClient.multipart('PATCH', '/users/me', fields: {
        if (fullName != null) 'full_name': fullName,
        if (dob != null) 'dob': dob,
        if (rolePosition != null) 'role_position': rolePosition,
        if (team != null) 'team': team,
        if (location != null) 'location': location,
        if (school != null) 'school': school,
        if (bio != null) 'bio': bio,
      }, files: [
        if (avatar != null) avatar,
      ]) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> selectSport({
    required String sport,
    String? subRole,
  }) async =>
      await ApiClient.post('/users/me/sport', body: {
        'sport': sport,
        if (subRole != null) 'sub_role': subRole,
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> settings() async =>
      await ApiClient.get('/users/me/settings') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> updateSettings(
          Map<String, dynamic> patch) async =>
      await ApiClient.patch('/users/me/settings', body: patch)
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> publicProfile(String userId) async =>
      await ApiClient.get('/users/$userId/profile') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> track(String userId) async =>
      await ApiClient.post('/users/$userId/track') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> untrack(String userId) async =>
      await ApiClient.delete('/users/$userId/track') as Map<String, dynamic>;
}

class PlayerService {
  static Future<Map<String, dynamic>> dashboard() async =>
      await ApiClient.get('/players/me/dashboard') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> qoScore() async =>
      await ApiClient.get('/players/me/qo-score') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> performance(
          {String period = 'this_season'}) async =>
      await ApiClient.get('/players/me/performance',
          query: {'period': period}) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> matches({int page = 1}) async =>
      await ApiClient.get('/players/me/matches',
          query: {'page': '$page', 'limit': '20'}) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> playbook() async =>
      await ApiClient.get('/players/me/playbook') as Map<String, dynamic>;
}

class CoachService {
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? roleTitle,
    String? academy,
    String? location,
    String? certification,
    int? experienceYears,
    String? sport,
    String? bio,
    http.MultipartFile? avatar,
  }) async =>
      await ApiClient.multipart('PATCH', '/coaches/me', fields: {
        if (fullName != null) 'full_name': fullName,
        if (roleTitle != null) 'role_title': roleTitle,
        if (academy != null) 'academy': academy,
        if (location != null) 'location': location,
        if (certification != null) 'certification': certification,
        if (experienceYears != null) 'experience_years': '$experienceYears',
        if (sport != null) 'sport': sport,
        if (bio != null) 'bio': bio,
      }, files: [
        if (avatar != null) avatar,
      ]) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> dashboard() async =>
      await ApiClient.get('/coaches/me/dashboard') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> playbook() async =>
      await ApiClient.get('/coaches/me/playbook') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> playerDirectory({String? q}) async =>
      await ApiClient.get('/players/directory',
              query: {if (q != null && q.isNotEmpty) 'q': q})
          as Map<String, dynamic>;

  static Future<List<dynamic>> roster() async =>
      (await ApiClient.get('/coaches/me/players')
          as Map<String, dynamic>)['items'] as List<dynamic>;

  static Future<Map<String, dynamic>> removePlayer(String userId) async =>
      await ApiClient.delete('/coaches/me/players/$userId')
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> addPlayer(String playerId) async =>
      await ApiClient.post('/coaches/me/players', body: {'player_id': playerId})
          as Map<String, dynamic>;

  static Future<Map<String, dynamic>> recommend({
    required List<String> playerUserIds,
    String? note,
    double? rating,
  }) async =>
      await ApiClient.post('/recommendations', body: {
        'player_ids': playerUserIds,
        if (note != null && note.isNotEmpty) 'note': note,
        if (rating != null) 'rating': rating,
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> certification() async =>
      await ApiClient.get('/coaches/me/certification') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> submitCertification({
    required String certificationLevel,
    String? issuingBody,
    String? issuedOn, // YYYY-MM-DD
    List<http.MultipartFile> documents = const [],
  }) async =>
      await ApiClient.multipart('POST', '/coaches/me/certification', fields: {
        'certification_level': certificationLevel,
        if (issuingBody != null) 'issuing_body': issuingBody,
        if (issuedOn != null) 'issued_on': issuedOn,
      }, files: documents) as Map<String, dynamic>;
}

class LeagueService {
  static Future<Map<String, dynamic>> create({
    required String name,
    required String cricketType,
    required String gender, // "Men's" | "Women's"
    String? location,
    required List<String> teamNames,
    http.MultipartFile? logo,
  }) async =>
      await ApiClient.multipart('POST', '/leagues', fields: {
        'name': name,
        'cricket_type': cricketType,
        'gender': gender,
        if (location != null) 'location': location,
        'teams_count': '${teamNames.length}',
        'team_names': teamNames.join(','),
      }, files: [
        if (logo != null) logo,
      ]) as Map<String, dynamic>;

  static Future<List<dynamic>> myLeagues() async =>
      (await ApiClient.get('/coaches/me/leagues')
          as Map<String, dynamic>)['items'] as List<dynamic>;

  static Future<Map<String, dynamic>> join(
          {required String leagueCode, required String teamId}) async =>
      await ApiClient.post('/leagues/join', body: {
        'league_code': leagueCode,
        'team_id': teamId,
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> detail(String leagueId) async =>
      await ApiClient.get('/leagues/$leagueId') as Map<String, dynamic>;

  /// Look a league up by its invite code (for the join screen's team picker).
  static Future<Map<String, dynamic>?> findByCode(String code) async {
    // The backend keys join on the code; league detail needs an id, so we
    // resolve via join-preview: fetch code owner path is owner-only, so we
    // simply attempt detail through the code on the join endpoint's error —
    // instead, expose teams through /leagues/{id} once joined. For the picker
    // we call the dedicated lightweight lookup below.
    try {
      return await ApiClient.get('/leagues/by-code/$code')
          as Map<String, dynamic>;
    } on ApiException {
      return null;
    }
  }

  static Future<Map<String, dynamic>> leagueCode(String leagueId) async =>
      await ApiClient.get('/leagues/$leagueId/code') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> matches(String leagueId) async =>
      await ApiClient.get('/leagues/$leagueId/matches') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> createMatch({
    required String leagueId,
    required String teamAId,
    required String teamBId,
    required DateTime startsAt,
    String? venue,
  }) async =>
      await ApiClient.post('/leagues/$leagueId/matches', body: {
        'team_a_id': teamAId,
        'team_b_id': teamBId,
        'starts_at': startsAt.toUtc().toIso8601String(),
        if (venue != null) 'venue': venue,
      }) as Map<String, dynamic>;

  static Future<List<dynamic>> players(String leagueId,
          {String? teamId}) async =>
      (await ApiClient.get('/leagues/$leagueId/players',
              query: teamId == null ? null : {'team_id': teamId})
          as Map<String, dynamic>)['items'] as List<dynamic>;

  static Future<void> exit(String leagueId) async =>
      await ApiClient.delete('/leagues/$leagueId/membership');

  static Future<Map<String, dynamic>> submitPoints({
    required String matchId,
    required String result, // team_a_won | team_b_won | draw | abandoned
    required List<Map<String, dynamic>> playerStats,
    required String idempotencyKey,
  }) async =>
      await ApiClient.postWithHeaders('/matches/$matchId/points',
          body: {'result': result, 'player_stats': playerStats},
          extraHeaders: {'Idempotency-Key': idempotencyKey})
      as Map<String, dynamic>;
}

class FeedService {
  static Future<Map<String, dynamic>> feed(
          {String tab = 'all', String? q, int page = 1}) async =>
      await ApiClient.get('/feed', query: {
        'tab': tab,
        'page': '$page',
        'limit': '20',
        if (q != null && q.isNotEmpty) 'q': q,
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> createPost({
    required String content,
    String? category,
    List<http.MultipartFile> media = const [],
  }) async =>
      await ApiClient.multipart('POST', '/posts', fields: {
        'content': content,
        if (category != null) 'category': category,
      }, files: media) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> like(String postId) async =>
      await ApiClient.post('/posts/$postId/like') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> unlike(String postId) async =>
      await ApiClient.delete('/posts/$postId/like') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> bookmark(String postId) async =>
      await ApiClient.post('/posts/$postId/bookmark') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> unbookmark(String postId) async =>
      await ApiClient.delete('/posts/$postId/bookmark') as Map<String, dynamic>;

  static Future<Map<String, dynamic>> comments(String postId,
          {int page = 1}) async =>
      await ApiClient.get('/posts/$postId/comments',
          query: {'page': '$page'}) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> addComment(
          {required String postId,
          required String body,
          String? parentId}) async =>
      await ApiClient.post('/posts/$postId/comments', body: {
        'body': body,
        if (parentId != null) 'parent_id': parentId,
      }) as Map<String, dynamic>;

  static Future<Map<String, dynamic>> share(String postId) async =>
      await ApiClient.post('/posts/$postId/share') as Map<String, dynamic>;
}

class NotificationService {
  static Future<Map<String, dynamic>> list({int page = 1}) async =>
      await ApiClient.get('/notifications',
          query: {'page': '$page', 'limit': '30'}) as Map<String, dynamic>;

  static Future<void> markRead(String id) async =>
      await ApiClient.post('/notifications/$id/read');

  static Future<void> markAllRead() async =>
      await ApiClient.post('/notifications/read-all');
}

class ConfigService {
  static Future<List<dynamic>> cardTiers() async =>
      (await ApiClient.get('/config/card-tiers')
          as Map<String, dynamic>)['tiers'] as List<dynamic>;

  static Future<List<dynamic>> cricketTypes() async =>
      (await ApiClient.get('/config/cricket-types')
          as Map<String, dynamic>)['types'] as List<dynamic>;
}
