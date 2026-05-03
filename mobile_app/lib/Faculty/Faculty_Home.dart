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
const Color _facultyIndigo = Color(0xFF303F9F);
const Color _bgLight = Color(0xFFF8F9FD);
const Color _primaryTeal = Color(0xFF26A69A);

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
          selectedItemColor: const Color(0xFF26A69A), // Matching your Teal Dashboard color
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Faculty Vetting"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Internships"),
            Tab(text: "Certificates"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInternshipList(),
          _buildUsersWithCertificates(),
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
          return const Center(
            child: Text("No certificates uploaded yet."),
          );
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
          future: _db
              .from('User_profile')
              .select()
              .inFilter('id', userIds),
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
                    leading: CircleAvatar(
                      child: Text(name[0].toUpperCase()),
                    ),
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
                  return const Center(
                      child: Text("No certificates found."));
                }

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "Certificates: $name",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
          imageWidget = Image.memory(
            bytes,
            height: 200,
            fit: BoxFit.cover,
          );
        } catch (e) {
          imageWidget = const Text("Invalid image");
        }
      } else {
        imageWidget = Image.network(
          imageUrl,
          height: 200,
          fit: BoxFit.cover,
        );
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
                  child: const Text("Reject",
                      style: TextStyle(color: Colors.red)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _db.from('Certificates').update({
                      'is_verified': true
                    }).eq('id', cert['id']);
                    Navigator.pop(context);
                  },
                  child: const Text("Accept"),
                ),
              ),
            ],
          )
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
              child: Center(
                child: _buildFullImage(imageUrl),
              ),
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

  // ✅ HANDLE IMAGE TYPE
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

  Widget _buildInternshipList() =>
      const Center(child: Text("Internships"));
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
          const SnackBar(content: Text("Announcement Broadcasted Successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        // This will now catch and show the correct error if any remaining schema issues exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("Post Announcement", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Announcement Details", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title (e.g., Internship Fair 2025)",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedTag,
              decoration: InputDecoration(
                labelText: "Category Tag",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _tags.map((tag) => DropdownMenuItem(value: tag, child: Text(tag))).toList(),
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
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isPosting ? null : _broadcastAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isPosting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.campaign_rounded, color: Colors.white),
                label: const Text("Broadcast to Students", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 3: PROFILE & LOGOUT
// ──────────────────────────────────────────────────────────────────────────────
class FacultyProfilePage extends StatelessWidget {
  const FacultyProfilePage({super.key});

  // Local constants for your styling
  static const Color _textGrey = Colors.grey;
  static const Color _white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        title: const Text("Faculty Profile", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // Removes the back arrow
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: _facultyIndigo,
              child: Icon(Icons.person, size: 45, color: Colors.white),
            ),
            const SizedBox(height: 16),
            
            // Syncing with your FacultySession variables
            Text(FacultySession.name ?? "Faculty Member", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(FacultySession.email ?? "email@university.edu", 
                style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 8),
            Chip(
              label: Text(FacultySession.department ?? "Department"),
              backgroundColor: Colors.indigo[50],
            ),
            
            const Spacer(),

            // --- LOGOUT BUTTON SECTION ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text('Log Out',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel',
                                style: TextStyle(color: _textGrey))),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx); 
                            FacultySession.clear(); 
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: _white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}