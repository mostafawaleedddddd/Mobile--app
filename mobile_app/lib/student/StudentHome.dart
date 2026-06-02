import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // [NEW] For picking PDF/DOCX files from device
import '../app_session.dart';
import '../theme_provider.dart';
import 'User_profile.dart';
import 'survey.dart';
import 'interview_prep.dart';
import 'internships_page.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}

const _white = Colors.white;
const _appliedColor = Color(0xFF3B82F6);
const _acceptedColor = Color(0xFF10B981);
const _rejectedColor = Color(0xFFEF4444);
const _interviewColor = Color(0xFF7C3AED);

final _activityTabs = ['All', 'Applied', 'Interview', 'Rejected'];
const _tabStatuses = ['', 'pending', 'interview', 'rejected'];

String _getInitials(String name) => name
    .trim()
    .split(' ')
    .where((e) => e.isNotEmpty)
    .take(2)
    .map((e) => e[0].toUpperCase())
    .join();

final _toolsToUse = [
  _TooltoUse(
    title: 'Resume Analyzer',
    subtitle: 'Get AI feedback on your CV',
    icon: Icons.description_outlined,
    grad: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
  ),
  _TooltoUse(
    title: 'Interview Prep',
    subtitle: 'Practice mock interviews',
    icon: Icons.record_voice_over_outlined,
    grad: [Color(0xFF0284C7), Color(0xFF06B6D4)],
  ),
];

class _TooltoUse {
  final String title, subtitle;
  final IconData icon;
  final List<Color> grad;

  const _TooltoUse({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.grad,
  });
}

class _Announcement {
  final String title, body, date, type;
  final Color typeColor;

  const _Announcement({
    required this.title,
    required this.body,
    required this.date,
    required this.type,
    required this.typeColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// UNCHANGED: HomePage and _HomePageState — only _buildToolsToUse() is modified
// ─────────────────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  final int? userId;

  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _db = Supabase.instance.client;
  Timer? _refreshTimer;
  int _filterIndex = 0;
  int _navIndex = 0;
  bool _isLoading = true;

  int? _userId;
  String _username = 'Student';
  String _email = '';
  List<Map<String, dynamic>> _internships = [];
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? user;
      final sessionEmail =
          AppSession.email ??
          _db.auth.currentSession?.user.email ??
          _db.auth.currentUser?.email;

      if (widget.userId != null) {
        user = await _db
            .from('User_profile')
            .select()
            .eq('id', widget.userId!)
            .maybeSingle();
      } else if (sessionEmail != null && sessionEmail.isNotEmpty) {
        user = await _db
            .from('User_profile')
            .select()
            .eq('email', sessionEmail)
            .maybeSingle();
      }

      List<Map<String, dynamic>> internships = [];
      if (user != null) {
        final internshipRows = await _db
            .from('Internships')
            .select()
            .eq('user_id', user['id'])
            .order('id', ascending: false);
        internships = List<Map<String, dynamic>>.from(internshipRows);
      }

      List<Map<String, dynamic>> applications = [];
      if (user != null) {
        final appsRows = await _db
            .from('Job_applications')
            .select(
              '*, Job_postings!inner(title, company_id, Company_profile!inner(name))',
            )
            .eq('student_id', user['id'])
            .order('applied_at', ascending: false);
        applications = appsRows
            .map(
              (row) => {
                'job_title': row['Job_postings']['title'] as String,
                'company_name':
                    row['Job_postings']['Company_profile']['name'] as String,
                'status': row['status'] as String,
                'applied_at': row['applied_at'] as String?,
              },
            )
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _userId = user?['id'] as int?;
        _username = ((user?['name'] ?? '') as String).trim().isEmpty
            ? 'Student'
            : user!['name'] as String;
        _email = (user?['email'] ?? '') as String;
        _internships = internships;
        _applications = applications;
        _isLoading = false;
      });

      if (user != null) {
        AppSession.setUser(userEmail: _email, id: user['id'] as int);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials() {
    final parts = _username
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'S';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  Future<void> _openProfile() async {
    if (_userId == null) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ProfileScreen(id: _userId!)),
    );
  }

  Future<void> _handleBottomNavTap(int index) async {
    if (index == 0) {
      if (_navIndex != 0) setState(() => _navIndex = 0);
      return;
    }
    if (index == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InternshipsPage(
            userId: _userId!,
            userName: _username,
            userEmail: _email,
          ),
        ),
      );
      return;
    }
    if (index == 2) {
      await _openProfile();
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final body = _navIndex == 3 && _userId != null
        ? SurveyScreen(userId: _userId!, internships: _internships)
        : _buildHomeBody();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: body,
      bottomNavigationBar: _BottomBar(
        currentIndex: _navIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildHomeBody() {
    final sw = MediaQuery.of(context).size.width;
    final theme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _Blob(size: sw * 0.75, color: theme.primary.withOpacity(0.07)),
        ),
        Positioned(
          bottom: -60,
          right: -40,
          child: _Blob(size: sw * 0.55, color: theme.primary.withOpacity(0.05)),
        ),
        SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildWelcomeHeader()),
              SliverToBoxAdapter(child: _buildActivityTabs()),
              SliverToBoxAdapter(
                child: _buildSectionHeader('My Applications', 'View All', () {
                  if (_userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AllApplicationsScreen(userId: _userId!),
                      ),
                    );
                  }
                }),
              ),
              SliverToBoxAdapter(child: _buildApplicationsList()),
              SliverToBoxAdapter(
                child: _buildSectionHeader('Tools to use', '', null),
              ),
              SliverToBoxAdapter(child: _buildToolsToUse()),
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'University Announcements',
                  'View All',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllAnnouncementsScreen(),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Supabase.instance.client
                        .from('university_announcements')
                        .stream(primaryKey: ['id'])
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final liveData = snapshot.data ?? [];
                      final previewData = liveData.take(3).toList();
                      if (previewData.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text("No university announcements yet."),
                          ),
                        );
                      }
                      return Column(
                        children: previewData.map((item) {
                          final a = _Announcement(
                            title: item['title'] ?? 'Untitled',
                            body: item['description'] ?? '',
                            date: _formatTimeAgo(item['created_at']),
                            type: item['type'] ?? 'News',
                            typeColor: _getLiveTypeColor(item['type']),
                          );
                          return _AnnouncementCard(a: a);
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _username,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF818CF8),
                    Theme.of(context).colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _openProfile,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Text(
                    _initials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _activityTabs.length,
        itemBuilder: (_, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
                border: active
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
              ),
              child: Text(
                _activityTabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (action.isNotEmpty && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    final filtered = _filterIndex == 0
        ? _applications
        : _applications
              .where((a) => a['status'] == _tabStatuses[_filterIndex])
              .toList();
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (_, i) {
          final app = filtered[i];
          return _ApplicationCard(app: app);
        },
      ),
    );
  }

  // ─── [MODIFIED] _buildToolsToUse ──────────────────────────────────────────
  // WHAT CHANGED: Added an `onTap` for the "Resume Analyzer" card.
  // When tapped, it navigates to the new `ResumeAnalyzerScreen`.
  // The Interview Prep card navigation is kept exactly as before.
  Widget _buildToolsToUse() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _toolsToUse.length,
        itemBuilder: (_, i) {
          final tool = _toolsToUse[i];

          // [NEW] Determine the correct onTap for each tool card
          VoidCallback? tapAction;

          if (tool.title == 'Interview Prep') {
            // UNCHANGED: Original interview prep navigation
            tapAction = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InterviewPrepScreen(),
                ),
              );
            };
          } else if (tool.title == 'Resume Analyzer') {
            // [NEW] Navigate to the new ResumeAnalyzerScreen
            tapAction = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ResumeAnalyzerScreen(),
                ),
              );
            };
          }

          return _TooltoUseCard(tool: tool, onTap: tapAction);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [NEW] ResumeAnalyzerScreen
//
// PURPOSE: Full-page CV analyzer. The user picks a PDF or DOCX file, taps
// "Analyze my CV", and receives a structured AI response from Gemini Flash
// broken into three sections: Strengths, Weaknesses, and Recommendations.
//
// HOW IT WORKS END-TO-END:
//  1. FilePicker opens the native file picker filtered to PDF/DOCX.
//  2. The raw bytes of the file are read into a Uint8List.
//  3. On "Analyze", bytes are base64-encoded and sent to Gemini via HTTP POST
//     using the inline_data format that Gemini's vision/document API expects.
//  4. Gemini returns plain text. We parse that text by looking for our
//     section headers (STRENGTHS:, WEAKNESSES:, RECOMMENDATIONS:) and split
//     the response into three structured lists for display.
//  5. The UI renders each section in a themed card matching the rest of the app.
// ─────────────────────────────────────────────────────────────────────────────

class ResumeAnalyzerScreen extends StatefulWidget {
  const ResumeAnalyzerScreen({super.key});

  @override
  State<ResumeAnalyzerScreen> createState() => _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends State<ResumeAnalyzerScreen> {
  // ── Gemini credentials ────────────────────────────────────────────────────
  // [PROVIDED BY USER] These are passed in exactly as given.
  static const String _apiKey = "AIzaSyCxn_LZ_cIfgwmYrbbb0ViVPKGE94mYTGQ";
  static const String _url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$_apiKey";

  // ── State ─────────────────────────────────────────────────────────────────
  // Stores the raw bytes of the picked file.
  // We hold bytes (not just a path) so we can base64-encode them for Gemini.
  Uint8List? _fileBytes;

  // The display name shown in the UI after picking (e.g. "my_resume.pdf")
  String? _fileName;

  // The MIME type we detected from the file extension.
  // Gemini needs the exact MIME to know how to parse the document.
  String? _mimeType;

  // True while the HTTP request to Gemini is in flight
  bool _isAnalyzing = false;

  // Parsed results — each is a list of bullet-point strings
  List<String> _strengths = [];
  List<String> _weaknesses = [];
  List<String> _recommendations = [];

  // True once we have received and parsed a valid response
  bool _hasResult = false;

  // ── File Picker ───────────────────────────────────────────────────────────
  // [NEW] Opens the native file picker allowing only PDF and DOCX files.
  // `withData: true` tells file_picker to eagerly read the bytes into memory,
  // which we need so we can send them to Gemini.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'], // Only CV-relevant formats
      withData: true, // Read bytes immediately so we can base64-encode them
    );

    if (result == null || result.files.isEmpty) return; // User cancelled

    final file = result.files.first;

    // Determine MIME type from file extension.
    // Gemini's inline_data block requires an accurate MIME type.
    String mime;
    if (file.extension?.toLowerCase() == 'pdf') {
      mime = 'application/pdf';
    } else {
      // DOCX = Office Open XML
      mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }

    setState(() {
      _fileBytes = file.bytes; // Raw file bytes
      _fileName = file.name;   // Display name
      _mimeType = mime;
      // Reset any previous results when a new file is picked
      _hasResult = false;
      _strengths = [];
      _weaknesses = [];
      _recommendations = [];
    });
  }

  // ── Gemini API Call ───────────────────────────────────────────────────────
  // [NEW] Sends the CV to Gemini and parses the structured response.
  //
  // HOW THE GEMINI REQUEST IS STRUCTURED:
  //  Gemini's generateContent API accepts a `contents` array.
  //  Each content item has a `parts` array. A part can be either:
  //    - { "text": "..." }           → plain text / the prompt
  //    - { "inline_data": { "mime_type": "...", "data": "<base64>" } }
  //                                  → a binary file (PDF, image, etc.)
  //
  //  We send TWO parts in one user turn:
  //    Part 1: The inline_data part — the base64-encoded CV bytes with its MIME type.
  //    Part 2: The text prompt — instructions telling Gemini exactly what to return.
  //
  //  The prompt uses strict section headers so we can reliably parse the output
  //  without needing JSON mode (Gemini Flash handles this well with clear headers).
  Future<void> _analyzeCV() async {
    if (_fileBytes == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // Step 1: Base64-encode the raw file bytes.
      // Gemini's inline_data field expects a base64 string, not raw bytes.
      final base64File = base64Encode(_fileBytes!);

      // Step 2: Build the request body.
      // The structure follows Gemini's REST API for multimodal content.
      final requestBody = jsonEncode({
        "contents": [
          {
            "parts": [
              // Part A: The document itself, sent as inline binary data.
              // mime_type tells Gemini whether to treat it as PDF or DOCX.
              // data is the base64-encoded file content.
              {
                "inline_data": {
                  "mime_type": _mimeType,
                  "data": base64File,
                }
              },
              // Part B: The text prompt.
              // We tell Gemini to act as a professional CV reviewer and return
              // output using exact headers we can reliably parse.
              // Each section must be a bullet list starting with "- ".
              {
                "text": """
You are a professional CV/resume reviewer with expertise in career development and recruitment.

Analyze the CV/resume provided and give structured feedback with these EXACT section headers:

STRENGTHS:
- [List each strength as a bullet point]

WEAKNESSES:
- [List specific CV issues: formatting problems, missing sections, unclear content, weak descriptions, etc.]
If no weaknesses found, write: "- I have nothing to say"

RECOMMENDATIONS:
- [Provide specific actionable steps to improve each weakness mentioned above]
Focus only on how to fix and improve the CV content, structure, and presentation.
If no recommendations (i.e., no weaknesses to improve), write: "- I have nothing to say"

Rules:
- ALWAYS include ALL THREE sections (STRENGTHS, WEAKNESSES, RECOMMENDATIONS) in your response
- EVERY line in each section MUST start with "- " (including placeholders)
- WEAKNESSES = what is wrong or could be better in the CV
- RECOMMENDATIONS = how to fix/improve those CV weaknesses
- Be specific and actionable, not generic
- Provide 3 to 5 points per section if possible
- Focus on CV content, structure, formatting, and professional impact
- Do NOT add any text before "STRENGTHS:" or after the last section
"""
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,    // Lower = more consistent/structured output
          "maxOutputTokens": 2000 // Enough for 3-5 points × 3 sections
        }
      });

      // Step 3: Send the HTTP POST to Gemini's generateContent endpoint.
      // The API key is appended to the URL as a query parameter.
      final uri = Uri.parse(_url);
      final response = await _sendHttpPost(uri, requestBody);

      // Step 4: Parse the raw JSON response from Gemini.
      final decoded = jsonDecode(response);

      // Navigate the response JSON: candidates[0].content.parts[0].text
      // This is where Gemini puts its generated text response.
      final text = decoded['candidates'][0]['content']['parts'][0]['text'] as String;

      // Step 5: Split the plain text response into our three sections.
      _parseGeminiResponse(text);

      setState(() {
        _isAnalyzing = false;
        _hasResult = true;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: _rejectedColor,
          ),
        );
      }
    }
  }

  // ── HTTP POST helper ──────────────────────────────────────────────────────
  // [NEW] Sends a POST request with JSON body and returns the response body as a String.
  // We use dart:io's HttpClient to avoid adding the `http` package dependency,
  // keeping the project's pubspec.yaml unchanged.
  // If you already have the `http` package, you can replace this with http.post().
  Future<String> _sendHttpPost(Uri uri, String body) async {
    // ignore: avoid_web_libraries_in_flutter
    final client = HttpClient(); // dart:io HttpClient
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    client.close();
    return responseBody;
  }

  // ── Response Parser ───────────────────────────────────────────────────────
  // [NEW] Splits Gemini's plain-text output into three bullet lists.
  //
  // HOW IT WORKS:
  //  We find the character index of each section header in the raw text.
  //  Then we extract the substring for each section and split by newlines.
  //  Lines starting with "- " are kept as bullet points (the leading "- " is stripped).
  void _parseGeminiResponse(String text) {
    // Find where each section starts in the raw response text
    final strengthsIdx = text.indexOf('STRENGTHS:');
    final weaknessesIdx = text.indexOf('WEAKNESSES:');
    final recommendationsIdx = text.indexOf('RECOMMENDATIONS:');

    // Helper: extract bullet lines from a text block between two positions
    List<String> extractBullets(int start, int end) {
      // Get the substring for this section
      final section = end > 0
          ? text.substring(start, end)
          : text.substring(start);

      // Split into lines, keep only lines starting with "- ", strip the "- " prefix
      return section
          .split('\n')
          .where((line) => line.trim().startsWith('- '))
          .map((line) => line.trim().substring(2).trim()) // Remove "- " prefix
          .where((line) => line.isNotEmpty)
          .toList();
    }

    _strengths = strengthsIdx >= 0
        ? extractBullets(strengthsIdx, weaknessesIdx > strengthsIdx ? weaknessesIdx : text.length)
        : [];

    _weaknesses = weaknessesIdx >= 0
        ? extractBullets(weaknessesIdx, recommendationsIdx > weaknessesIdx ? recommendationsIdx : text.length)
        : [];

    _recommendations = recommendationsIdx >= 0
        ? extractBullets(recommendationsIdx, text.length)
        : [];
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      // Matches the app's surface color exactly
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text(
          'Resume Analyzer',
          style: TextStyle(
            color: theme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // Matches AllAnnouncementsScreen and AllApplicationsScreen styling
        backgroundColor: theme.surfaceContainerHighest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Upload Card ──────────────────────────────────────────────────
            // [NEW] Tappable card that opens the file picker.
            // Shows a dashed-border upload zone when no file is selected,
            // and a filled confirmation card when a file has been picked.
            GestureDetector(
              onTap: _isAnalyzing ? null : _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: _fileBytes != null
                      ? const Color(0xFF7C3AED).withOpacity(0.08)
                      : theme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    // Purple border when file picked, dashed-style outline when empty
                    color: _fileBytes != null
                        ? const Color(0xFF7C3AED).withOpacity(0.5)
                        : theme.outline,
                    width: _fileBytes != null ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon changes based on state
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _fileBytes != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.upload_file_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fileBytes != null ? _fileName! : 'Upload your CV',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _fileBytes != null
                            ? const Color(0xFF7C3AED)
                            : theme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _fileBytes != null
                          ? 'Tap to change file'
                          : 'Tap to browse — PDF or Word supported',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Analyze Button ───────────────────────────────────────────────
            // [NEW] Disabled until a file is picked. Shows a spinner while loading.
            // Uses the same gradient style as the tool cards.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _fileBytes != null ? 1.0 : 0.45,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _fileBytes != null
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    // Button only works if file is picked and not currently analyzing
                    onTap: (_fileBytes != null && !_isAnalyzing) ? _analyzeCV : null,
                    child: Center(
                      child: _isAnalyzing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Analyze my CV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Results Section ──────────────────────────────────────────────
            // [NEW] Only shown after a successful analysis.
            // Three cards: Strengths (green), Weaknesses (red), Recommendations (blue).
            if (_hasResult) ...[
              const SizedBox(height: 32),
              _ResultSection(
                title: 'Strengths',
                icon: Icons.star_rounded,
                color: _acceptedColor,
                items: _strengths,
              ),
              const SizedBox(height: 16),
              _ResultSection(
                title: 'Weaknesses',
                icon: Icons.warning_amber_rounded,
                color: _rejectedColor,
                items: _weaknesses,
              ),
              const SizedBox(height: 16),
              _ResultSection(
                title: 'Recommendations',
                icon: Icons.lightbulb_outline_rounded,
                color: _appliedColor,
                items: _recommendations,
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [NEW] _ResultSection
//
// PURPOSE: Renders one section of the CV analysis (Strengths / Weaknesses /
// Recommendations) as a themed card matching the rest of the app's design language.
//
// HOW IT WORKS:
//  - Takes a `title`, an `icon`, an accent `color`, and a list of `items`.
//  - The header uses the accent color for the icon background (low opacity).
//  - Each bullet is rendered as a row with a small colored dot + the text.
// ─────────────────────────────────────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _ResultSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Matches the card style used throughout the app
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Bullet list ────────────────────────────────────────────────
          // Each item from the parsed Gemini response is a bullet row.
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colored dot bullet
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Bullet text, wraps naturally
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNCHANGED: All remaining original classes kept exactly as they were
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;

  const _ApplicationCard({required this.app});

  Color get _statusColor {
    switch (app['status']) {
      case 'pending':
        return _appliedColor;
      case 'accepted':
        return _acceptedColor;
      case 'rejected':
        return _rejectedColor;
      case 'interview':
        return _interviewColor;
      default:
        return _appliedColor;
    }
  }

  String get _displayStatus {
    switch (app['status']) {
      case 'pending':
        return 'Applied';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'interview':
        return 'Interview';
      default:
        return app['status'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    _getInitials(app['company_name']),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _statusColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _displayStatus,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            app['company_name'],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            app['job_title'],
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TooltoUseCard extends StatelessWidget {
  final _TooltoUse tool;
  final VoidCallback? onTap;

  const _TooltoUseCard({required this.tool, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: tool.grad,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: tool.grad.first.withOpacity(0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: _white, size: 20),
            ),
            const Spacer(),
            Text(
              tool.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              tool.subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.75),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final _Announcement a;

  const _AnnouncementCard({required this.a});

  void _showFullAnnouncement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.typeColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    a.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: a.typeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  a.date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              a.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            SingleChildScrollView(
              child: Text(
                a.body,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullAnnouncement(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: a.typeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: a.typeColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          a.type,
                          style: TextStyle(
                            fontSize: 10,
                            color: a.typeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        a.date,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.work_outline_rounded,
                label: 'Internships',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                active: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.assignment_outlined,
                label: 'Surveys',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap ?? () {},
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: active
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

Color _getLiveTypeColor(String? type) {
  switch (type) {
    case 'News':
      return const Color(0xFF3B82F6);      // Blue
    case 'Event':
      return const Color(0xFF8B5CF6);      // Purple 
    case 'Reminder':
      return const Color(0xFFEC4899);      // Green
    case 'Opportunity':
      return const Color(0xFFF59E0B);      // Amber
    case 'Courses':
      return const Color(0xFF06B6D4);      // Cyan
    case 'Training':
      return const Color(0xFF10B981);      // Emerald
    case 'Internship':
      return const Color(0xFFF97316);      // Orange
    case 'Workshop':
      return const Color(0xFFEF4444);      // Red
    case 'Other':
      return const Color(0xFF6B7280);      // Gray
    default:
      return Colors.blueGrey;
  }
}

String _formatTimeAgo(String? timestamp) {
  if (timestamp == null) return "Just now";
  DateTime postDate = DateTime.parse(timestamp).toLocal();
  DateTime now = DateTime.now();
  Duration diff = now.difference(postDate);
  if (diff.isNegative || diff.inSeconds < 60) return "Just now";
  if (diff.inMinutes < 60) {
    return "${diff.inMinutes} mins ago";
  } else if (diff.inHours < 24) return "${diff.inHours} hours ago";
  else if (diff.inDays < 7) return "${diff.inDays} days ago";
  else return "${postDate.day}/${postDate.month}/${postDate.year}";
}

class AllAnnouncementsScreen extends StatelessWidget {
  const AllAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text(
          'University Announcements',
          style: TextStyle(
            color: theme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: theme.surfaceContainerHighest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(size: sw * 0.75, color: theme.primary.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _Blob(size: sw * 0.55, color: theme.primary.withOpacity(0.05)),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('university_announcements')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final liveData = snapshot.data ?? [];
              if (liveData.isEmpty) {
                return const Center(child: Text("No announcements found."));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: liveData.length,
                itemBuilder: (context, index) {
                  final item = liveData[index];
                  final a = _Announcement(
                    title: item['title'] ?? 'Untitled',
                    body: item['description'] ?? '',
                    date: _formatTimeAgo(item['created_at']),
                    type: item['type'] ?? 'News',
                    typeColor: _getLiveTypeColor(item['type']),
                  );
                  return _AnnouncementCard(a: a);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class AllApplicationsScreen extends StatefulWidget {
  final int userId;

  const AllApplicationsScreen({super.key, required this.userId});

  @override
  State<AllApplicationsScreen> createState() => _AllApplicationsScreenState();
}

class _AllApplicationsScreenState extends State<AllApplicationsScreen> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _fetchApplications();
    _setupRealtime();
  }

  @override
  void dispose() {
    if (_subscription != null) {
      _db.removeChannel(_subscription!);
    }
    super.dispose();
  }

  Future<void> _fetchApplications() async {
    try {
      final appsRows = await _db
          .from('Job_applications')
          .select('*, Job_postings!inner(title, Company_profile!inner(name))')
          .eq('student_id', widget.userId)
          .order('applied_at', ascending: false);

      final parsed = appsRows.map((row) => {
        'job_title': row['Job_postings']['title'] as String,
        'company_name': row['Job_postings']['Company_profile']['name'] as String,
        'status': row['status'] as String,
      }).toList();

      if (mounted) {
        setState(() {
          _applications = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    _subscription = _db.channel('public:Job_applications').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'Job_applications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'student_id',
        value: widget.userId,
      ),
      callback: (payload) {
        _fetchApplications();
      },
    ).subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text(
          'My Applications',
          style: TextStyle(color: theme.onSurface, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: theme.surfaceContainerHighest,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(size: sw * 0.75, color: theme.primary.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _Blob(size: sw * 0.55, color: theme.primary.withOpacity(0.05)),
          ),
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _applications.isEmpty
                  ? Center(child: Text("No applications found.", style: TextStyle(color: theme.onSurfaceVariant)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _applications.length,
                      itemBuilder: (context, index) {
                        final app = _applications[index];
                        Color statusCol;
                switch (app['status']) {
                  case 'pending': statusCol = const Color(0xFF3B82F6); break;
                  case 'accepted': statusCol = const Color(0xFF10B981); break;
                  case 'rejected': statusCol = const Color(0xFFEF4444); break;
                  case 'interview': statusCol = const Color(0xFF7C3AED); break;
                  default: statusCol = const Color(0xFF3B82F6);
                }
                final initials = app['company_name'].toString().trim().split(' ')
                    .where((e) => e.isNotEmpty).take(2)
                    .map((e) => e[0].toUpperCase()).join();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: statusCol.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(initials,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: statusCol))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(app['job_title'],
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.onSurface),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(app['company_name'],
                                style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusCol.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          app['status'].toString().toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusCol),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),    
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// pubspec.yaml — ADD THIS DEPENDENCY (if not already present):
//
//   dependencies:
//     file_picker: ^8.0.0
//
// Then run: flutter pub get
//
// file_picker handles the native file browser on Android, iOS, and desktop.
// withData: true reads file bytes eagerly into memory (needed for base64 encoding).
// ─────────────────────────────────────────────────────────────────────────────
