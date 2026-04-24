class AppConstants {
  // API
  static const String baseUrl = 'http://10.0.2.2:5081'; // Android emulator
  // static const String baseUrl = 'http://localhost:5081'; // iOS simulator
  

  // Storage keys
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
  static const String keyFirstName    = 'first_name';
  static const String keyLastName     = 'last_name';
  static const String keyEmail        = 'email';
  static const String keyRole         = 'role';
  static const String keyCityId       = 'city_id';

  // Pagination
  static const int defaultPageSize = 10;

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}