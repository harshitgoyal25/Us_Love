import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  String? token;
  String? userId;
  String? name;
  bool isLoading = false;
  String? error;

  Future<bool> register(String userName, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.register(userName, email, password);
      token = data['token'];
      name = data['name'];
      userId = data['userId'];
      await _api.saveToken(token!);
      await _api.saveUserId(userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name!);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Registration failed. Try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final data = await _api.login(email, password);
      token = data['token'];
      name = data['name'];
      userId = data['userId'];
      print('userId saved: $userId');
      await _api.saveToken(token!);
      await _api.saveUserId(userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name!);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('LOGIN ERROR: $e');
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    userId = prefs.getString('userId');
    name = prefs.getString('name');
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('name');
    token = null;
    userId = null;
    name = null;
    notifyListeners();
  }

  bool get isLoggedIn => token != null;
}