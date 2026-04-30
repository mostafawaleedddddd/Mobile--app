// ─────────────────────────────────────────────────────────────────────────────
// faculty_model.dart
// All data model / entity classes for the faculty (Doctors/TAs) side of the app.
// ─────────────────────────────────────────────────────────────────────────────

// ─── FACULTY PROFILE ──────────────────────────────────────────────────────────
class FacultyProfile {
  final int id;
  final String name;
  final String email;
  final String department;
  final String designation; // e.g., 'Professor', 'TA', 'HOD'

  const FacultyProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
  });

  factory FacultyProfile.fromMap(Map<String, dynamic> map) => FacultyProfile(
        id: map['id'] as int,
        name: (map['name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        department: (map['department'] ?? '') as String,
        designation: (map['designation'] ?? '') as String,
      );

  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'email': email,
        'department': department,
        'designation': designation,
      };

  String get initials {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'F';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}

// ─── UNIVERSITY ANNOUNCEMENT ─────────────────────────────────────────────────
/// These are official university-led offers (Trainings, Seminars, etc.)
class UniversityAnnouncement {
  final int? id;
  final int facultyId;
  final String title;
  final String description;
  final String type; // e.g., 'Training', 'Internship', 'Workshop'
  final DateTime? createdAt;

  const UniversityAnnouncement({
    this.id,
    required this.facultyId,
    required this.title,
    required this.description,
    required this.type,
    this.createdAt,
  });

  factory UniversityAnnouncement.fromMap(Map<String, dynamic> map) =>
      UniversityAnnouncement(
        id: map['id'] as int?,
        facultyId: map['faculty_id'] as int,
        title: (map['title'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        type: (map['type'] ?? 'Training') as String,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertMap() => {
        'faculty_id': facultyId,
        'title': title,
        'description': description,
        'type': type,
      };
}

// ─── INTERNSHIP VETTING ──────────────────────────────────────────────────────
/// A simple view model to help Faculty review Company JobPostings.
class VettingRecord {
  final int jobId;
  final String jobTitle;
  final String companyName;
  final String companyEmail;
  final String status; // 'pending' | 'approved' | 'rejected'

  const VettingRecord({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.companyEmail,
    required this.status,
  });

  factory VettingRecord.fromJoinedMap(Map<String, dynamic> map) => VettingRecord(
        jobId: map['id'] as int,
        jobTitle: (map['title'] ?? '') as String,
        companyName: (map['Company_profile']['name'] ?? 'Unknown') as String,
        companyEmail: (map['Company_profile']['email'] ?? '') as String,
        status: (map['status'] ?? 'pending') as String,
      );
}