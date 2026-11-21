import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Low-level HTTP client with JWT token management.
/// The token is persisted to SharedPreferences so it survives app restarts.
class ApiClient {
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';

  final String baseUrl;
  String? _accessToken;
  String? _userRole;

  ApiClient({required this.baseUrl});

  /// `true` while the last request failed due to a network/server error.
  /// Cleared automatically on the next successful response.
  final ValueNotifier<bool> connectivityError = ValueNotifier(false);

  String? get userRole => _userRole;

  Future<void> setUserRole(String role) async {
    _userRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
  }

  // --- Token management ---

  /// Persists the token in memory and to disk (remember me = true).
  Future<void> setToken(String accessToken) async {
    _accessToken = accessToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.remove('session_only');
  }

  /// Clears the token and role from memory and from disk.
  Future<void> clearToken() async {
    _accessToken = null;
    _userRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }

  /// Restores a previously persisted token and role from disk.
  /// Call once at app startup before any API requests are made.
  Future<void> restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
    _userRole = prefs.getString(_roleKey);
  }

  bool get isLoggedIn => _accessToken != null;

  String? get token => _accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // --- HTTP methods ---

  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? queryParams}) async {
    return _guard(() async {
      final response = await http.get(_buildUri(path, queryParams), headers: _headers);
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    return _guard(() async {
      final response = await http.post(
        _buildUri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body}) async {
    return _guard(() async {
      final response = await http.put(
        _buildUri(path),
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> putList(String path, List<dynamic> body) async {
    return _guard(() async {
      final response = await http.put(
        _buildUri(path),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    });
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _guard(() async {
      final response = await http.delete(_buildUri(path), headers: _headers);
      return _handleResponse(response);
    });
  }

  /// Runs [call], flipping [connectivityError] on network failures.
  Future<Map<String, dynamic>> _guard(
      Future<Map<String, dynamic>> Function() call) async {
    try {
      final result = await call();
      connectivityError.value = false;
      return result;
    } on ApiException catch (e) {
      // Surface server-side failures (5xx) as a connectivity-style error so
      // the user gets the full-screen "try again" instead of a cryptic dialog.
      if (e.statusCode >= 500 || e.statusCode == 0) {
        connectivityError.value = true;
      }
      rethrow;
    } on TimeoutException {
      connectivityError.value = true;
      rethrow;
    } on http.ClientException {
      connectivityError.value = true;
      rethrow;
    } catch (_) {
      // Any unexpected transport-level failure is treated as "no connection".
      connectivityError.value = true;
      rethrow;
    }
  }

  // --- Health check ---

  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/api/health');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --- Helpers ---

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return {};
      throw ApiException(statusCode: response.statusCode, message: 'Request failed');
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: response.statusCode >= 500
            ? 'Server error. Please try again.'
            : 'Unexpected response from server.',
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    final message = body['message'] as String? ?? 'Request failed';
    throw ApiException(statusCode: response.statusCode, message: message);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}
