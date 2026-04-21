import 'package:flutter/material.dart';
import 'onboarding_page3.dart';

// ── Page 2: Hiring Company ─────────────
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  static const _bg        = Color(0xFFFDF2FF);   // very light magenta-white
  static const _accent    = Color(0xFFBE185D);   // deep pink/magenta
  static const _dotActive = Color(0xFFDB2777);
  static const _dotInact  = Color(0xFFE5E7EB);
  static const _textDark  = Color(0xFF4A0D2E);
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
                      'Hire the Best\nYoung Talent',
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
                      'Post internship roles, review verified student profiles, rate candidates, and build your pipeline — faster than ever before.',
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
                            _Dot(active: false, active2: false, color: _dotActive, inact: _dotInact),
                            const SizedBox(width: 8),
                            _Dot(active: true,  active2: false, color: _dotActive, inact: _dotInact),
                            const SizedBox(width: 8),
                            _Dot(active: false, active2: false, color: _dotActive, inact: _dotInact),
                          ],
                        ),
                        _NextButton(
                          color: _accent,
                          onTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, a, __) => const OnboardingPage3(),
                              transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          ),
                        ),
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
            color: const Color(0xFFDB2777).withOpacity(0.07),
          ),
        ),

        // Main orb
        Container(
          width: orbSize,
          height: orbSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFF472B6),
                Color(0xFFBE185D),
                Color(0xFF831843),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDB2777).withOpacity(0.30),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.20),
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

        // Icon composition
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SparkDot(size: 6, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 8),
                _SparkDot(size: 9, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 6),
                _SparkDot(size: 5, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 14),

            Icon(Icons.business_center_rounded, size: orbSize * 0.32, color: Colors.white),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SmallOrbIcon(icon: Icons.people_alt_outlined, color: const Color(0xFFFDA4AF)),
                const SizedBox(width: 18),
                _SmallOrbIcon(icon: Icons.verified_rounded,    color: const Color(0xFFF9A8D4)),
              ],
            ),
          ],
        ),

        // Bottom glow
        Positioned(
          bottom: sh * 0.01,
          child: Container(
            width: orbSize * 0.6,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xFF9333EA).withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }
}

class _SparkDot extends StatelessWidget {
  final double size;
  final Color color;
  const _SparkDot({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
  final bool active2;
  final Color color;
  final Color inact;
  const _Dot({required this.active, required this.active2, required this.color, required this.inact});
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

class _NextButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _NextButton({required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
        ),
      );
}
