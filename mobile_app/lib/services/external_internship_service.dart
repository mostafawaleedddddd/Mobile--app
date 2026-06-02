import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// EXTERNAL INTERNSHIP MODEL
// ─────────────────────────────────────────────────────────────────────────────
class ExternalInternship {
  final String title;
  final String company;
  final String location;
  final String description;
  final String applyUrl;
  final String employmentType;

  const ExternalInternship({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.applyUrl,
    required this.employmentType,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// EXTERNAL INTERNSHIP SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class ExternalInternshipService {
  static const String _apiHost = 'jsearch.p.rapidapi.com';
  static const String _apiKey =
      '8475cc7791msh1f6a3b83ab37424p17b8aejsnefc446b01106'; // Replace with actual API key
  static const List<String> _csKeywords = [
    'software',
    'software engineer',
    'software engineering',
    'developer',
    'programmer',
    'backend',
    'frontend',
    'full stack',
    'fullstack',
    'mobile',
    'flutter',
    'android',
    'ios',
    'web developer',
    'computer science',
    'artificial intelligence',
    'ai',
    'machine learning',
    'ml',
    'deep learning',
    'data science',
    'data scientist',
    'data analyst',
    'data engineer',
    'big data',
    'cybersecurity',
    'cyber security',
    'security analyst',
    'penetration tester',
    'soc analyst',
    'cloud',
    'cloud engineer',
    'devops',
    'site reliability',
    'sre',
    'network engineer',
    'systems engineer',
    'database',
    'sql',
    'information technology',
    'it intern',
  ];
  // Target companies
  static const List<String> _targetCompanies = [
    'Microsoft',
    'Siemens',
    'VOIS',
    'NBE',
  ];

  // Keywords to filter for internship roles
  static const List<String> _internshipKeywords = [
    'intern',
    'internship',
    'trainee',
    'graduate',
    'training',
  ];

  /// Check if company matches target companies (case insensitive)
  static bool _isTargetCompany(String companyName) {
    final lowerCompany = companyName.toLowerCase();
    return _targetCompanies.any(
      (target) => lowerCompany.contains(target.toLowerCase()),
    );
  }

  /// Check if location is in Egypt
  static bool _isEgypt(String location) {
    final lowerLocation = location.toLowerCase();
    return lowerLocation.contains('egypt') ||
        lowerLocation.contains('cairo') ||
        lowerLocation.contains('giza') ||
        lowerLocation.contains('alexandria');
  }

  /// Search for external internships from JSearch API
  Future<List<ExternalInternship>> searchInternships({
    String? query,
    int page = 1,
  }) async {
    try {
      // Build a broader query and rely on post-response filtering.
      final searchQuery = [
        if (query?.trim().isNotEmpty ?? false) query!.trim(),
        'internship egypt',
      ].join(' ');

      final url = Uri.https(_apiHost, '/search', {
        'query': searchQuery,
        'page': page.toString(),
        'num_pages': '1',
      });
      print('External internship query: $searchQuery');

      final response = await http
          .get(
            url,
            headers: {'X-RapidAPI-Key': _apiKey, 'X-RapidAPI-Host': _apiHost},
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('API request timed out'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final jobsRaw = data['data'] as List<dynamic>?;
        print('Total jobs from API: ${jobsRaw?.length}');
        if (jobsRaw == null || jobsRaw.isEmpty) {
          print('External internship response: $data');
          return [];
        }

        final internships = <ExternalInternship>[];
        for (final jobRaw in jobsRaw) {
          final job = jobRaw as Map<String, dynamic>;
          final title = job['job_title'] as String? ?? '';
          final company = job['employer_name'] as String? ?? '';
          final location = _formatLocation(job);

          // Filter: only keep internship-related titles
          final description = job['job_description'] as String? ?? '';

          if (!_isInternshipRole(title)) {
            print('Rejected: Not internship');
            continue;
          }

          // if (!_isComputerScienceJob(title, description)) {
          //   print('Rejected: Not CS');
          //   continue;
          // }

          // if (!_isLinkedInJob(job)) {
          //   print('Rejected: Not LinkedIn');
          //   continue;
          // }

          // if (!_isTargetCompany(company)) {
          //   print('Rejected: Company mismatch');
          //   continue;
          // }

          // if (!_isEgypt(location)) {
          //   print('Rejected: Not Egypt');
          //   continue;
          // }

          print('Accepted: $title');

          internships.add(
            ExternalInternship(
              title: title,
              company: company,
              location: location,
              description:
                  job['job_description'] as String? ??
                  'No description available',
              applyUrl: job['job_apply_link'] as String? ?? '',
              employmentType:
                  job['job_employment_type'] as String? ?? 'Not specified',
            ),
          );
          print('Total jobs from API after: ${internships.length}');
        }

        return internships;
      } else if (response.statusCode == 429) {
        throw RateLimitException(
          'API rate limit exceeded. Please try again later.',
        );
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on TimeoutException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Only keep jobs whose apply URL is LinkedIn
  static bool _isLinkedInJob(Map<String, dynamic> job) {
    final url = _getApplyUrl(job).toLowerCase();
    return url.contains('linkedin.com');
  }

  static String _getApplyUrl(Map<String, dynamic> job) {
    return (job['job_apply_link'] ??
            job['job_url'] ??
            job['job_link'] ??
            job['apply_url'] ??
            job['link'] ??
            '')
        .toString();
  }

  /// Only keep Computer Science related jobs
  static bool _isComputerScienceJob(String title, String description) {
    final text = '$title $description'.toLowerCase();

    return _csKeywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  /// Check if job title contains internship keywords
  static bool _isInternshipRole(String title) {
    final lowerTitle = title.toLowerCase();
    return _internshipKeywords.any((keyword) => lowerTitle.contains(keyword));
  }

  /// Format location from job data
  static String _formatLocation(Map<String, dynamic> job) {
    final city = job['job_city'] as String?;
    final country = job['job_country'] as String?;

    if (city != null && country != null) {
      return '$city, $country';
    } else if (city != null) {
      return city;
    } else if (country != null) {
      return country;
    } else if (job['job_location'] != null) {
      return job['job_location'] as String;
    }
    return 'Remote';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM EXCEPTIONS
// ─────────────────────────────────────────────────────────────────────────────
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  @override
  String toString() => message;
}
