class AppConstants {
 
  static const String baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:5081', 
); 
  
  static const String keyAccessToken  = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId       = 'user_id';
  static const String keyFirstName    = 'first_name';
  static const String keyLastName     = 'last_name';
  static const String keyEmail        = 'email';
  static const String keyRole         = 'role';
  static const String keyCityId       = 'city_id';

  static const int defaultPageSize = 10;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}