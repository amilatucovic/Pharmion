import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await ApiService.post(
      'Auth/login',
      {'username': username, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;

    // Samo pacijenti mogu koristiti mobilnu aplikaciju
    if (data['role'] != 'Patient') {
      throw const AppException('Access denied. This app is for patients only.');
    }

    await _saveSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> request) async {
    final data = await ApiService.post('Auth/register', request, auth: false)
        as Map<String, dynamic>;
    await _saveSession(data);
    return data;
  }

  static Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
  
  if (refreshToken != null && refreshToken.isNotEmpty) {
    try {
      await ApiService.post(
        'Auth/revoke-token',
        {'refreshToken': refreshToken},
      );
    } catch (_) {}
  }
  
  await ApiService.clearSession();
}

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAccessToken) != null;
  }

  static Future<Map<String, String?>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId':    prefs.getInt(AppConstants.keyUserId)?.toString(),
      'firstName': prefs.getString(AppConstants.keyFirstName),
      'lastName':  prefs.getString(AppConstants.keyLastName),
      'email':     prefs.getString(AppConstants.keyEmail),
      'role':      prefs.getString(AppConstants.keyRole),
      'cityId':    prefs.getInt(AppConstants.keyCityId)?.toString(),
    };
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAccessToken, data['accessToken'] ?? '');
    await prefs.setString(AppConstants.keyRefreshToken, data['refreshToken'] ?? '');
    await prefs.setInt(AppConstants.keyUserId, data['userId'] as int? ?? 0);
    await prefs.setString(AppConstants.keyFirstName, data['firstName'] ?? '');
    await prefs.setString(AppConstants.keyLastName, data['lastName'] ?? '');
    await prefs.setString(AppConstants.keyEmail, data['email'] ?? '');
    await prefs.setString(AppConstants.keyRole, data['role'] ?? '');
    if (data['cityId'] != null) {
      await prefs.setInt(AppConstants.keyCityId, data['cityId'] as int);
    }
  }
}