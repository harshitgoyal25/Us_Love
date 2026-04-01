import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'app_error.dart';
import 'error_service.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.httpBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          final appError = _mapDioError(e);
          ErrorService.instance.showError(appError);
          return handler.next(e);
        },
      ),
    );
  }

  AppError _mapDioError(DioException e) {
    final requestPath = e.requestOptions.path.toLowerCase();
    final isLoginRequest = requestPath.contains('/api/auth/login');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return AppError.timeout();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.badCertificate) {
      return AppError(
        type: AppErrorType.network,
        title: 'Network Error',
        message:
            'Could not reach the server. Please check your internet or if the server is running.',
        technicalDetails: e.message,
      );
    }
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      String? backendMessage;
      if (responseData is Map<String, dynamic>) {
        final message = responseData['message'];
        final error = responseData['error'];
        if (message is String && message.trim().isNotEmpty) {
          backendMessage = message;
        } else if (error is String && error.trim().isNotEmpty) {
          backendMessage = error;
        }
      }

      final normalizedMessage = backendMessage?.toLowerCase() ?? '';
      final looksLikeCredentialFailure =
          normalizedMessage.contains('invalid email') ||
          normalizedMessage.contains('invalid password') ||
          normalizedMessage.contains('invalid credential') ||
          normalizedMessage.contains('credentials were incorrect') ||
          normalizedMessage.contains('bad credentials') ||
          normalizedMessage.contains('unauthorized');

      if (isLoginRequest &&
          (statusCode == 500 || statusCode == 400 || statusCode == 404)) {
        return AppError.auth('Invalid email or password.');
      }

      if (looksLikeCredentialFailure) {
        return AppError.auth('Invalid email or password.');
      }

      if (statusCode == 401 || statusCode == 403) {
        return AppError.auth(backendMessage ?? 'Invalid email or password.');
      }
      if (statusCode == 409) {
        return AppError.client(
          backendMessage ??
              'Email already exists. Please sign in or use another email.',
        );
      }
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return AppError.client(
          backendMessage ?? 'Please check your input and try again.',
        );
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
    String name,
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createRoom(String userId) async {
    final token = await getToken();
    final response = await _dio.post(
      '/api/rooms/create',
      options: Options(
        headers: {'X-User-Id': userId, 'Authorization': 'Bearer $token'},
      ),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> joinRoom(String code, String userId) async {
    final token = await getToken();
    final response = await _dio.post(
      '/api/rooms/join',
      data: {'code': code},
      options: Options(
        headers: {'X-User-Id': userId, 'Authorization': 'Bearer $token'},
      ),
    );
    return response.data;
  }
}
