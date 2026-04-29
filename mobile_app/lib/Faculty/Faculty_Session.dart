class FacultySession {
  static String? email;
  static int?    facultyId;
  static String? name;
  static String? department;
  static String? designation;

  /// Populate session after a successful faculty login.
  static void setFaculty({
    required String facultyEmail,
    required int    id,
    required String facultyName,
    String?         dept,
    String?         title,
  }) {
    email       = facultyEmail;
    facultyId   = id;
    name        = facultyName;
    department  = dept;
    designation = title;
  }

  /// Wipe faculty session on logout.
  static void clear() {
    email       = null;
    facultyId   = null;
    name        = null;
    department  = null;
    designation = null;
  }

  /// True when a faculty member is currently logged in.
  static bool get isLoggedIn => facultyId != null;
}