import 'app_config.dart';

class ApiConfig {
  // Private constructor
  ApiConfig._();

  // Base URL
  static String get baseUrl => AppConfig.apiBaseUrl;

  // Timeout
  static Duration get timeout => Duration(milliseconds: AppConfig.apiTimeout);

  // API Endpoints
  static const String projects = '/api/v1/projects';
  static const String health = '/api/health';
  static const String adminReset = '/api/admin/reset';

  // Projects endpoints
  static String projectById(String id) => '$projects/$id';
  static String projectUpload(String id) => '$projects/$id/upload';
  static String projectQuery(String id) => '$projects/$id/query';
  static String projectSummary(String id) => '$projects/$id/summary';

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };


  // Response status codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int noContentCode = 204;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int serverErrorCode = 500;
}