class AppSession {
  static String? email;
  static int? userId;

  static void setUser({
    required String userEmail,
    required int id,
  }) {
    email = userEmail;
    userId = id;
  }

  static void clear() {
    email = null;
    userId = null;
  }
}
