import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  String? token;
  String? userId;
  String? name;
  String? email;
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
      this.email = data['email'] ?? email; // Update the class field
      await _api.saveToken(token!);
      await _api.saveUserId(userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name!);
      await prefs.setString('email', this.email!);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
      this.email = data['email'] ?? email;
      await _api.saveToken(token!);
      await _api.saveUserId(userId!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name!);
      await prefs.setString('email', this.email!);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
    email = prefs.getString('email');
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('email');
    token = null;
    userId = null;
    name = null;
    email = null;
    notifyListeners();
  }

  bool get isLoggedIn => token != null;
}