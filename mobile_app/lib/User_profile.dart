import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Profile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}

// ─── COLORS (same theme as auth) ───────
const _blue      = Color(0xFF3B82F6);
const _blueLight = Color(0xFFEFF6FF);
const _bluePale  = Color(0xFFF0F7FF);
const _textDark  = Color(0xFF1E293B);
const _textGrey  = Color(0xFF64748B);
const _border    = Color(0xFFE2E8F0);
const _white     = Colors.white;

// ─── PROFILE SCREEN ────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _bluePale,
      body: Stack(
        children: [
          // Background blobs (same as auth)
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

          // Content
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
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        _IconBtn(
                          icon: Icons.settings_outlined,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Profile Hero Card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _ProfileHeroCard(),
                  ),
                ),

                // ── Stats Row ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _StatsRow(),
                  ),
                ),

                // ── Section: About ──
                SliverToBoxAdapter(
                  child: _SectionTitle('About'),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _AboutCard(),
                  ),
                ),

                // ── Section: Skills ──
                SliverToBoxAdapter(child: _SectionTitle('Skills')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SkillsCard(),
                  ),
                ),

                // ── Section: Education ──
                SliverToBoxAdapter(child: _SectionTitle('Education')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _EducationCard(),
                  ),
                ),

                // ── Section: Certificates ──
                SliverToBoxAdapter(child: _SectionTitle('Certificates')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _CertificatesCard(),
                  ),
                ),

                // ── Section: Rating & Reviews ──
                SliverToBoxAdapter(child: _SectionTitle('Rating & Reviews')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: _RatingCard(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom action bar ──
      bottomNavigationBar: _BottomBar(),
    );
  }
}

// ─── PROFILE HERO CARD ──────────────────
class _ProfileHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: const Center(
                  child: Text(
                    'JS',
                    style: TextStyle(
                      color: _white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              // Online badge
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

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'John Smith',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Verified badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _blueLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 12, color: _blue),
                          SizedBox(width: 3),
                          Text('Student',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _blue,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Computer Science • 3rd Year',
                  style: TextStyle(fontSize: 13, color: _textGrey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: _textGrey),
                    const SizedBox(width: 3),
                    const Text('Cairo, Egypt',
                        style:
                            TextStyle(fontSize: 12, color: _textGrey)),
                    const SizedBox(width: 12),
                    const Icon(Icons.school_outlined,
                        size: 13, color: _textGrey),
                    const SizedBox(width: 3),
                    const Expanded(
                      child: Text('Cairo University',
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: _textGrey)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Star rating
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                        size: 16,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '4.5',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('(12 reviews)',
                        style:
                            TextStyle(fontSize: 12, color: _textGrey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STATS ROW ──────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: '3', label: 'Internships\nApplied'),
        const SizedBox(width: 10),
        _StatCard(value: '5', label: 'Certificates\nUploaded'),
        const SizedBox(width: 10),
        _StatCard(value: '2', label: 'Surveys\nCompleted'),
      ],
    );
  }
}

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
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: _textGrey,
                height: 1.3,
              ),
            ),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                color: _blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ABOUT CARD ─────────────────────────
class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: const Text(
        'Passionate Computer Science student with a strong interest in mobile development and UI/UX design. Currently seeking internship opportunities to apply my skills in real-world projects.',
        style: TextStyle(
          fontSize: 13,
          color: _textGrey,
          height: 1.6,
        ),
      ),
    );
  }
}

// ─── SKILLS CARD ────────────────────────
class _SkillsCard extends StatelessWidget {
  final _skills = const [
    'Flutter', 'Dart', 'Python', 'UI/UX', 'Firebase', 'Git', 'SQL',
  ];

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _skills
            .map(
              (s) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _blueLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _blue.withOpacity(0.25), width: 1),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── EDUCATION CARD ─────────────────────
class _EducationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: _TimelineItem(
        icon: Icons.school_rounded,
        title: 'Cairo University',
        subtitle: 'B.Sc. Computer Science',
        date: '2022 – Present',
        isLast: true,
      ),
    );
  }
}

// ─── CERTIFICATES CARD ──────────────────
class _CertificatesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        children: [
          _CertItem(
            title: 'Flutter Development Bootcamp',
            issuer: 'Udemy',
            date: 'Jan 2024',
          ),
          const Divider(height: 20, color: _border),
          _CertItem(
            title: 'Google UX Design',
            issuer: 'Google / Coursera',
            date: 'Mar 2024',
          ),
          const SizedBox(height: 12),
          // Upload button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _blueLight,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _blue.withOpacity(0.3), width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded,
                      size: 16, color: _blue),
                  SizedBox(width: 8),
                  Text(
                    'Upload New Certificate',
                    style: TextStyle(
                      fontSize: 13,
                      color: _blue,
                      fontWeight: FontWeight.w600,
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

// ─── RATING CARD ────────────────────────
class _RatingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall rating
          Row(
            children: [
              const Text(
                '4.5',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                  height: 1,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < 4
                            ? Icons.star_rounded
                            : Icons.star_half_rounded,
                        size: 18,
                        color: const Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('12 reviews',
                      style: TextStyle(
                          fontSize: 12, color: _textGrey)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Rating bars
          _RatingBar(label: '5', fraction: 0.6),
          const SizedBox(height: 6),
          _RatingBar(label: '4', fraction: 0.25),
          const SizedBox(height: 6),
          _RatingBar(label: '3', fraction: 0.1),
          const SizedBox(height: 6),
          _RatingBar(label: '2', fraction: 0.05),
          const SizedBox(height: 6),
          _RatingBar(label: '1', fraction: 0.0),

          const SizedBox(height: 18),
          const Divider(color: _border),
          const SizedBox(height: 12),

          // Sample review
          _ReviewItem(
            name: 'Tech Corp',
            date: 'Feb 2024',
            rating: 5,
            comment:
                'John was a great intern — proactive, fast learner, and delivered excellent work.',
          ),
        ],
      ),
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
                  icon: Icons.home_rounded, label: 'Home', active: false, onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const LandingPage())); }),
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

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String date;
  final bool isLast;
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _blueLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _blue, size: 18),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: _textGrey)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _blueLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(date,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _blue,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CertItem extends StatelessWidget {
  final String title;
  final String issuer;
  final String date;
  const _CertItem(
      {required this.title, required this.issuer, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _blueLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: _blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark)),
              const SizedBox(height: 2),
              Text('$issuer • $date',
                  style: const TextStyle(
                      fontSize: 12, color: _textGrey)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded,
            color: _textGrey, size: 18),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double fraction;
  const _RatingBar({required this.label, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: _textGrey)),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded,
            size: 12, color: Color(0xFFFBBF24)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: _border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_blue),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String name;
  final String date;
  final int rating;
  final String comment;
  const _ReviewItem({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _blueLight,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('TC',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _blue)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textDark)),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: _textGrey)),
                ],
              ),
            ),
            Row(
              children: List.generate(
                rating,
                (i) => const Icon(Icons.star_rounded,
                    size: 13, color: Color(0xFFFBBF24)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(comment,
            style: const TextStyle(
                fontSize: 13, color: _textGrey, height: 1.5)),
      ],
    );
  }
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
  const _NavItem(
      {required this.icon, required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active ? _blueLight : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: active ? _blue : _textGrey,
                size: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? _blue : _textGrey,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}