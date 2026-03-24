import 'package:flutter/material.dart';
import 'app_error.dart';

class ErrorService extends ChangeNotifier {
  static final ErrorService instance = ErrorService._internal();
  ErrorService._internal();

  AppError? _currentError;
  AppError? get currentError => _currentError;

  void showError(AppError error) {
    _currentError = error;
    notifyListeners();
  }

  void clearError() {
    _currentError = null;
    notifyListeners();
  }
}
