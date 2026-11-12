import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _userIdKey = 'user_id';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  // SAVE USER ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, userId);
  }

   static Future<void> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("userName", userName);
  }
    static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("userName");
  }


  // GET USER ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_userIdKey);
  }

  // GET USER NAME

  // REMOVE USER ID
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
  }
}
