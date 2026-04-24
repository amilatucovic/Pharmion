import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../core/errors/app_exception.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  String? _firstName;
  String? _lastName;
  String? _email;
  int? _userId;
  int? _cityId;
  String? _error;
  bool _loading = false;

  AuthStatus get status    => _status;
  String? get firstName    => _firstName;
  String? get lastName     => _lastName;
  String? get email        => _email;
  int? get userId          => _userId;
  int? get cityId          => _cityId;
  String? get error        => _error;
  bool get loading         => _loading;
  String get fullName      => '$_firstName $_lastName'.trim();
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      final data = await AuthService.getSessionData();
      _setUserData(data);
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AuthService.login(username, password);
      _setUserDataFromResponse(data);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, dynamic> request) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await AuthService.register(request);
      _setUserDataFromResponse(data);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _status = AuthStatus.unauthenticated;
    _firstName = null;
    _lastName = null;
    _email = null;
    _userId = null;
    _cityId = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setUserData(Map<String, String?> data) {
    _userId    = int.tryParse(data['userId'] ?? '');
    _firstName = data['firstName'];
    _lastName  = data['lastName'];
    _email     = data['email'];
    _cityId    = int.tryParse(data['cityId'] ?? '');
  }

  void _setUserDataFromResponse(Map<String, dynamic> data) {
    _userId    = data['userId'] as int?;
    _firstName = data['firstName'] as String?;
    _lastName  = data['lastName'] as String?;
    _email     = data['email'] as String?;
    _cityId    = data['cityId'] as int?;
  }
}