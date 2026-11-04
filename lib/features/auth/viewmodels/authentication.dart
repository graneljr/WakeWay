import 'package:flutter/material.dart';
import 'package:wakeway/features/auth/models/user.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';

class Authentication extends ChangeNotifier {
  final AuthenticationRepository _authRepository = AuthenticationRepository();
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;
 Map<String, dynamic>? _errorMessage;

  // 2. Public Getters (Exposed to the View layer safely)
  String get name => _name;
  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get errorMessage => _errorMessage;

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

  Future<void> registerAccount() async {
    // Basic Client-side Validation Checks
    if (_name.isEmpty || _email.isEmpty || _password.isEmpty) {
      _setErrorMessage({'status': 400, 'message': 'Please fill out all required fields.'});
      return;
    }

    if (_password.length < 6) {
      _setErrorMessage({'status': 400, 'message': 'Password must be at least 6 characters long.'});
      return;
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
      await Future.delayed(const Duration(seconds: 2));

      _clearForm();
    } catch (error) {
      _setErrorMessage({'status': 500, 'message': error.toString()});
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login() async {
    if (_email.isEmpty || _password.isEmpty) {
      _setErrorMessage({'status': 400, 'message': 'Please fill out all required fields.'});
      return;
    }

    _setLoading(true);
    _setErrorMessage(null);

   try {
  _setLoading(true); // Optional: ensure your loading state starts

  // 1. Await the response map (which contains your status and data/message)
  final Map<String, dynamic>?result = await _authRepository.loginAccount(_email, _password);
  await Future.delayed(const Duration(seconds: 2));
  _setErrorMessage(result);
} catch (error) {
  _setErrorMessage({'status': 500, 'message': 'System error: Could not connect to server.'});
} finally {
  _setLoading(false);
}

  }
  // 5. Helper Methods (Internal State Manipulation)
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Forces UI to refresh (e.g., swapping a button with a circular spinner)
  }

  void _setErrorMessage(Map<String, dynamic>? message) {
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
    print("User logged out");
    notifyListeners();
  }
}
