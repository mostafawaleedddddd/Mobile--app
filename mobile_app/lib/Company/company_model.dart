// ─────────────────────────────────────────────────────────────────────────────
// company_model.dart
// All data model / entity classes for the company side of the app.
// Keep this file free of any Flutter / UI imports.
// ─────────────────────────────────────────────────────────────────────────────

// ─── COMPANY PROFILE ──────────────────────────────────────────────────────────
class CompanyProfile {
  final int id;
  final String name;
  final String email;
  final String industry;
  final String location;
  final String? description;

  const CompanyProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.industry,
    required this.location,
    this.description,
  });

  /// Build a [CompanyProfile] from a Supabase row map.
  factory CompanyProfile.fromMap(Map<String, dynamic> map) => CompanyProfile(
        id: map['id'] as int,
        name: (map['name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        industry: (map['industry'] ?? '') as String,
        location: (map['location'] ?? '') as String,
        description: map['description'] as String?,
      );

  /// Serialize to a map suitable for Supabase inserts (excludes `id`).
  Map<String, dynamic> toInsertMap() => {
        'name': name,
        'email': email,
        'industry': industry,
        'location': location,
        'description': description,
      };

  /// Return initials from company name (up to 2 characters).
  String get initials {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}

// ─── JOB POSTING ─────────────────────────────────────────────────────────────
class JobPosting {
  final int? id;
  final int companyId;
  final String title;
  final String description;
  final String requirements;
  final String location;
  final String duration;
  final int spotsAvailable;
  final DateTime? createdAt;

  const JobPosting({
    this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.requirements,
    required this.location,
    required this.duration,
    required this.spotsAvailable,
    this.createdAt,
  });

  factory JobPosting.fromMap(Map<String, dynamic> map) => JobPosting(
        id: map['id'] as int?,
        companyId: map['company_id'] as int,
        title: (map['title'] ?? '') as String,
        description: (map['description'] ?? '') as String,
        requirements: (map['requirements'] ?? '') as String,
        location: (map['location'] ?? '') as String,
        duration: (map['duration'] ?? '') as String,
        spotsAvailable: (map['spots_available'] ?? 0) as int,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)
            : null,
      );

  /// Serialize for Supabase inserts.
  Map<String, dynamic> toInsertMap() => {
        'company_id': companyId,
        'title': title,
        'description': description,
        'requirements': requirements,
        'location': location,
        'duration': duration,
        'spots_available': spotsAvailable,
      };
}

// ─── JOB APPLICATION ─────────────────────────────────────────────────────────
/// Represents a student's application to a job posting.
/// status values: 'pending' | 'accepted' | 'rejected'
class JobApplication {
  final int? id;
  final int jobId;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final String status;
  final DateTime? appliedAt;

  const JobApplication({
    this.id,
    required this.jobId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.status,
    this.appliedAt,
  });

  factory JobApplication.fromMap(Map<String, dynamic> map) => JobApplication(
        id: map['id'] as int?,
        jobId: map['job_id'] as int,
        studentId: map['student_id'] as int,
        studentName: (map['student_name'] ?? 'Unknown') as String,
        studentEmail: (map['student_email'] ?? '') as String,
        status: (map['status'] ?? 'pending') as String,
        appliedAt: map['applied_at'] != null
            ? DateTime.tryParse(map['applied_at'] as String)
            : null,
      );

  /// Return a copy of this application with an updated [status].
  JobApplication copyWith({String? status}) => JobApplication(
        id: id,
        jobId: jobId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        status: status ?? this.status,
        appliedAt: appliedAt,
      );

  /// Initials derived from [studentName].
  String get initials {
    final parts =
        studentName.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}
