import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:5081',
  );

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await post('Auth/revoke-token', {'refreshToken': refreshToken});
      } catch (_) {}
    }

    await clearToken();
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAdministrator') ?? false;
  }

  static Future<String> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') ?? '';
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['role'] != 'Pharmacist') {
        throw Exception(
          'Access denied. Only pharmacists can access this application.',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['accessToken']);
      await prefs.setString('role', data['role']);
      await prefs.setBool('isAdministrator', data['isAdministrator'] ?? false);
      await prefs.setInt('userId', data['userId']);
      await prefs.setString('refresh_token', data['refreshToken']);
      await prefs.setInt('pharmacyId', data['pharmacyId'] ?? 0);
      await prefs.setString('firstName', data['firstName'] ?? '');
      await prefs.setString('lastName', data['lastName'] ?? '');
      if (data['cityId'] != null) {
        await prefs.setInt('cityId', data['cityId'] as int);
      }

      return data;
    } else {
      throw Exception('Invalid username or password.');
    }
  }

  static Future<dynamic> get(String endpoint) async {
    var headers = await getHeaders();
    var response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await getHeaders();
      response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.body.isNotEmpty) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error: ${response.statusCode}');
      }
      throw Exception('Error: ${response.statusCode}');
    }
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    var headers = await getHeaders();
    var response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await getHeaders();
      response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 204) {
      return null;
    } else {
      if (response.body.isEmpty) {
       throw Exception('Error: ${response.statusCode}');
      }
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error: ${response.statusCode}');
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    var headers = await getHeaders();
    var response = await http.put(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await getHeaders();
      response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Error: ${response.statusCode}');
    }
  }

  static Future<void> delete(String endpoint) async {
    var headers = await getHeaders();
    var response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      await _refreshToken();
      headers = await getHeaders();
      response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.body.isNotEmpty) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error: ${response.statusCode}');
      }
      throw Exception('Error: ${response.statusCode}');
    }
  }

  static Future<void> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await http.post(
      Uri.parse('$baseUrl/Auth/refresh-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('jwt_token', data['accessToken']);
      await prefs.setString('refresh_token', data['refreshToken']);
    } else {
      await prefs.clear();
      throw Exception('Session expired');
    }
  }

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    List<int> bytes,
    String filename,
  ) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/$endpoint');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.body.isNotEmpty) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Upload failed: ${response.statusCode}',
      );
    }
    throw Exception('Upload failed: ${response.statusCode}');
  }
}
