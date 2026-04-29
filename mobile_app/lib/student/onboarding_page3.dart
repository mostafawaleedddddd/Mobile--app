import 'package:flutter/material.dart';
import 'UserRole.dart';

// ── Page 3: Faculty Staff ──────────────
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  static const _bg        = Color(0xFFF0FBFF);   // very light cyan-white
  static const _accent    = Color(0xFF0369A1);   // deep sky blue
  static const _dotActive = Color(0xFF0284C7);
  static const _dotInact  = Color(0xFFE5E7EB);
  static const _textDark  = Color(0xFF0C2340);
  static const _textBody  = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 55,
              child: _OrbScene(sh: sh, sw: sw),
            ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),

                    const Text(
                      'Empower Your\nStudents\' Future',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Monitor student internship progress, review submitted surveys, validate certificates, and ensure every student is career-ready.',
                      style: TextStyle(
                        fontSize: 15,
                        color: _textBody,
                        height: 1.6,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _Dot(active: false, color: _dotActive, inact: _dotInact),
                            const SizedBox(width: 8),
                            _Dot(active: false, color: _dotActive, inact: _dotInact),
                            const SizedBox(width: 8),
                            _Dot(active: true,  color: _dotActive, inact: _dotInact),
                          ],
                        ),

                        // Last page: "Get Started" button instead of arrow
                        _GetStartedButton(color: _accent, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const UserRole()));
                        }),
                      ],
                    ),

                    SizedBox(height: sh * 0.04),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Orb Illustration ─────────────────────
class _OrbScene extends StatelessWidget {
  final double sh, sw;
  const _OrbScene({required this.sh, required this.sw});

  @override
  Widget build(BuildContext context) {
    final orbSize = sw * 0.72;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: orbSize + 32,
          height: orbSize + 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0284C7).withOpacity(0.07),
          ),
        ),

        // Main orb — teal-to-blue like the third card in the reference
        Container(
          width: orbSize,
          height: orbSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF38BDF8),
                Color(0xFF0284C7),
                Color(0xFF0C4A6E),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withOpacity(0.28),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.22),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
        ),

        // Inner highlight
        Positioned(
          top: sh * 0.04,
          child: Container(
            width: orbSize * 0.4,
            height: orbSize * 0.18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white.withOpacity(0.18),
            ),
          ),
        ),

        // Stacked lens / ring shapes (like the 3rd panel in the reference)
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stacked concentric arcs mimicking the reference's capsule shape
            _RingArc(width: orbSize * 0.42, height: orbSize * 0.12, color: Colors.white.withOpacity(0.90)),
            const SizedBox(height: 5),
            _RingArc(width: orbSize * 0.32, height: orbSize * 0.09, color: Colors.white.withOpacity(0.55)),
            const SizedBox(height: 5),
            _RingArc(width: orbSize * 0.22, height: orbSize * 0.07, color: Colors.white.withOpacity(0.30)),

            const SizedBox(height: 18),

            // Main icon below arcs
            Icon(Icons.menu_book_rounded, size: orbSize * 0.28, color: Colors.white),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SmallOrbIcon(icon: Icons.bar_chart_rounded,    color: const Color(0xFF7DD3FC)),
                const SizedBox(width: 18),
                _SmallOrbIcon(icon: Icons.fact_check_outlined,  color: const Color(0xFFBAE6FD)),
              ],
            ),
          ],
        ),

        // Bottom glow strip
        Positioned(
          bottom: sh * 0.01,
          child: Container(
            width: orbSize * 0.6,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xFF06B6D4).withOpacity(0.28),
            ),
          ),
        ),
      ],
    );
  }
}

// Flat pill/arc shape
class _RingArc extends StatelessWidget {
  final double width, height;
  final Color color;
  const _RingArc({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
        ),
      );
}

class _SmallOrbIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SmallOrbIcon({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Icon(icon, size: 18, color: color),
      );
}

class _Dot extends StatelessWidget {
  final bool active;
  final Color color;
  final Color inact;
  const _Dot({required this.active, required this.color, required this.inact});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: active ? 24 : 8, height: 8,
        decoration: BoxDecoration(
          color: active ? color : inact,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _GetStartedButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _GetStartedButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  'Get Started',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
        ),
      );
}
