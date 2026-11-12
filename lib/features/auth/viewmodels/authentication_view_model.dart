import 'package:flutter/material.dart';
import 'package:wakeway/features/auth/repositories/authentication_repository.dart';

class AuthenticationViewModel extends ChangeNotifier {
  AuthenticationViewModel({AuthenticationRepository? authRepository})
    : _authRepository = authRepository ?? AuthenticationRepository();

  final AuthenticationRepository _authRepository;

  bool _isLoading = false;
  Map<String, dynamic>? _errorMessage;

  bool get isLoading => _isLoading;

  Map<String, dynamic>? get errorMessage => _errorMessage;

  String? get currentUserId => _authRepository.currentUserId;

  AuthenticationRepository get authenticationRepository => _authRepository;

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final result = await _authRepository.loginWithGoogle();

      if (result['status'] != 200) {
        _setErrorMessage(result);
        return false;
      }

      return true;
    } catch (e) {
      _setErrorMessage({
        'status': 500,
        'message': 'Could not authenticate: $e',
      });

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authRepository.logoutAccount();
    _setErrorMessage(null);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(Map<String, dynamic>? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
