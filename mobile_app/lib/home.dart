import 'package:flutter/material.dart';
import 'onboarding_page2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ── Page 1: Internship Seeker ──────────
Future<void> main() async {                    
  WidgetsFlutterBinding.ensureInitialized();   
  await Supabase.initialize(                   
    url: 'https://vkkwzzrpmdkvgnxlvddz.supabase.co',
    anonKey: 'sb_publishable_q_3tICsMxAFw8x0tyMzBPQ_RrN6h_be', // your full key
  );
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const OnboardingPage1(),
      );
}

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  static const _bg         = Color(0xFFF5F3FF);   // very light lavender-white
 // static const _orb1       = Color(0xFF7C3AED);   // deep violet
 // static const _orb2       = Color(0xFF4F46E5);   // indigo
 // static const _orb3       = Color(0xFF06B6D4);   // cyan glow
  static const _accent     = Color(0xFF7C3AED);
  static const _textDark   = Color(0xFF1E1B4B);
  static const _textBody   = Color(0xFF4B5563);
  static const _dotActive  = Color(0xFF7C3AED);
  static const _dotInact   = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Illustrated orb zone ──────────────
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

                    // Title
                    const Text(
                      'Find Your Dream\nInternship',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Body
                    const Text(
                      'Browse hundreds of internship opportunities, apply with one tap, upload your CV, and track every application — all in one place.',
                      style: TextStyle(
                        fontSize: 15,
                        color: _textBody,
                        height: 1.6,
                      ),
                    ),

                    const Spacer(),

                    // Dots + Next button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dot indicators
                        Row(
                          children: [
                            _Dot(active: true,  color: _dotActive, inactiveColor: _dotInact),
                            const SizedBox(width: 8),
                            _Dot(active: false, color: _dotActive, inactiveColor: _dotInact),
                            const SizedBox(width: 8),
                            _Dot(active: false, color: _dotActive, inactiveColor: _dotInact),
                          ],
                        ),

                        // Next button
                        _NextButton(
                          color: _accent,
                          onTap: () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, a, __) => const OnboardingPage2(),
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
            color: const Color(0xFF7C3AED).withOpacity(0.08),
          ),
        ),

        // Main orb gradient circle
        Container(
          width: orbSize,
          height: orbSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF818CF8),
                Color(0xFF6D28D9),
                Color(0xFF312E81),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.30),
                blurRadius: 60,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF06B6D4).withOpacity(0.20),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
        ),

        // Inner glow highlight
        Positioned(
          top: sh * 0.04,
          child: Container(
            width: orbSize * 0.4,
            height: orbSize * 0.18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: Colors.white.withOpacity(0.15),
            ),
          ),
        ),

        // Icon composition: briefcase + sparkles
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sparkle dots above
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SparkDot(size: 5, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 6),
                _SparkDot(size: 8, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 6),
                _SparkDot(size: 5, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 14),
                _SparkDot(size: 6, color: const Color(0xFF67E8F9).withOpacity(0.8)),
              ],
            ),
            const SizedBox(height: 14),

            // Main icon
            Icon(
              Icons.work_outline_rounded,
              size: orbSize * 0.32,
              color: Colors.white,
            ),

            const SizedBox(height: 10),

            // Sub icon row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SmallOrbIcon(icon: Icons.search_rounded, color: const Color(0xFF67E8F9)),
                const SizedBox(width: 18),
                _SmallOrbIcon(icon: Icons.upload_file_rounded, color: const Color(0xFFA78BFA)),
              ],
            ),
          ],
        ),

        // Bottom cyan glow
        Positioned(
          bottom: sh * 0.01,
          child: Container(
            width: orbSize * 0.6,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: const Color(0xFF06B6D4).withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared small widgets ─────────────────
class _SparkDot extends StatelessWidget {
  final double size;
  final Color color;
  const _SparkDot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _SmallOrbIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SmallOrbIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
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
  final Color inactiveColor;
  const _Dot({required this.active, required this.color, required this.inactiveColor});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: active ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? color : inactiveColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _NextButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _NextButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
          ),
        ),
      );
}
