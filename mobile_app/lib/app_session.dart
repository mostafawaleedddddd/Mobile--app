import 'package:shared_preferences/shared_preferences.dart';

// ─── Keys ────────────────────────────────────────────────────────────────────
const _kEmail       = 'session_email';
const _kUserId      = 'session_user_id';
const _kAccountType = 'session_account_type';

// ─── AppSession ──────────────────────────────────────────────────────────────
// Persists login state across app kills using shared_preferences.
// Call AppSession.load() once in main() before runApp().
// Values are available as static fields throughout the app after that.
class AppSession {
  // ── In-memory mirrors (fast access after load) ───────────────────────────
  static String? email;
  static int?    userId;
  static String? accountType; // 'Student' | 'Company' | 'Faculty'

  // ── Persist & mirror ─────────────────────────────────────────────────────
  static Future<void> setUser({
    required String userEmail,
    required int    id,
    required String type,        // 'Student' | 'Company' | 'Faculty'
  }) async {
    email       = userEmail;
    userId      = id;
    accountType = type;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmail,       userEmail);
    await prefs.setInt   (_kUserId,      id);
    await prefs.setString(_kAccountType, type);
  }

  // ── Load from disk into memory (call once at startup) ────────────────────
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    email       = prefs.getString(_kEmail);
    userId      = prefs.getInt   (_kUserId);
    accountType = prefs.getString(_kAccountType);
  }

  // ── Clear on logout ───────────────────────────────────────────────────────
  static Future<void> clear() async {
    email       = null;
    userId      = null;
    accountType = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmail);
    await prefs.remove(_kUserId);
    await prefs.remove(_kAccountType);
  }

  // ── Convenience ───────────────────────────────────────────────────────────
  static bool get isLoggedIn => userId != null && accountType != null;
}