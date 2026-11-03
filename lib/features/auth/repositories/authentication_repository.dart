import 'package:wakeway/core/database/app_database.dart';
import 'package:wakeway/core/security/password_hasher.dart';
import 'package:wakeway/features/auth/models/user.dart';
class   AuthenticationRepository {
   Future<String?> createAccount(UserModel userModel) async {
    try {
      if (userModel.password == null || userModel.password!.isEmpty) {
        return 'Password cannot be empty';
      }
      final passwordHasher = PasswordHasher();
      final hashedPassword = passwordHasher.hashPassword(userModel.password);
      final dataToInsert = {
        'name': userModel.name,
        'email': userModel.email,
        'password': hashedPassword, 
      };

      await SupabaseService.client.from("users").insert(dataToInsert);

      return "User registered successfully";
    } catch (e) {
      return e.toString();
    }
  }
}
