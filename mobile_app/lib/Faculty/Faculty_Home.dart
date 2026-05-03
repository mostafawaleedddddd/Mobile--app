// import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'Faculty_Model.dart';
import 'Faculty_Session.dart';
// import 'Faculty_Auth.dart';
// Assuming these are your existing imports for navigation
// import 'package:your_app/user_role_screen.dart';

final _db = Supabase.instance.client;

// ─── COLORS ────────────────────────────────
const Color _facultyIndigo = Color(0xFF303F9F);
const Color _facultyIndigoLight = Color(0xFFEEF0FF);
const Color _facultyIndigoPale = Color(0xFFF5F6FF);
const Color _accentTeal = Color(0xFF26A69A);
const Color _white = Colors.white;
const Color _textDark = Color(0xFF1E293B);
const Color _textGrey = Color(0xFF64748B);

class FacultyHomePage extends StatefulWidget {
  final int facultyId;
  const FacultyHomePage({super.key, required this.facultyId});

  @override
  State<FacultyHomePage> createState() => _FacultyHomePageState();
}

class _FacultyHomePageState extends State<FacultyHomePage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const ReviewQueuePage(),
      PostAnnouncementPage(facultyId: FacultySession.facultyId ?? 0),
      const Center(child: Text("Student Management Page")),
      const FacultyProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(
            0xFF26A69A,
          ), // Matching your Teal Dashboard color
          unselectedItemColor: Colors.grey[500],
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
              label: 'Applicants',
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
  const ReviewQueuePage({super.key});

  @override
  State<ReviewQueuePage> createState() => _ReviewQueuePageState();
}

class _ReviewQueuePageState extends State<ReviewQueuePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _facultyIndigoPale,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Faculty Vetting"),
        backgroundColor: _facultyIndigoPale,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
            children: [_buildInternshipList(), _buildUsersWithCertificates()],
          ),
        ],
      ),
    );
  }

  // ✅ USERS WITH CERTIFICATES
  Widget _buildUsersWithCertificates() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db.from('Certificates').select(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final certificates = snapshot.data!;

        if (certificates.isEmpty) {
          return const Center(child: Text("No certificates uploaded yet."));
        }

        // ✅ GROUP BY user_id
        final Map<int, List<Map<String, dynamic>>> grouped = {};

        for (var cert in certificates) {
          final userId = cert['user_id'];
          if (userId == null) continue;

          grouped.putIfAbsent(userId, () => []);
          grouped[userId]!.add(cert);
        }

        final userIds = grouped.keys.toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _db.from('User_profile').select().inFilter('id', userIds),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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
                  child: ListTile(
                    leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                    title: Text(name),
                    subtitle: Text("$count certificate(s)"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showCertificates(userId, name);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ✅ SHOW CERTIFICATES
  void _showCertificates(int userId, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          builder: (_, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _db
                  .from('Certificates')
                  .select()
                  .eq('user_id', userId)
                  .limit(20),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final certs = snapshot.data!;

                if (certs.isEmpty) {
                  return const Center(child: Text("No certificates found."));
                }

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Certificates: $name",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: certs.length,
                        itemBuilder: (context, i) => _certificateCard(certs[i]),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ✅ CERTIFICATE CARD
  Widget _certificateCard(Map<String, dynamic> cert) {
    final imageUrl = cert['image_url'] ?? '';

    Widget imageWidget = const SizedBox();

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('data:image')) {
        try {
          final bytes = base64Decode(imageUrl.split(',').last);
          imageWidget = Image.memory(bytes, height: 200, fit: BoxFit.cover);
        } catch (e) {
          imageWidget = const Text("Invalid image");
        }
      } else {
        imageWidget = Image.network(imageUrl, height: 200, fit: BoxFit.cover);
      }
    }

    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            title: Text(cert['title'] ?? ''),
            subtitle: Text(cert['date']?.toString() ?? ''),
          ),

          // ✅ CLICK TO ENLARGE
          GestureDetector(
            onTap: () => _showFullImage(imageUrl),
            child: imageWidget,
          ),

          Row(
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
                  child: const Text(
                    "Reject",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
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
        ],
      ),
    );
  }

  // ✅ FULLSCREEN IMAGE VIEWER (ZOOM)
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
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HANDLE IMAGE TYPE
  Widget _buildFullImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return const Text(
          "Invalid image",
          style: TextStyle(color: Colors.white),
        );
      }
    } else {
      return Image.network(imageUrl, fit: BoxFit.contain);
    }
  }

  Widget _buildInternshipList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _db
          .from('Job_postings')
          .select('*, Company_profile(name, email)')
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final internships = snapshot.data!;

        if (internships.isEmpty) {
          return const Center(
            child: Text("No internship postings submitted yet."),
          );
        }

        return RefreshIndicator(
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
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Submitted: $createdAt',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _denyPosting(item),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
    final id = posting['id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Internship'),
        content: const Text(
          'Are you sure you want to deny and remove this internship posting?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
          content: Text('Internship posting denied successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error denying posting: $e')));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 2: ANNOUNCEMENTS (Corrected Column Names)
// ──────────────────────────────────────────────────────────────────────────────
class PostAnnouncementPage extends StatefulWidget {
  // Pass the facultyId to this widget to satisfy the database schema
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

  final List<String> _tags = ['News', 'Event', 'Important', 'Reminder'];

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
            content: Text("Announcement Broadcasted Successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // This will now catch and show the correct error if any remaining schema issues exist
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _facultyIndigoPale,
      appBar: AppBar(
        title: const Text(
          "Post Announcement",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: _facultyIndigoPale,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -sh * 0.12,
            right: -sw * 0.25,
            child: _Blob(
              size: sw * 0.85,
              color: _facultyIndigo.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -sh * 0.1,
            left: -sw * 0.2,
            child: _Blob(size: sw * 0.7, color: _accentTeal.withOpacity(0.06)),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Announcement Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Title (e.g., Internship Fair 2025)",
                    filled: true,
                    fillColor: _white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTag,
                  decoration: InputDecoration(
                    labelText: "Category Tag",
                    filled: true,
                    fillColor: _white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _tags
                      .map(
                        (tag) => DropdownMenuItem(value: tag, child: Text(tag)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedTag = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: "Announcement Description",
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: _white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _isPosting ? null : _broadcastAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentTeal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: _white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.campaign_rounded, color: _white),
                    label: const Text(
                      "Broadcast to Students",
                      style: TextStyle(
                        color: _white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
// SECTION 3: PROFILE & LOGOUT
// ──────────────────────────────────────────────────────────────────────────────
class FacultyProfilePage extends StatelessWidget {
  const FacultyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _facultyIndigoPale,
      appBar: AppBar(
        title: const Text(
          "Faculty Profile",
          style: TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: _facultyIndigoPale,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -sh * 0.15,
            left: -sw * 0.2,
            child: _Blob(
              size: sw * 0.85,
              color: _facultyIndigo.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -sh * 0.1,
            right: -sw * 0.15,
            child: _Blob(size: sw * 0.7, color: _accentTeal.withOpacity(0.06)),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: _facultyIndigo,
                  child: const Icon(Icons.person, size: 45, color: _white),
                ),
                const SizedBox(height: 16),
                Text(
                  FacultySession.name ?? "Faculty Member",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                Text(
                  FacultySession.email ?? "email@university.edu",
                  style: const TextStyle(color: _textGrey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _facultyIndigoLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _facultyIndigo.withOpacity(0.2)),
                  ),
                  child: Text(
                    FacultySession.department ?? "Department",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _facultyIndigo,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Log Out',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          content: const Text(
                            'Are you sure you want to log out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: _textGrey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                FacultySession.clear();
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: _white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Log Out'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
