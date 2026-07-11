import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Error envelope from the backend:
/// { "error": { "code", "message", "field", "request_id" } }
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final String? field;

  ApiException(this.statusCode, this.code, this.message, {this.field});

  @override
  String toString() => message;
}

class ApiClient {
  static Future<void>? _refreshing; // single-flight refresh

  static Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (TokenStore.accessToken != null)
          'Authorization': 'Bearer ${TokenStore.accessToken}',
      };

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    return query == null || query.isEmpty
        ? base
        : base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  // ── public verbs ────────────────────────────────────────────────────────
  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => http.get(_uri(path, query), headers: _headers()));

  static Future<dynamic> post(String path, {Object? body}) =>
      _send(() => http.post(_uri(path),
          headers: _headers(), body: jsonEncode(body ?? {})));

  static Future<dynamic> postWithHeaders(String path,
          {Object? body, required Map<String, String> extraHeaders}) =>
      _send(() => http.post(_uri(path),
          headers: {..._headers(), ...extraHeaders},
          body: jsonEncode(body ?? {})));

  static Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => http.patch(_uri(path),
          headers: _headers(), body: jsonEncode(body ?? {})));

  static Future<dynamic> delete(String path) =>
      _send(() => http.delete(_uri(path), headers: _headers()));

  /// Multipart POST/PATCH — [fields] are form fields, [files] filename→bytes
  /// keyed by the part name (e.g. 'avatar', 'logo', 'media').
  static Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
  }) =>
      _send(() async {
        final req = http.MultipartRequest(method, _uri(path))
          ..headers.addAll(_headers(json: false))
          ..fields.addAll(fields)
          ..files.addAll(files);
        final streamed = await req.send();
        return http.Response.fromStream(streamed);
      });

  // ── core send with auto-refresh ────────────────────────────────────────
  static Future<dynamic> _send(
      Future<http.Response> Function() request) async {
    var response = await request();
    if (response.statusCode == 401 && TokenStore.hasSession) {
      final err = _tryDecodeError(response);
      if (err?.code == 'TOKEN_EXPIRED' || err?.code == 'INVALID_TOKEN') {
        await _refreshTokens();
        response = await request(); // retry once with the new access token
      }
    }
    return _decode(response);
  }

  static Future<void> _refreshTokens() {
    // Concurrent 401s share one refresh call — the token rotates, so a
    // second refresh with the old token would revoke the whole family.
    _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
    return _refreshing!;
  }

  static Future<void> _doRefresh() async {
    final res = await http.post(
      _uri('/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': TokenStore.refreshToken}),
    );
    if (res.statusCode != 200) {
      await TokenStore.clear(); // TOKEN_REUSED / expired → force re-login
      throw _tryDecodeError(res) ??
          ApiException(res.statusCode, 'SESSION_ENDED',
              'Your session ended. Please log in again.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    await TokenStore.save(
      access: body['access_token'] as String,
      refresh: body['refresh_token'] as String, // rotated — keep the new one
    );
  }

  // ── decoding ────────────────────────────────────────────────────────────
  static dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null; // 204s
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw _tryDecodeError(response) ??
        ApiException(response.statusCode, 'HTTP_${response.statusCode}',
            'Something went wrong (${response.statusCode}).');
  }

  static ApiException? _tryDecodeError(http.Response response) {
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final err = body['error'] as Map<String, dynamic>?;
      if (err == null) return null;
      return ApiException(
        response.statusCode,
        (err['code'] ?? 'UNKNOWN') as String,
        (err['message'] ?? 'Something went wrong.') as String,
        field: err['field'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
