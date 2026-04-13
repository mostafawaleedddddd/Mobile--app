import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

// ─── COLORS ────────────────────────────
const _blue      = Color(0xFF3B82F6);
const _blueLight = Color(0xFFEFF6FF);
const _bluePale  = Color(0xFFF0F7FF);
const _textDark  = Color(0xFF1E293B);
const _textGrey  = Color(0xFF64748B);
const _white     = Colors.white;

// ─── PROFILE SCREEN ────────────────────
class ProfileScreen extends StatefulWidget {
  final int id;
  const ProfileScreen({super.key, required this.id});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final data = await supabase
          .from('User_profile')
          .select()
          .eq('id', widget.id)
          .single();

      setState(() {
        _user = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getInitials(String name) {
    return name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bluePale,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: _bluePale,
        body: Center(child: Text('No user found.')),
      );
    }

    final name        = _user!['name']         ?? '';
    final email       = _user!['email']        ?? '';
    final phone       = _user!['phone']        ?? '';
    final accountType = _user!['account_type'] ?? '';
    final initials    = _getInitials(name);

    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bluePale,
      body: Stack(
        children: [
          Positioned(
            top: -sh * 0.07,
            left: -sw * 0.18,
            child: _Blob(size: sw * 0.85, color: _blue.withOpacity(0.09)),
          ),
          Positioned(
            bottom: -sh * 0.06,
            right: -sw * 0.14,
            child: _Blob(size: sw * 0.65, color: _blue.withOpacity(0.07)),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [

                // ── App Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Profile',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.3)),
                        _IconBtn(icon: Icons.settings_outlined, onTap: () {}),
                      ],
                    ),
                  ),
                ),

                // ── Hero Card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.10),
                            blurRadius: 30,
                            spreadRadius: 1,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF60A5FA), _blue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _blue.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    initials,         // ← from DB
                                    style: const TextStyle(
                                      color: _white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + badge
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,         // ← from DB
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _textDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (accountType.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _blueLight,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified_rounded,
                                                size: 12, color: _blue),
                                            const SizedBox(width: 3),
                                            Text(accountType, // ← from DB
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: _blue,
                                                    fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Email
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        size: 13, color: _textGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(email, // ← from DB
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12, color: _textGrey)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Phone
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 13, color: _textGrey),
                                    const SizedBox(width: 4),
                                    Text(phone, // ← from DB
                                        style: const TextStyle(
                                            fontSize: 12, color: _textGrey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Stats Row ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        _StatCard(value: '0', label: 'Internships\nApplied'),
                        const SizedBox(width: 10),
                        _StatCard(value: '0', label: 'Certificates\nUploaded'),
                        const SizedBox(width: 10),
                        _StatCard(value: '0', label: 'Surveys\nCompleted'),
                      ],
                    ),
                  ),
                ),

                // ── About ──
                SliverToBoxAdapter(child: _SectionTitle('About')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _WhiteCard(
                      child: Text('No about info added yet.',
                          style: TextStyle(
                              fontSize: 13, color: _textGrey, height: 1.6)),
                    ),
                  ),
                ),

                // ── Skills ──
                SliverToBoxAdapter(child: _SectionTitle('Skills')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _WhiteCard(
                      child: Text('No skills added yet.',
                          style: TextStyle(fontSize: 13, color: _textGrey)),
                    ),
                  ),
                ),

                // ── Education ──
                SliverToBoxAdapter(child: _SectionTitle('Education')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const _WhiteCard(
                      child: Text('No education added yet.',
                          style: TextStyle(fontSize: 13, color: _textGrey)),
                    ),
                  ),
                ),

                // ── Certificates ──
                SliverToBoxAdapter(child: _SectionTitle('Certificates')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WhiteCard(
                      child: Column(
                        children: [
                          const Text('No certificates uploaded yet.',
                              style:
                                  TextStyle(fontSize: 13, color: _textGrey)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _blueLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _blue.withOpacity(0.3), width: 1),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file_rounded,
                                      size: 16, color: _blue),
                                  SizedBox(width: 8),
                                  Text('Upload New Certificate',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: _blue,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Rating & Reviews ──
                SliverToBoxAdapter(child: _SectionTitle('Rating & Reviews')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: _WhiteCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('0.0',
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: _textDark,
                                  height: 1)),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              5,
                              (i) => const Icon(Icons.star_outline_rounded,
                                  size: 18, color: Color(0xFFFBBF24)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('No reviews yet.',
                              style:
                                  TextStyle(fontSize: 12, color: _textGrey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(),
    );
  }
}

// ─── STAT CARD ──────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _blue)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: _textGrey, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION TITLE ──────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark)),
          GestureDetector(
            onTap: () {},
            child: const Text('Edit',
                style: TextStyle(
                    fontSize: 13,
                    color: _blue,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── WHITE CARD ─────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── BOTTOM NAV BAR ─────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.08),
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
                active: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LandingPage()),
                  );
                },
              ),
              _NavItem(
                  icon: Icons.work_outline_rounded,
                  label: 'Internships',
                  active: false),
              _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: true),
              _NavItem(
                  icon: Icons.assignment_outlined,
                  label: 'Surveys',
                  active: false),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SMALL WIDGETS ──────────────────────
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: _textDark, size: 20),
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active ? _blueLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: active ? _blue : _textGrey, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: active ? _blue : _textGrey,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}