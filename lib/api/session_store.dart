import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the parent's (student_code, phone) on-device so they don't
/// have to type it in every time they open the app. This is convenience
/// storage only, not an auth token — the values are re-checked against
/// the database on every API call.
class SessionStore {
  static const _codeKey = "student_code";
  static const _phoneKey = "phone";

  static Future<void> save(String studentCode, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeKey, studentCode);
    await prefs.setString(_phoneKey, phone);
  }

  static Future<(String, String)?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_codeKey);
    final phone = prefs.getString(_phoneKey);
    if (code == null || phone == null) return null;
    return (code, phone);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codeKey);
    await prefs.remove(_phoneKey);
  }
}
