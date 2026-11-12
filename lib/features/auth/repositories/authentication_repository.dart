
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakeway/core/storage/preferences_service.dart';
class AuthenticationRepository {
  AuthenticationRepository({
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
  }) : supabase = client ?? Supabase.instance.client,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final SupabaseClient supabase;
  final GoogleSignIn _googleSignIn;

  // Replace with your Google Web OAuth Client ID.
  static const String webClientId = '740358344602-vr4nr4ev6in3c6thdtb71ta4hno9hfqn.apps.googleusercontent.com';

  // Initialize once during application startup.
  Future<void> initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId: webClientId,
    );
  }

  // GOOGLE LOGIN / REGISTRATION
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();

      final googleAuthentication = googleUser.authentication;
      final idToken = googleAuthentication.idToken;

      if (idToken == null) {
        return {
          'status': 401,
          'message': 'Google did not provide an ID token.',
        };
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = response.user;

      if (user == null || response.session == null) {
        return {
          'status': 401,
          'message': 'Google authentication failed.',
        };
      }
      
      await PreferencesService.saveUserName(user.userMetadata?['full_name'] ?? 'Unknown User');
      return {
        'status': 200,
        'message': 'Google login successful.',
        'user_id': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'],
        'avatar': user.userMetadata?['avatar_url'],
      };
    } on GoogleSignInException catch (e) {
      return {
        'status': 400,
        'message': e.description ?? 'Google sign-in was cancelled or failed.',
      };
    } on AuthException catch (e) {
      return {
        'status': 401,
        'message': e.message,
      };
    } catch (e) {
      return {
        'status': 500,
        'message': 'Unexpected authentication error: $e',
      };
    }
  }

  // LOGOUT
  Future<void> logoutAccount() async {
    await supabase.auth.signOut();
    await _googleSignIn.signOut();
  }

  // CURRENT AUTHENTICATED USER
  User? get currentUser => supabase.auth.currentUser;

  // CURRENT USER ID
  String? get currentUserId => currentUser?.id;

  String requireCurrentUserId() {
    final userId = currentUserId;

    if (userId == null) {
      throw StateError('Sign in to continue.');
    }

    return userId;
  }

  // AUTHENTICATION STATUS
  bool get isAuthenticated => currentUser != null;
}
