// import 'dart:typed_data';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme_provider.dart';
import 'Faculty_Session.dart';

final _db = Supabase.instance.client;

const Color _facultyIndigo = Color(0xFF303F9F);
const Color _accentTeal = Color(0xFF26A69A);

class FacultyHomePage extends StatefulWidget {
  final int facultyId;
  const FacultyHomePage({super.key, required this.facultyId});

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  final GlobalKey<_FacultyProfilePageState> _profileKey =
      GlobalKey<_FacultyProfilePageState>();

  @override
  void initState() {
    super.initState();
    _pages = [
      ReviewQueuePage(onGoToProfile: () => setState(() => _currentIndex = 4)),
      PostAnnouncementPage(facultyId: FacultySession.facultyId ?? 0),
      const CompanyManagementPage(),
      const StudentReportPage(),
      FacultyProfilePage(key: _profileKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Reload stats whenever the Profile tab is opened
            if (index == 4) {
              _profileKey.currentState?._loadStats();
            }
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_customize_outlined),
              activeIcon: Icon(Icons.dashboard_customize),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.post_add_rounded),
              label: 'Announce',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Companies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school_rounded),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 1: REVIEW QUEUE (Vetting)
// ──────────────────────────────────────────────────────────────────────────────
class ReviewQueuePage extends StatefulWidget {
  final VoidCallback? onGoToProfile;
  const ReviewQueuePage({super.key, this.onGoToProfile});

  @override
  State<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends State<ReviewQueuePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _initials() {
    final name = FacultySession.name ?? '';
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'F';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Faculty Vetting",
            style:
                TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: _facultyIndigo,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: Ink(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), _facultyIndigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _facultyIndigo.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: widget.onGoToProfile,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Text(
                      _initials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: "Internships"),
            Tab(text: "Certificates"),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.2,
            child: _Blob(
              size: MediaQuery.of(context).size.width * 0.8,
              color: _facultyIndigo.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.08,
            right: -MediaQuery.of(context).size.width * 0.15,
            child: _Blob(
              size: MediaQuery.of(context).size.width * 0.65,
              color: _accentTeal.withOpacity(0.06),
            ),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _buildInternshipList(),
              _buildUsersWithCertificates()
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersWithCertificates() {
    final theme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.from('Certificates').select(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(color: theme.primary));
        }

        final certificates = snapshot.data!;

        if (certificates.isEmpty) {
          return Center(
              child: Text("No certificates uploaded yet.",
                  style: TextStyle(color: theme.onSurfaceVariant)));
        }

        final Map<int, List<Map<String, dynamic>>> grouped = {};
        for (var cert in certificates) {
          final userId = cert['user_id'];
          if (userId == null) continue;
          grouped.putIfAbsent(userId, () => []);
          grouped[userId]!.add(cert);
        }

        final userIds = grouped.keys.toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future:
              _db.from('User_profile').select().inFilter('id', userIds),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(color: theme.primary));
            }

            final users = userSnapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final userId = user['id'];
                final name = user['name'] ?? 'Unknown';
                final count = grouped[userId]?.length ?? 0;

                return Card(
                  color: theme.surfaceContainerHighest,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: theme.primary.withOpacity(0.1),
                        foregroundColor: theme.primary,
                        child: Text(name[0].toUpperCase())),
                    title: Text(name,
                        style: TextStyle(
                            color: theme.onSurface,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text("$count certificate(s)",
                        style: TextStyle(color: theme.onSurfaceVariant)),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: theme.onSurfaceVariant),
                    onTap: () => _showCertificates(userId, name),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCertificates(int userId, String name) {
    final theme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _db
                    .from('Certificates')
                    .select()
                    .eq('user_id', userId)
                    .limit(20),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: theme.primary));
                  }

                  final certs = snapshot.data!;

                  if (certs.isEmpty) {
                    return Center(
                        child: Text("No certificates found.",
                            style:
                                TextStyle(color: theme.onSurfaceVariant)));
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: theme.outline,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),
                      Text(
                        "Certificates: $name",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: certs.length,
                          itemBuilder: (context, i) =>
                              _certificateCard(certs[i]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _certificateCard(Map<String, dynamic> cert) {
    final theme = Theme.of(context).colorScheme;
    final imageUrl = cert['image_url'] ?? '';

    Widget imageWidget = const SizedBox();

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        try {
          final bytes = base64Decode(imageUrl.split(',').last);
          imageWidget = Image.memory(bytes,
              height: 200, width: double.infinity, fit: BoxFit.cover);
        } catch (e) {
          imageWidget = Container(
              height: 200,
              width: double.infinity,
              color: theme.surfaceContainerHighest,
              child: const Center(child: Text("Invalid image")));
        }
      } else {
        imageWidget = Image.network(imageUrl,
            height: 200, width: double.infinity, fit: BoxFit.cover);
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(cert['title'] ?? '',
                style: TextStyle(
                    color: theme.onSurface,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(cert['date']?.toString() ?? '',
                style: TextStyle(color: theme.onSurfaceVariant)),
          ),
          GestureDetector(
            onTap: () => _showFullImage(imageUrl),
            child: imageWidget,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      await _db
                          .from('Certificates')
                          .delete()
                          .eq('id', cert['id']);
                      Navigator.pop(context);
                    },
                    child: const Text("Reject",
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await _db
                          .from('Certificates')
                          .update({'is_verified': true})
                          .eq('id', cert['id']);
                      Navigator.pop(context);
                    },
                    child: const Text("Accept"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: _buildFullImage(imageUrl)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close,
                    color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return const Text("Invalid image",
            style: TextStyle(color: Colors.white));
      }
    } else {
      return Image.network(imageUrl, fit: BoxFit.contain);
    }
  }

  Widget _buildInternshipList() {
    final theme = Theme.of(context).colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db
          .from('Job_postings')
          .select('*, Company_profile(name, email)')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(color: theme.primary));
        }

        final internships = snapshot.data!;

        if (internships.isEmpty) {
          return Center(
            child: Text(
              "No internship postings submitted yet.",
              style: TextStyle(color: theme.onSurfaceVariant),
            ),
          );
        }

        return RefreshIndicator(
          color: theme.primary,
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final item = internships[index];
              final company =
                  item['Company_profile']?['name'] ?? 'Unknown Company';
              final title = item['title'] ?? 'No title';
              final location = item['location'] ?? 'No location';
              final createdAt = item['created_at'] != null
                  ? item['created_at'].toString()
                  : 'Unknown date';

              return Card(
                color: theme.surfaceContainerHighest,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.onSurface)),
                      const SizedBox(height: 6),
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.onSurface)),
                      const SizedBox(height: 6),
                      Text(location,
                          style:
                              TextStyle(color: theme.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Text('Submitted: $createdAt',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.onSurfaceVariant)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _denyPosting(item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side:
                                    const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: const Text('Deny Posting'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _denyPosting(Map<String, dynamic> posting) async {
    final theme = Theme.of(context).colorScheme;
    final id = posting['id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        title: Text('Deny Internship',
            style: TextStyle(color: theme.onSurface)),
        content: Text(
          'Are you sure you want to deny and remove this internship posting?',
          style: TextStyle(color: theme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
                foregroundColor: theme.onSurfaceVariant),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.from('Job_postings').delete().eq('id', id);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Internship posting denied successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error denying posting: $e')));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 2: ANNOUNCEMENTS
// ──────────────────────────────────────────────────────────────────────────────
class PostAnnouncementPage extends StatefulWidget {
  final int facultyId;
  const PostAnnouncementPage({super.key, required this.facultyId});

  @override
  State<PostAnnouncementPage> createState() => _PostAnnouncementPageState();
}

class _PostAnnouncementPageState extends State<PostAnnouncementPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTag = 'News';
  bool _isPosting = false;

  final List<String> _tags = ['News', 'Event', 'Reminder' , 'Opportunity' , 'Courses', 'Training', 'Internship', 'Workshop', 'Other'];

  Future<void> _broadcastAnnouncement() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      await Supabase.instance.client.from('university_announcements').insert({
        'faculty_id': widget.facultyId,
        'title': _titleController.text.trim(),
        'description': _bodyController.text.trim(),
        'type': _selectedTag,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _titleController.clear();
        _bodyController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Announcement Broadcasted Successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text("Post Announcement",
            style: TextStyle(
                color: theme.onSurface, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: theme.surface,
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: _facultyIndigo,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -sh * 0.12,
            right: -sw * 0.25,
            child: _Blob(
                size: sw * 0.85,
                color: _facultyIndigo.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -sh * 0.1,
            left: -sw * 0.2,
            child: _Blob(
                size: sw * 0.7, color: _accentTeal.withOpacity(0.06)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Announcement Details",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.onSurface)),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    labelText: "Title (e.g., Internship Fair 2025)",
                    labelStyle:
                        TextStyle(color: theme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.outline)),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTag,
                  dropdownColor: theme.surfaceContainerHighest,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    labelText: "Category Tag",
                    labelStyle:
                        TextStyle(color: theme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.outline)),
                  ),
                  items: _tags
                      .map((tag) => DropdownMenuItem(
                          value: tag, child: Text(tag)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedTag = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
                  maxLines: 5,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    labelText: "Announcement Description",
                    labelStyle:
                        TextStyle(color: theme.onSurfaceVariant),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.outline)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isPosting ? null : _broadcastAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _facultyIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.campaign_rounded,
                            color: Colors.white),
                    label: const Text(
                      "Broadcast to Students",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 3: COMPANY MANAGEMENT (CRUD)
// ──────────────────────────────────────────────────────────────────────────────
class CompanyManagementPage extends StatefulWidget {
  const CompanyManagementPage({super.key});

  @override
  State<CompanyManagementPage> createState() =>
      _CompanyManagementPageState();
}

class _CompanyManagementPageState extends State<CompanyManagementPage> {
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCompanies() async {
    setState(() => _isLoading = true);
    try {
      final data = await _db
          .from('Company_profile')
          .select('id, name, email, industry, location, password')
          .order('name', ascending: true);
      if (mounted) setState(() => _companies = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading companies: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCompanies {
    if (_searchQuery.isEmpty) return _companies;
    final q = _searchQuery.toLowerCase();
    return _companies.where((c) {
      return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
          (c['industry'] ?? '').toString().toLowerCase().contains(q) ||
          (c['location'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  // ── ADD COMPANY ──
  void _showAddDialog() => _showCompanyDialog(null);

  // ── EDIT COMPANY ──
  void _showEditDialog(Map<String, dynamic> company) =>
      _showCompanyDialog(company);

  void _showCompanyDialog(Map<String, dynamic>? existing) {
    final theme = Theme.of(context).colorScheme;
    final isEdit = existing != null;

    final nameCtrl =
        TextEditingController(text: existing?['name'] ?? '');
    final emailCtrl =
        TextEditingController(text: existing?['email'] ?? '');
    final industryCtrl =
        TextEditingController(text: existing?['industry'] ?? '');
    final locationCtrl =
        TextEditingController(text: existing?['location'] ?? '');
    final passwordCtrl =
        TextEditingController(text: existing?['password'] ?? '');
    bool isSaving = false;
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: theme.outline,
                              borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _facultyIndigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_rounded
                                  : Icons.add_business_rounded,
                              color: _facultyIndigo,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            isEdit ? "Edit Company" : "Add New Company",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Fields
                      _sheetField(
                        controller: nameCtrl,
                        label: "Company Name",
                        icon: Icons.business_rounded,
                        theme: theme,
                      ),
                      const SizedBox(height: 14),
                      _sheetField(
                        controller: emailCtrl,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        theme: theme,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _sheetField(
                        controller: industryCtrl,
                        label: "Industry",
                        icon: Icons.category_outlined,
                        theme: theme,
                      ),
                      const SizedBox(height: 14),
                      _sheetField(
                        controller: locationCtrl,
                        label: "Location",
                        icon: Icons.location_on_outlined,
                        theme: theme,
                      ),
                      const SizedBox(height: 14),
                      // ── Password field with show/hide toggle ──
                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        style: TextStyle(color: theme.onSurface),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle:
                              TextStyle(color: theme.onSurfaceVariant),
                          prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: theme.onSurfaceVariant,
                              size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () => setSheetState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          filled: true,
                          fillColor: theme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.outline.withOpacity(0.5))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: theme.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final name = nameCtrl.text.trim();
                                  final email = emailCtrl.text.trim();
                                  final industry =
                                      industryCtrl.text.trim();
                                  final location =
                                      locationCtrl.text.trim();
                                  final password =
                                      passwordCtrl.text.trim();

                                  if (name.isEmpty ||
                                      email.isEmpty ||
                                      industry.isEmpty ||
                                      location.isEmpty ||
                                      password.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                          Text("Please fill all fields"),
                                    ));
                                    return;
                                  }

                                  setSheetState(
                                      () => isSaving = true);

                                  try {
                                    if (isEdit) {
                                      await _db
                                          .from('Company_profile')
                                          .update({
                                            'name': name,
                                            'email': email,
                                            'industry': industry,
                                            'location': location,
                                            'password': password,
                                          })
                                          .eq('id', existing['id']);
                                    } else {
                                      await _db
                                          .from('Company_profile')
                                          .insert({
                                        'name': name,
                                        'email': email,
                                        'industry': industry,
                                        'location': location,
                                        'password': password,
                                      });
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      await _fetchCompanies();
                                      ScaffoldMessenger.of(
                                              this.context)
                                          .showSnackBar(SnackBar(
                                        content: Text(isEdit
                                            ? "Company updated successfully"
                                            : "Company added successfully"),
                                      ));
                                    }
                                  } catch (e) {
                                    setSheetState(
                                        () => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Error: $e')));
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEdit
                                ? _facultyIndigo
                                : _accentTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : Icon(
                                  isEdit
                                      ? Icons.save_rounded
                                      : Icons.add_rounded,
                                  color: Colors.white),
                          label: Text(
                            isEdit ? "Save Changes" : "Add Company",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
      },
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ColorScheme theme,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: theme.onSurfaceVariant, size: 20),
        filled: true,
        fillColor: theme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.outline.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── DELETE COMPANY ──
  Future<void> _deleteCompany(Map<String, dynamic> company) async {
    final theme = Theme.of(context).colorScheme;
    final id = company['id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Company',
            style: TextStyle(
                color: theme.onSurface, fontWeight: FontWeight.bold)),
        content: RichText(
          text: TextSpan(
            style: TextStyle(color: theme.onSurfaceVariant, fontSize: 14),
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: company['name'] ?? 'this company',
                style: TextStyle(
                    color: theme.onSurface, fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
                foregroundColor: theme.onSurfaceVariant),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _db.from('Company_profile').delete().eq('id', id);
      await _fetchCompanies();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final filtered = _filteredCompanies;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Companies",
            style: TextStyle(
                color: theme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: theme.surface,
        elevation: 0,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: _facultyIndigo,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -sh * 0.1,
            left: -sw * 0.2,
            child: _Blob(
                size: sw * 0.8,
                color: _facultyIndigo.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -sh * 0.08,
            right: -sw * 0.15,
            child: _Blob(
                size: sw * 0.65,
                color: _accentTeal.withOpacity(0.06)),
          ),

          Column(
            children: [
              // ── Stats banner ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _facultyIndigo.withOpacity(0.85),
                        _accentTeal.withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_companies.length} Registered Companies",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Manage your partner companies",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.onSurface),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Search by name, industry or location...",
                    hintStyle:
                        TextStyle(color: theme.onSurfaceVariant, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: theme.onSurfaceVariant),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: theme.onSurfaceVariant, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: theme.outline.withOpacity(0.4))),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // ── Company list ──
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: theme.primary))
                    : filtered.isEmpty
                        ? _buildEmptyState(theme)
                        : RefreshIndicator(
                            color: theme.primary,
                            onRefresh: _fetchCompanies,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 100),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildCompanyCard(
                                      filtered[index], theme),
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),

      // ── FAB to add ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: _accentTeal,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text("Add Company",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.business_outlined,
                size: 48, color: theme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? "No companies match \"$_searchQuery\""
                : "No companies registered yet",
            style: TextStyle(
                fontSize: 15,
                color: theme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Tap the button below to add your first company",
              style:
                  TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyCard(
      Map<String, dynamic> company, ColorScheme theme) {
    final name = company['name'] ?? 'Unknown';
    final email = company['email'] ?? '';
    final industry = company['industry'] ?? '';
    final location = company['location'] ?? '';
    final password = company['password'] ?? '';
    final maskedPassword = password.isNotEmpty
        ? '●' * (password.length.clamp(4, 12))
        : '—';

    // Pick an avatar color based on the first letter
    final avatarColors = [
      _facultyIndigo,
      _accentTeal,
      const Color(0xFF7B1FA2),
      const Color(0xFF0288D1),
      const Color(0xFF388E3C),
    ];
    final colorIndex = name.isNotEmpty ? name.codeUnitAt(0) % avatarColors.length : 0;
    final avatarColor = avatarColors[colorIndex];

    return Card(
      color: theme.surfaceContainerHighest,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.outline.withOpacity(0.15))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: avatarColor),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.onSurface)),
                  const SizedBox(height: 4),
                  _infoChip(Icons.email_outlined, email, theme),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                          child: _infoChip(
                              Icons.category_outlined, industry, theme)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _infoChip(
                              Icons.location_on_outlined, location, theme)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _infoChip(Icons.lock_outline_rounded, maskedPassword, theme),
                  const SizedBox(height: 12),
                  // Action row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditDialog(company),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _facultyIndigo,
                            side: BorderSide(
                                color: _facultyIndigo.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text("Edit",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteCompany(company),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                                color: Colors.red.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16),
                          label: const Text("Delete",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, ColorScheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style:
                TextStyle(fontSize: 12, color: theme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 4: PROFILE & LOGOUT
// ──────────────────────────────────────────────────────────────────────────────
class FacultyProfilePage extends StatefulWidget {
  const FacultyProfilePage({super.key});

  @override
  State<FacultyProfilePage> createState() => _FacultyProfilePageState();
}

class _FacultyProfilePageState extends State<FacultyProfilePage> {
  // Stats loaded from Supabase
  int _announcementCount = 0;
  int _pendingVettingCount = 0;
  int _companiesCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final facultyId = FacultySession.facultyId;
      final results = await Future.wait([
        // Announcements posted by this faculty
        _db
            .from('university_announcements')
            .select('id')
            .eq('faculty_id', facultyId ?? 0),
        // All job postings (no status column — count all pending review)
        _db
            .from('Job_postings')
            .select('id'),
        // Total companies
        _db.from('Company_profile').select('id'),
      ]);

      if (mounted) {
        setState(() {
          _announcementCount = (results[0] as List).length;
          _pendingVettingCount = (results[1] as List).length;
          _companiesCount = (results[2] as List).length;
          _statsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  /// Opens a bottom sheet to edit the faculty's display name and department.
  void _showEditProfileSheet(ColorScheme theme) {
    final nameCtrl =
        TextEditingController(text: FacultySession.name ?? '');
    final deptCtrl =
        TextEditingController(text: FacultySession.department ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: theme.outline,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Edit Profile",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.onSurface)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    labelText: "Display Name",
                    prefixIcon:
                        Icon(Icons.person_outline, color: theme.primary),
                    labelStyle:
                        TextStyle(color: theme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.outline)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: deptCtrl,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    labelText: "Department",
                    prefixIcon: Icon(Icons.school_outlined,
                        color: theme.primary),
                    labelStyle:
                        TextStyle(color: theme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: theme.outline)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setSheet(() => isSaving = true);
                            try {
                              await _db
                                  .from('faculty_profile')
                                  .update({
                                    'name': nameCtrl.text.trim(),
                                    'department': deptCtrl.text.trim(),
                                  })
                                  .eq('id',
                                      FacultySession.facultyId ?? 0);
                              FacultySession.name = nameCtrl.text.trim();
                              FacultySession.department =
                                  deptCtrl.text.trim();
                              if (mounted) {
                                Navigator.pop(ctx);
                                setState(() {});
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Profile updated!')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(
                                            'Error updating: $e')));
                              }
                            } finally {
                              setSheet(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _facultyIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded),
                    label: const Text("Save Changes",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a bottom sheet to change the faculty's password.
  void _showChangePasswordSheet(ColorScheme theme) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true; // ← separate toggle for confirm field
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: theme.outline,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text("Change Password",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.onSurface)),
                const SizedBox(height: 20),
                _passwordField(
                  controller: currentCtrl,
                  label: "Current Password",
                  obscure: obscureCurrent,
                  onToggle: () =>
                      setSheet(() => obscureCurrent = !obscureCurrent),
                  theme: theme,
                ),
                const SizedBox(height: 14),
                _passwordField(
                  controller: newCtrl,
                  label: "New Password",
                  obscure: obscureNew,
                  onToggle: () =>
                      setSheet(() => obscureNew = !obscureNew),
                  theme: theme,
                ),
                const SizedBox(height: 14),
                _passwordField(
                  controller: confirmCtrl,
                  label: "Confirm New Password",
                  obscure: obscureConfirm, // ← fixed: own toggle
                  onToggle: () =>
                      setSheet(() => obscureConfirm = !obscureConfirm),
                  theme: theme,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (currentCtrl.text.trim().isEmpty ||
                                newCtrl.text.trim().isEmpty ||
                                confirmCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content:
                                          Text('Please fill all fields.')));
                              return;
                            }
                            if (newCtrl.text != confirmCtrl.text) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Passwords do not match.')));
                              return;
                            }
                            if (newCtrl.text.length < 6) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Password must be at least 6 characters.')));
                              return;
                            }
                            setSheet(() => isSaving = true);
                            try {
                              // Verify current password then update
                              // ← fixed table name: faculty_profile (lowercase)
                              final check = await _db
                                  .from('faculty_profile')
                                  .select('id')
                                  .eq('id',
                                      FacultySession.facultyId ?? 0)
                                  .eq('password', currentCtrl.text.trim())
                                  .maybeSingle();
                              if (check == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Current password is incorrect.')));
                                }
                                setSheet(() => isSaving = false);
                                return;
                              }
                              // ← fixed table name: faculty_profile (lowercase)
                              await _db
                                  .from('faculty_profile')
                                  .update({'password': newCtrl.text.trim()})
                                  .eq('id',
                                      FacultySession.facultyId ?? 0);
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Password changed successfully!')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text('Error: $e')));
                              }
                            } finally {
                              setSheet(() => isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _facultyIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.lock_outline_rounded),
                    label: const Text("Update Password",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required ColorScheme theme,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: theme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: theme.primary),
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: theme.onSurfaceVariant),
          onPressed: onToggle,
        ),
        labelStyle: TextStyle(color: theme.onSurfaceVariant),
        filled: true,
        fillColor: theme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.outline)),
      ),
    );
  }

  void _confirmLogout(BuildContext context, ColorScheme theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Log Out',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: theme.onSurface)),
        content: Text('Are you sure you want to log out?',
            style: TextStyle(color: theme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: theme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              FacultySession.clear();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final isDark = theme.brightness == Brightness.dark;
    final indigoText =
        isDark ? Colors.indigo.shade200 : _facultyIndigo;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        title: Text("My Profile",
            style: TextStyle(
                color: theme.onSurface, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: theme.surface,
        elevation: 0,
        actions: [
          // Edit profile shortcut
          IconButton(
            icon: Icon(Icons.edit_outlined, color: _facultyIndigo),
            tooltip: "Edit Profile",
            onPressed: () => _showEditProfileSheet(theme),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) => IconButton(
              onPressed: () => themeProvider.toggleTheme(),
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: _facultyIndigo,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -sh * 0.15,
            left: -sw * 0.2,
            child: _Blob(
                size: sw * 0.85,
                color: _facultyIndigo.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -sh * 0.1,
            right: -sw * 0.15,
            child: _Blob(
                size: sw * 0.7, color: _accentTeal.withOpacity(0.06)),
          ),
          RefreshIndicator(
            color: _facultyIndigo,
            onRefresh: _loadStats,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              children: [
                // ── AVATAR + NAME CARD ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _facultyIndigo.withOpacity(0.85),
                        const Color(0xFF818CF8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _facultyIndigo.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with gradient border
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.8),
                              Colors.white.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        FacultySession.name ?? "Faculty Member",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FacultySession.email ?? "email@university.edu",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // Badges row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (FacultySession.designation != null &&
                              FacultySession.designation!.isNotEmpty)
                            _badge(
                                FacultySession.designation!,
                                Icons.workspace_premium_outlined,
                                Colors.white.withOpacity(0.25)),
                          const SizedBox(width: 8),
                          _badge(
                              FacultySession.department ?? "Department",
                              Icons.school_outlined,
                              Colors.white.withOpacity(0.25)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── STATS ROW ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        theme,
                        icon: Icons.campaign_rounded,
                        label: "Announcements",
                        value: _statsLoading
                            ? '—'
                            : '$_announcementCount',
                        color: _facultyIndigo,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        theme,
                        icon: Icons.pending_actions_rounded,
                        label: "Pending Jobs",
                        value: _statsLoading
                            ? '—'
                            : '$_pendingVettingCount',
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        theme,
                        icon: Icons.business_rounded,
                        label: "Companies",
                        value: _statsLoading
                            ? '—'
                            : '$_companiesCount',
                        color: _accentTeal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── QUICK ACTIONS ─────────────────────────────────────
                Text("Quick Actions",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.onSurface)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _actionTile(
                        theme,
                        icon: Icons.edit_outlined,
                        label: "Edit Profile",
                        color: _facultyIndigo,
                        onTap: () => _showEditProfileSheet(theme),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionTile(
                        theme,
                        icon: Icons.lock_outline_rounded,
                        label: "Change Password",
                        color: _accentTeal,
                        onTap: () => _showChangePasswordSheet(theme),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _actionTile(
                        theme,
                        icon: Icons.refresh_rounded,
                        label: "Refresh Stats",
                        color: Colors.deepPurple,
                        onTap: _loadStats,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionTile(
                        theme,
                        icon: Icons.info_outline_rounded,
                        label: "About App",
                        color: Colors.blueGrey,
                        onTap: () => _showAboutSheet(theme),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── ACCOUNT INFO SECTION ──────────────────────────────
                Text("Account Information",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: theme.onSurface)),
                const SizedBox(height: 12),
                _infoRow(
                  theme,
                  icon: Icons.badge_outlined,
                  label: "Faculty ID",
                  value: '#${FacultySession.facultyId ?? '—'}',
                ),
                _infoRow(
                  theme,
                  icon: Icons.alternate_email_rounded,
                  label: "Email",
                  value:
                      FacultySession.email ?? "—",
                ),
                _infoRow(
                  theme,
                  icon: Icons.school_outlined,
                  label: "Department",
                  value: FacultySession.department ?? "—",
                ),
                _infoRow(
                  theme,
                  icon: Icons.workspace_premium_outlined,
                  label: "Designation",
                  value: FacultySession.designation ?? "—",
                ),

                const SizedBox(height: 28),

                // ── LOGOUT ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, theme),
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.red, size: 18),
                    label: const Text('Log Out',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.red, width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  String _initials() {
    final name = FacultySession.name ?? '';
    final parts =
        name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'F';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  Widget _badge(String label, IconData icon, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statCard(ColorScheme theme,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: theme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionTile(ColorScheme theme,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: theme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.onSurface)),
              ),
              Icon(Icons.chevron_right,
                  size: 16, color: theme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ColorScheme theme,
      {required IconData icon,
      required String label,
      required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _facultyIndigo),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(ColorScheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: theme.outline,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), _facultyIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school_rounded,
                  color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            Text("Faculty Portal",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.onSurface)),
            const SizedBox(height: 6),
            Text("Version 1.0.0",
                style: TextStyle(color: theme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(
              "A dedicated portal for faculty members to manage internship vetting, post university announcements, and oversee company registrations.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.onSurfaceVariant,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.outline),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Close",
                    style: TextStyle(color: theme.onSurface)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 5: STUDENT REPORTS
// ──────────────────────────────────────────────────────────────────────────────
class StudentReportPage extends StatefulWidget {
  const StudentReportPage({super.key});
  @override
  State<StudentReportPage> createState() => _StudentReportPageState();
}

class _StudentReportPageState extends State<StudentReportPage> {
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _db
          .from('User_profile')
          .select('id, name, email')
          .order('name', ascending: true);
      final list = List<Map<String, dynamic>>.from(rows as List);
      if (mounted) {
        setState(() {
          _students = list;
          _filtered = list;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _students
          : _students
              .where((s) =>
                  (s['name'] ?? '').toString().toLowerCase().contains(q) ||
                  (s['email'] ?? '').toString().toLowerCase().contains(q))
              .toList();
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.surface,
        elevation: 0,
        title: Text('Student Reports',
            style: TextStyle(
                color: theme.onSurface, fontWeight: FontWeight.bold)),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => IconButton(
              onPressed: tp.toggleTheme,
              icon: Icon(
                tp.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: _facultyIndigo,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.08,
            left: -MediaQuery.of(context).size.width * 0.2,
            child: _Blob(
                size: MediaQuery.of(context).size.width * 0.75,
                color: _facultyIndigo.withOpacity(0.06)),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.06,
            right: -MediaQuery.of(context).size.width * 0.15,
            child: _Blob(
                size: MediaQuery.of(context).size.width * 0.6,
                color: _accentTeal.withOpacity(0.05)),
          ),
          Column(
            children: [
              // ── Search bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: theme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    hintStyle: TextStyle(color: theme.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search, color: theme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text('${_filtered.length} student(s)',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // ── List ────────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(color: theme.primary))
                    : _filtered.isEmpty
                        ? Center(
                            child: Text('No students found.',
                                style:
                                    TextStyle(color: theme.onSurfaceVariant)))
                        : RefreshIndicator(
                            color: theme.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final s = _filtered[i];
                                final name =
                                    (s['name'] ?? 'Unknown').toString();
                                final email =
                                    (s['email'] ?? '').toString();
                                return _StudentCard(
                                  name: name,
                                  email: email,
                                  initials: _initials(name),
                                  onViewReport: () =>
                                      _openReport(context, s),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openReport(BuildContext ctx, Map<String, dynamic> student) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentReportSheet(student: student),
    );
  }
}

// ── Student card ──────────────────────────────────────────────────────────────
class _StudentCard extends StatelessWidget {
  final String name, email, initials;
  final VoidCallback onViewReport;
  const _StudentCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.onViewReport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Card(
      color: theme.surfaceContainerHighest,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onViewReport,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), _facultyIndigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.onSurface)),
                    const SizedBox(height: 2),
                    Text(email,
                        style: TextStyle(
                            fontSize: 12, color: theme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _facultyIndigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.description_outlined,
                        size: 14, color: _facultyIndigo),
                    SizedBox(width: 4),
                    Text('Report',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _facultyIndigo)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}

// ── Full report bottom sheet ──────────────────────────────────────────────────
class _StudentReportSheet extends StatefulWidget {
  final Map<String, dynamic> student;
  const _StudentReportSheet({required this.student});
  @override
  State<_StudentReportSheet> createState() => _StudentReportSheetState();
}

class _StudentReportSheetState extends State<_StudentReportSheet> {
  List<Map<String, dynamic>> _internships = [];
  List<Map<String, dynamic>> _certificates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = widget.student['id'];
    try {
      final results = await Future.wait([
        // Accepted internship applications with job details
        _db
            .from('Job_applications')
            .select('*, Job_postings(title, company_id, location, duration, Company_profile(name))')
            .eq('student_id', userId)
            .eq('status', 'accepted'),
        // All certificates
        _db.from('Certificates').select().eq('user_id', userId).order('date', ascending: false),
      ]);
      if (mounted) {
        setState(() {
          _internships = List<Map<String, dynamic>>.from(results[0] as List);
          _certificates = List<Map<String, dynamic>>.from(results[1] as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  String _fmt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  Future<void> _printReport() async {
    final student = widget.student;
    final name = (student['name'] ?? 'Unknown').toString();
    final email = (student['email'] ?? '').toString();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Student Internship Report',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.indigo, width: 1.5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text('OFFICIAL RECORD',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo)),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.indigo, thickness: 2),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (pw.Context ctx) => [
          // ── Student Info ──────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.indigo50,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(name,
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    if (email.isNotEmpty)
                      _pdfRow(Icons.email, 'Email', email),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Internship History ────────────────────────────────────────
          pw.Text('Internship History',
              style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800)),
          pw.SizedBox(height: 2),
          pw.Divider(color: PdfColors.indigo200),
          pw.SizedBox(height: 8),
          if (_internships.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text('No accepted internships on record.',
                  style: const pw.TextStyle(color: PdfColors.grey600)),
            )
          else
            ..._internships.map((app) {
              final job = app['Job_postings'] as Map<String, dynamic>?;
              final company = job?['Company_profile'] as Map<String, dynamic>?;
              final jobTitle = (job?['title'] ?? 'Unknown Role').toString();
              final companyName = (company?['name'] ?? 'Unknown Company').toString();
              final location = (job?['location'] ?? '').toString();
              final duration = (job?['duration'] ?? '').toString();
              final appliedAt = _fmt(app['applied_at']?.toString());

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.indigo200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(jobTitle,
                            style: pw.TextStyle(
                                fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.teal50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text('Accepted',
                              style: const pw.TextStyle(
                                  fontSize: 9, color: PdfColors.teal800)),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    _pdfRow(Icons.business, 'Company', companyName),
                    if (location.isNotEmpty)
                      _pdfRow(Icons.location_on, 'Location', location),
                    if (duration.isNotEmpty)
                      _pdfRow(Icons.access_time, 'Duration', duration),
                    _pdfRow(Icons.event, 'Applied On', appliedAt),
                  ],
                ),
              );
            }),
          pw.SizedBox(height: 20),

          // ── Certificates ──────────────────────────────────────────────
          pw.Text('Certificates & Achievements',
              style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo800)),
          pw.SizedBox(height: 2),
          pw.Divider(color: PdfColors.indigo200),
          pw.SizedBox(height: 8),
          if (_certificates.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text('No certificates on record.',
                  style: const pw.TextStyle(color: PdfColors.grey600)),
            )
          else
            ..._certificates.asMap().entries.map((entry) {
              final i = entry.key;
              final cert = entry.value;
              final title = (cert['title'] ?? 'Untitled').toString();
              final desc = (cert['description'] ?? '').toString();
              final date = _fmt(cert['date']?.toString());
              final isVerified = cert['is_verified'] == true;

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: isVerified
                          ? PdfColors.teal200
                          : PdfColors.orange200),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 28,
                      height: 28,
                      decoration: pw.BoxDecoration(
                        color: isVerified ? PdfColors.teal100 : PdfColors.orange100,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text('${i + 1}',
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: isVerified
                                    ? PdfColors.teal800
                                    : PdfColors.orange800)),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(title,
                                  style: pw.TextStyle(
                                      fontSize: 13,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: isVerified
                                      ? PdfColors.teal50
                                      : PdfColors.orange50,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.Text(
                                    isVerified ? '✓ Verified' : 'Pending',
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        color: isVerified
                                            ? PdfColors.teal800
                                            : PdfColors.orange800)),
                              ),
                            ],
                          ),
                          if (desc.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(desc,
                                style: const pw.TextStyle(
                                    fontSize: 11, color: PdfColors.grey700)),
                          ],
                          pw.SizedBox(height: 4),
                          _pdfRow(Icons.calendar_today, 'Date', date),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'report_$name.pdf',
    );
  }

  pw.Widget _pdfRow(IconData _, String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3),
        child: pw.Row(
          children: [
            pw.Text('$label: ',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey800)),
          ],
        ),
      );

  // ── In-app report preview ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final student = widget.student;
    final name = (student['name'] ?? 'Unknown').toString();
    final email = (student['email'] ?? '').toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Sheet handle + header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: theme.outline,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Student Report',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500)),
                            Text(name,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.onSurface)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _printReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _facultyIndigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: theme.outlineVariant),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: theme.primary))
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        // Student info card
                        _ReportSection(
                          icon: Icons.person_outline_rounded,
                          title: 'Student Information',
                          color: _facultyIndigo,
                          child: Column(
                            children: [
                              _ReportRow(Icons.email_outlined, 'Email', email.isEmpty ? '—' : email),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Internship history
                        _ReportSection(
                          icon: Icons.work_history_outlined,
                          title: 'Internship History',
                          subtitle: '${_internships.length} accepted internship(s)',
                          color: _accentTeal,
                          child: _internships.isEmpty
                              ? _EmptyHint('No accepted internships on record.')
                              : Column(
                                  children: _internships.map((app) {
                                    final job = app['Job_postings'] as Map<String, dynamic>?;
                                    final company = job?['Company_profile'] as Map<String, dynamic>?;
                                    final jobTitle = (job?['title'] ?? 'Unknown Role').toString();
                                    final companyName = (company?['name'] ?? 'Unknown Company').toString();
                                    final location = (job?['location'] ?? '').toString();
                                    final duration = (job?['duration'] ?? '').toString();
                                    final appliedAt = _fmt(app['applied_at']?.toString());
                                    return _InternshipTile(
                                      jobTitle: jobTitle,
                                      companyName: companyName,
                                      location: location,
                                      duration: duration,
                                      appliedAt: appliedAt,
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Certificates
                        _ReportSection(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Certificates & Achievements',
                          subtitle: '${_certificates.length} certificate(s)',
                          color: const Color(0xFFD97706),
                          child: _certificates.isEmpty
                              ? _EmptyHint('No certificates uploaded.')
                              : Column(
                                  children: _certificates
                                      .map((c) => _CertTile(cert: c, fmt: _fmt))
                                      .toList(),
                                ),
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

// ── Reusable report UI widgets ────────────────────────────────────────────────
class _ReportSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final Widget child;
  const _ReportSection({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.onSurface)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 11, color: theme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: color.withOpacity(0.15)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ReportRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _facultyIndigo),
          const SizedBox(width: 8),
          Text('$label:  ',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.onSurfaceVariant)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.onSurface),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _InternshipTile extends StatelessWidget {
  final String jobTitle, companyName, location, duration, appliedAt;
  const _InternshipTile({
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.duration,
    required this.appliedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accentTeal.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(jobTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Accepted',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _accentTeal)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _IRow(Icons.business_outlined, companyName),
          if (location.isNotEmpty) _IRow(Icons.location_on_outlined, location),
          if (duration.isNotEmpty) _IRow(Icons.access_time_rounded, duration),
          _IRow(Icons.event_outlined, 'Applied: $appliedAt'),
        ],
      ),
    );
  }
}

class _IRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: theme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12, color: theme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  final Map<String, dynamic> cert;
  final String Function(String?) fmt;
  const _CertTile({required this.cert, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final title = (cert['title'] ?? 'Untitled').toString();
    final desc = (cert['description'] ?? '').toString();
    final date = fmt(cert['date']?.toString());
    final isVerified = cert['is_verified'] == true;
    final imageUrl = (cert['image_url'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isVerified
                ? Colors.green.withOpacity(0.3)
                : Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isVerified
                        ? Icons.verified_rounded
                        : Icons.pending_outlined,
                    size: 16,
                    color: isVerified ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.onSurface)),
                      if (desc.isNotEmpty)
                        Text(desc,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isVerified ? '✓ Verified' : 'Pending',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isVerified ? Colors.green : Colors.orange),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: theme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(date,
                    style: TextStyle(
                        fontSize: 11, color: theme.onSurfaceVariant)),
              ],
            ),
          ),
          // Certificate image thumbnail
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              child: _buildCertImage(imageUrl),
            ),
        ],
      ),
    );
  }

  Widget _buildCertImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes,
            height: 160, width: double.infinity, fit: BoxFit.cover);
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return Image.network(url,
        height: 160, width: double.infinity, fit: BoxFit.cover);
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(message,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// DECORATOR BLOB WIDGET
// ──────────────────────────────────────────────────────────────────────────────
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