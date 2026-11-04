import 'package:wakeway/core/database/app_database.dart';
import 'package:wakeway/core/security/password_hasher.dart';
import 'package:wakeway/features/auth/models/user.dart';
class   AuthenticationRepository {
   Future<Map<String, dynamic>?> createAccount(UserModel userModel) async {
    try {
      if (userModel.password == null || userModel.password!.isEmpty) {
        return {'status': 400, 'message': 'Password cannot be empty'};
      }
      final passwordHasher = PasswordHasher();
      final hashedPassword = passwordHasher.hashPassword(userModel.password);
      final dataToInsert = {
        'name': userModel.name,
        'email': userModel.email,
        'password': hashedPassword, 
      };

      await SupabaseService.client.from("users").insert(dataToInsert);

      return {'status': 200, 'message': 'User registered successfully'};
    } catch (e) {
      return {'status': 500, 'message': 'Unexpected system error'};
    }
  }

  Future<Map<String, dynamic>?> loginAccount(String email, String password) async {
    try {
      final response = await SupabaseService.client
          .from("users")
          .select()
          .eq("email", email)
          .maybeSingle();

      if (response == null) {
        return {'status': 404, 'message': 'User not found'};
      }

      final userData = response;
      final storedHashedPassword = userData['password'];

      final passwordHasher = PasswordHasher();
      final isPasswordValid =
          passwordHasher.verifyPassword(password, storedHashedPassword);

      if (!isPasswordValid) {
        return {'status': 400, 'message': 'Invalid password'};
      }

      return {'status': 200, 'message': 'Login successful'};
    } catch (e) {
      return {'status': 500, 'message': 'Unexpected system error'};
    }
  }
}
