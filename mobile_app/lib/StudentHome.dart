import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_session.dart';
import 'User_profile.dart';
import 'survey.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'sans-serif'),
        home: const HomePage(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomePage();
}

const _violet = Color(0xFF7C3AED);
//const _violetL = Color(0xFFEDE9FE);
const _blue = Color(0xFF3B82F6);
const _blueL = Color(0xFFEFF6FF);
const _pink = Color(0xFFEC4899);
const _bg = Color(0xFFF8F7FF);
const _white = Colors.white;
const _textDark = Color(0xFF1E1B4B);
const _textGrey = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

const _appliedColor = Color(0xFF3B82F6);
const _acceptedColor = Color(0xFF10B981);
const _rejectedColor = Color(0xFFEF4444);
const _interviewColor = Color(0xFF7C3AED);

final _activityTabs = ['All', 'Applied', 'Interview', 'Rejected'];
const _tabStatuses = ['', 'pending', 'interview', 'rejected'];

String _getInitials(String name) => name.trim().split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();

final _aiTools = [
  _AiTool(title: 'Resume Analyzer', subtitle: 'Get AI feedback on your CV', icon: Icons.description_outlined, grad: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
  _AiTool(title: 'AI Career Chat', subtitle: 'Chat with your career assistant', icon: Icons.smart_toy_outlined, grad: [Color(0xFFDB2777), Color(0xFF9333EA)]),
  _AiTool(title: 'Interview Prep', subtitle: 'Practice mock interviews', icon: Icons.record_voice_over_outlined, grad: [Color(0xFF0284C7), Color(0xFF06B6D4)]),
];

class _AiTool {
  final String title, subtitle;
  final IconData icon;
  final List<Color> grad;

  const _AiTool({
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
        setState(() {
        });
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
      final sessionEmail = AppSession.email ??
          _db.auth.currentSession?.user.email ??
          _db.auth.currentUser?.email;

      if (widget.userId != null) {
        user = await _db.from('User_profile').select().eq('id', widget.userId!).maybeSingle();
      } else if (sessionEmail != null && sessionEmail.isNotEmpty) {
        user = await _db.from('User_profile').select().eq('email', sessionEmail).maybeSingle();
      }

      List<Map<String, dynamic>> internships = [];
      if (user != null) {
        final internshipRows =
            await _db.from('Internships').select().eq('user_id', user['id']).order('id', ascending: false);
        internships = List<Map<String, dynamic>>.from(internshipRows);
      }

      List<Map<String, dynamic>> applications = [];
      if (user != null) {
        final appsRows = await _db.from('Job_applications').select('*, Job_postings!inner(title, company_id, Company_profile!inner(name))').eq('student_id', user['id']).order('applied_at', ascending: false);
        applications = appsRows.map((row) => {
          'job_title': row['Job_postings']['title'] as String,
          'company_name': row['Job_postings']['Company_profile']['name'] as String,
          'status': row['status'] as String,
          'applied_at': row['applied_at'] as String?,
        }).toList();
      }

      if (!mounted) return;
      setState(() {
        _userId = user?['id'] as int?;
        _username = ((user?['name'] ?? '') as String).trim().isEmpty ? 'Student' : user!['name'] as String;
        _email = (user?['email'] ?? '') as String;
        _internships = internships;
        _applications = applications;
        _isLoading = false;
      });

      if (user != null) {
        AppSession.setUser(
          userEmail: _email,
          id: user['id'] as int,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _initials() {
    final parts = _username.trim().split(' ').where((e) => e.isNotEmpty).toList();
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
      if (_navIndex != 0) {
        setState(() => _navIndex = 0);
      }
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
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    final body = _navIndex == 3 && _userId != null
        ? SurveyScreen(userId: _userId!, internships: _internships)
        : _buildHomeBody();

    return Scaffold(
      backgroundColor: _bg,
      body: body,
      bottomNavigationBar: _BottomBar(
        currentIndex: _navIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildHomeBody() {
  return SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildWelcomeHeader()),
        SliverToBoxAdapter(child: _buildActivityTabs()),
        SliverToBoxAdapter(child: _buildSectionHeader('My Applications', 'View All', () {})),
        SliverToBoxAdapter(child: _buildApplicationsList()),
        SliverToBoxAdapter(child: _buildSectionHeader('AI Tools', '', null)),
        SliverToBoxAdapter(child: _buildAiTools()),
        SliverToBoxAdapter(child: _buildSectionHeader('University Announcements', 'View All', () {})),
        
        // --- DYNAMIC ANNOUNCEMENTS SECTION START ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // Using lowercase table name to avoid 404 errors shown in your logs
              stream: Supabase.instance.client
                  .from('university_announcements') 
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final liveData = snapshot.data ?? [];

                if (liveData.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No university announcements yet."),
                    ),
                  );
                }

                return Column(
                  // Mapping the live database records to your existing _AnnouncementCard
                  children: liveData.map((item) {
                    final a = _Announcement(
                      title: item['title'] ?? 'Untitled',
                      body: item['description'] ?? '',
                      date: _formatTimeAgo(item['created_at']), // Formats to "2 hours ago"
                      type: item['type'] ?? 'News',
                      typeColor: _getLiveTypeColor(item['type']), // Matches colors: Violet, Pink, Blue
                    );
                    return _AnnouncementCard(a: a);
                  }).toList(),
                );
              },
            ),
          ),
        ),
        // --- DYNAMIC ANNOUNCEMENTS SECTION END ---
      ],
    ),
  );
}

// Helper to keep your UI colors consistent with your design
Color _getLiveTypeColor(String? type) {
  switch (type) {
    case 'Event': return const Color(0xFF8B5CF6);      // Violet
    case 'Important': return const Color(0xFFEC4899);  // Pink
    case 'News': return const Color(0xFF3B82F6);       // Blue
    case 'Reminder': return const Color(0xFF059669);   // Green
    default: return Colors.blueGrey;
  }
}

// Helper to turn database timestamps into readable strings
String _formatTimeAgo(String? timestamp) {
  if (timestamp == null) return "Just now";
  
  // Parse the UTC time from Supabase correctly
  DateTime postDate = DateTime.parse(timestamp).toLocal();
  DateTime now = DateTime.now();
  
  // Use difference and take the absolute value to avoid negative numbers
  Duration diff = now.difference(postDate);
  
  // If the difference is negative or very small, just say "Just now"
  if (diff.isNegative || diff.inSeconds < 60) {
    return "Just now";
  }

  if (diff.inMinutes < 60) {
    return "${diff.inMinutes} mins ago";
  } else if (diff.inHours < 24) {
    return "${diff.inHours} hours ago";
  } else if (diff.inDays < 7) {
    return "${diff.inDays} days ago";
  } else {
    // For older posts, show the date
    return "${postDate.day}/${postDate.month}/${postDate.year}";
  }
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
                Text(_greeting(), style: const TextStyle(fontSize: 13, color: _textGrey)),
                const SizedBox(height: 4),
                Text(
                  _username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _textDark),
                ),
              ],
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), _violet],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: _violet.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: InkWell(
                onTap: _openProfile,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Text(
                    _initials(),
                    style: const TextStyle(color: _white, fontWeight: FontWeight.w800, fontSize: 16),
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
                color: active ? _violet : _white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: active
                    ? [BoxShadow(color: _violet.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
                border: active ? null : Border.all(color: _border, width: 1),
              ),
              child: Text(
                _activityTabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? _white : _textGrey,
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
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textDark)),
          if (action.isNotEmpty && onTap != null)
            GestureDetector(
              onTap: onTap,
              child: Text(action, style: const TextStyle(fontSize: 13, color: _violet, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    final filtered = _filterIndex == 0 ? _applications : _applications.where((a) => a['status'] == _tabStatuses[_filterIndex]).toList();
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

  Widget _buildAiTools() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _aiTools.length,
        itemBuilder: (_, i) {
          final tool = _aiTools[i];
          return _AiToolCard(tool: tool);
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;

  const _ApplicationCard({required this.app});

  Color get _statusColor {
    switch (app['status']) {
      case 'pending': return _appliedColor;
      case 'accepted': return _acceptedColor;
      case 'rejected': return _rejectedColor;
      case 'interview': return _interviewColor;
      default: return _appliedColor;
    }
  }

  String get _displayStatus {
    switch (app['status']) {
      case 'pending': return 'Applied';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'interview': return 'Interview';
      default: return app['status'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(_getInitials(app['company_name']), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _statusColor))),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: _statusColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                child: Text(_displayStatus, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor)),
              ),
            ],
          ),
          const Spacer(),
          Text(app['company_name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(app['job_title'], style: const TextStyle(fontSize: 11, color: _textGrey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _AiToolCard extends StatelessWidget {
  final _AiTool tool;

  const _AiToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tool.grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: tool.grad.first.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(12)),
            child: Icon(tool.icon, color: _white, size: 20),
          ),
          const Spacer(),
          Text(tool.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _white), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(tool.subtitle, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.75)), overflow: TextOverflow.ellipsis, maxLines: 2),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final _Announcement a;

  const _AnnouncementCard({required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(color: a.typeColor, borderRadius: BorderRadius.circular(2)),
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
                      decoration: BoxDecoration(color: a.typeColor.withOpacity(0.10), borderRadius: BorderRadius.circular(20)),
                      child: Text(a.type, style: TextStyle(fontSize: 10, color: a.typeColor, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text(a.date, style: const TextStyle(fontSize: 11, color: _textGrey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(a.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark)),
                const SizedBox(height: 4),
                Text(a.body, style: const TextStyle(fontSize: 12, color: _textGrey, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
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
        color: _white,
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', active: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.work_outline_rounded, label: 'Internships', active: currentIndex == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', active: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.assignment_outlined, label: 'Surveys', active: currentIndex == 3, onTap: () => onTap(3)),
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

  const _NavItem({required this.icon, required this.label, required this.active, this.onTap});

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
                color: active ? _blueL : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: active ? _blue : _textGrey, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? _blue : _textGrey,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      );
}
