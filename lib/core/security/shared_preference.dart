
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _userIdKey = 'user_id';

  // SAVE USER ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userIdKey, userId);
  }

  // GET USER ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_userIdKey);
  }

  // REMOVE USER ID
  static Future<void> clearUserId() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
  }
}
