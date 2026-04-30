// ─────────────────────────────────────────────────────────────────────────────
// company_session.dart
// In-memory session holder for the currently logged-in company.
// Mirrors the pattern used by app_session.dart on the student side.
// ─────────────────────────────────────────────────────────────────────────────

class CompanySession {
  static String? email;
  static int?    companyId;
  static String? companyName;

  /// Populate session after a successful login or registration.
  static void setCompany({
    required String companyEmail,
    required int    id,
    required String name,
  }) {
    email       = companyEmail;
    companyId   = id;
    companyName = name;
  }

  /// Wipe session on logout.
  static void clear() {
    email       = null;
    companyId   = null;
    companyName = null;
  }

  /// True when a company is currently logged in.
  static bool get isLoggedIn => companyId != null;
}
