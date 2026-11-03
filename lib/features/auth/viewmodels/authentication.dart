import 'package:flutter/material.dart';
import 'package:wakeway/features/auth/models/user.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';

class Authentication extends ChangeNotifier {
  final AuthenticationRepository _authRepository = AuthenticationRepository();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  // 2. Public Getters (Exposed to the View layer safely)
  String get name => _name;
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 3. UI State Setters
  void updateName(String value) {
    _name = value.trim();
    _clearError(); // Clear existing errors when typing begins
  }

  void updateEmail(String value) {
    _email = value.trim();
    _clearError();
  }

  void updatePassword(String value) {
    _password = value;
    _clearError();
  }

  // 4. Core Business Logic (Async Registration)
  Future<bool> registerAccount() async {
    // Basic Client-side Validation Checks
    if (_name.isEmpty || _email.isEmpty || _password.isEmpty) {
      _setErrorMessage('Please fill out all required fields.');
      return false;
    }

    if (_password.length < 6) {
      _setErrorMessage('Password must be at least 6 characters long.');
      return false;
    }

    // Set Loading State
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final userModel = UserModel(
        name: _name,
        email: _email,
        password: _password,
      );
      final result = await _authRepository.createAccount(userModel);
      if (result != 'User registered successfully') {
        _setErrorMessage(
          result ?? 'Unable to create your account. Please try again.',
        );
        return false;
      }

      _clearForm();
      return true;
    } catch (error) {
      _setErrorMessage(error.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 5. Helper Methods (Internal State Manipulation)
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Forces UI to refresh (e.g., swapping a button with a circular spinner)
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _clearForm() {
    _name = '';
    _email = '';
    _password = '';
    notifyListeners();
  }

  // Simulated logout function matching your earlier view snippet
  void logout() {
    _clearForm();
  }
}
