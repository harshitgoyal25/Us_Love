import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'app_error.dart';
import 'error_service.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.httpBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        final appError = _mapDioError(e);
        ErrorService.instance.showError(appError);
        return handler.next(e);
      },
    ));
  }

  AppError _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppError.timeout();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.badCertificate) {
      return AppError(
        type: AppErrorType.network,
        title: 'Network Error',
        message: 'Could not reach the server. Please check your internet or if the server is running.',
        technicalDetails: e.message,
      );
    }
    if (e.response != null) {
      if (e.response!.statusCode == 401 || e.response!.statusCode == 403) {
        return AppError.auth();
      }
      return AppError.server();
    }
    return AppError.unknown(e.message);
  }

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