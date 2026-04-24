import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

class ApiService {
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAccessToken);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    var headers = await _headers();
    var response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await _headers();
      response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/$endpoint'),
        headers: headers,
      );
    }

    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {bool auth = true}) async {
    var headers = await _headers(auth: auth);
    var response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && auth) {
      await _refreshToken();
      headers = await _headers();
      response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    var headers = await _headers();
    var response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await _headers();
      response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    return _handleResponse(response);
  }

  static Future<void> delete(String endpoint) async {
    var headers = await _headers();
    var response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await _headers();
      response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/$endpoint'),
        headers: headers,
      );
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw AppException('Error: ${response.statusCode}', statusCode: response.statusCode);
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    if (response.statusCode == 401) throw const UnauthorizedException();

    try {
      final error = jsonDecode(response.body);
      throw AppException(
        error['message'] ?? 'Error ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error ${response.statusCode}', statusCode: response.statusCode);
    }
  }

  static Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
    if (refreshToken == null) throw const UnauthorizedException();

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/Auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString(AppConstants.keyAccessToken, data['accessToken']);
      await prefs.setString(AppConstants.keyRefreshToken, data['refreshToken']);
    } else {
      await prefs.clear();
      throw const UnauthorizedException();
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}