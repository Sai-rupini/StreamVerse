import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _registeredUsersKey = 'registeredUsers';
  static const String _loggedInUserKey = 'loggedInUser';

  static Future<void> signUp(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_registeredUsersKey);
    Map<String, dynamic> users = usersJson != null ? jsonDecode(usersJson) : {};
    users[email] = password;
    await prefs.setString(_registeredUsersKey, jsonEncode(users));
  }

  static Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_registeredUsersKey);
    if (usersJson != null) {
      final Map<String, dynamic> users = jsonDecode(usersJson);
      if (users.containsKey(email) && users[email] == password) {
        await prefs.setString(_loggedInUserKey, email);
        return true;
      }
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInUserKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loggedInUserKey) != null;
  }
}
