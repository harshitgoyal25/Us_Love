import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.httpBase));

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await _dio.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createRoom(String userId) async {
    final token = await getToken();
    final response = await _dio.post(
      '/api/rooms/create',
      options: Options(headers: {
        'X-User-Id': userId,
        'Authorization': 'Bearer $token',
      }),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> joinRoom(String code, String userId) async {
    final token = await getToken();
    final response = await _dio.post(
      '/api/rooms/join',
      data: {'code': code},
      options: Options(headers: {
        'X-User-Id': userId,
        'Authorization': 'Bearer $token',
      }),
    );
    return response.data;
  }
}