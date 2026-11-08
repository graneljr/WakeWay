import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakeway/core/storage/preferences_service.dart';
import 'package:wakeway/features/auth/models/user_model.dart';

class AuthenticationRepository {
  final supabase = Supabase.instance.client;

  // REGISTER
  Future<Map<String, dynamic>?> createAccount(UserModel userModel) async {
    try {
      if (userModel.password == null || userModel.password!.isEmpty) {
        return {'status': 400, 'message': 'Password cannot be empty'};
      }

      final response = await supabase.auth.signUp(
        email: userModel.email,
        password: userModel.password!,
        emailRedirectTo: 'wakeway://login-callback/',
        data: {'name': userModel.name},
      );

      if (response.user == null) {
        return {'status': 400, 'message': 'Registration failed'};
      }

      return {
        'status': 201,
        'message': 'User registered successfully',
        'user_id': response.user!.id,
        'email': response.user!.email,
        'email_confirmation_required': response.session == null,
      };
    } on AuthException catch (e) {
      return {'status': 400, 'message': e.message};
    } catch (e) {
      return {'status': 500, 'message': 'Unexpected system error'};
    }
  }

  // LOGIN
  Future<Map<String, dynamic>?> loginAccount(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null || response.session == null) {
        return {'status': 401, 'message': 'Authentication failed'};
      }
      await PreferencesService.saveUserId(user.id);
      return {
        'status': 200,
        'message': 'Login successful',
        'user_id': user.id,
        'email': user.email,
      };
    } on AuthException catch (e) {
      return {'status': 401, 'message': e.message};
    } catch (e) {
      return {'status': 500, 'message': 'Unexpected system error'};
    }
  }

  // LOGOUT
  Future<void> logoutAccount() async {
    await supabase.auth.signOut();

    await PreferencesService.clearUserId();
  }

  // CURRENT USER
  User? get currentUser => supabase.auth.currentUser;

  // CURRENT USER ID
  String? get currentUserId => currentUser?.id;

  // AUTHENTICATION STATUS
  bool get isAuthenticated => currentUser != null;
}
