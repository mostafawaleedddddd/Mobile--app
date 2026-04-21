import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'Login_SignUp.dart'; // your existing AuthScreen lives here

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const _purple    = Color(0xFF6C63FF);
const _teal      = Color(0xFF00C6A7);
const _coral     = Color(0xFFFF6B6B);
const _bgLight   = Color(0xFFF5F7FF);
const _textDark  = Color(0xFF1A1A2E);
const _textGrey  = Color(0xFF8A8FAE);
const _white     = Colors.white;

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────
class _RoleOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Color> gradient;
  final Color bgTint;

  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradient,
    required this.bgTint,
  });
}

const _roles = [
  _RoleOption(
    title: 'Internship Seeker',
    subtitle: 'Discover and apply to top verified internship opportunities',
    icon: Icons.school_rounded,
    accentColor: _purple,
    gradient: [Color(0xFF6C63FF), Color(0xFF9B8FF7)],
    bgTint: Color(0xFFF0EEFF),
  ),
  _RoleOption(
    title: 'Hiring Company',
    subtitle: 'Find and recruit pre-vetted intern talent for your team',
    icon: Icons.business_center_rounded,
    accentColor: _teal,
    gradient: [Color(0xFF00C6A7), Color(0xFF00E4BF)],
    bgTint: Color(0xFFE6FBF7),
  ),
  _RoleOption(
    title: 'Faculty Staff',
    subtitle: 'Supervise students, track placements and manage records',
    icon: Icons.menu_book_rounded,
    accentColor: _coral,
    gradient: [Color(0xFFFF6B6B), Color(0xFFFF9A9A)],
    bgTint: Color(0xFFFFF0F0),
  ),
];

// ─────────────────────────────────────────────
// USER ROLE SCREEN
// ─────────────────────────────────────────────
class UserRole extends StatefulWidget {
  const UserRole({super.key});

  @override
  State<UserRole> createState() => _UserRoleState();
}

class _UserRoleState extends State<UserRole> with TickerProviderStateMixin {
  int? _selected;

  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_selected == null) return;
    // Only Internship Seeker navigates to Auth for now
    if (_selected == 0) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const AuthScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 420),
        ),
      );
    } else {
      // Coming soon snackbar for other roles
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_roles[_selected!].title} portal coming soon!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _roles[_selected!].accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      body: Stack(
        children: [
          // decorative blobs
          _AnimatedBlob(ctrl: _pulseCtrl, top: -80, left: -60,
              size: 260, color: _purple.withOpacity(0.07)),
          _AnimatedBlob(ctrl: _pulseCtrl, bottom: -60, right: -40,
              size: 200, color: _teal.withOpacity(0.06)),
          _AnimatedBlob(ctrl: _floatCtrl, top: 200, right: -30,
              size: 140, color: _coral.withOpacity(0.05)),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 44),
                  _buildCards(),
                  const SizedBox(height: 36),
                  _buildContinueButton(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────
  Widget _buildHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
      child: Column(children: [
        _FloatingLogo(pulseCtrl: _pulseCtrl, floatCtrl: _floatCtrl),
        const SizedBox(height: 28),
        const Text(
          'Choose Your Role',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Select how you\'ll be using the platform\nto personalise your experience',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: _textGrey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ]),
    );
  }

  // ── CARDS ───────────────────────────────────
  Widget _buildCards() {
    return Column(
      children: List.generate(_roles.length, (i) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 0.25 + i * 0.08), end: Offset.zero)
              .animate(CurvedAnimation(
                parent: _entryCtrl,
                curve: Interval(0.1 + i * 0.15, 0.8 + i * 0.06, curve: Curves.easeOutCubic),
              )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: _entryCtrl,
              curve: Interval(0.1 + i * 0.15, 1.0, curve: Curves.easeOut),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RoleCard(
                role: _roles[i],
                isSelected: _selected == i,
                pulseCtrl: _pulseCtrl,
                onTap: () => setState(() => _selected = i),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── CONTINUE BUTTON ─────────────────────────
  Widget _buildContinueButton() {
    final enabled = _selected != null;
    final accent  = enabled ? _roles[_selected!].accentColor : _purple;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: enabled ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: enabled ? _onContinue : null,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final glow = enabled ? 0.38 + _pulseCtrl.value * 0.18 : 0.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: enabled
                      ? _roles[_selected!].gradient
                      : [_purple, const Color(0xFF9B8FF7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(glow),
                    blurRadius: 26,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue',
                style: TextStyle(color: _white, fontSize: 17,
                    fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, color: _white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FLOATING LOGO
// ─────────────────────────────────────────────
class _FloatingLogo extends StatelessWidget {
  final AnimationController pulseCtrl;
  final AnimationController floatCtrl;
  const _FloatingLogo({required this.pulseCtrl, required this.floatCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseCtrl, floatCtrl]),
      builder: (_, __) {
        final floatY = math.sin(floatCtrl.value * math.pi) * 6.0;
        final glowR  = 42.0 + pulseCtrl.value * 8;
        final glowOp = 0.13 + pulseCtrl.value * 0.12;
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: glowR * 2,
              height: glowR * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _purple.withOpacity(glowOp),
              ),
            ),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF5144D3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withOpacity(0.40 + pulseCtrl.value * 0.1),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.people_alt_rounded, color: _white, size: 36),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// ANIMATED BLOB
// ─────────────────────────────────────────────
class _AnimatedBlob extends StatelessWidget {
  final AnimationController ctrl;
  final double size;
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _AnimatedBlob({
    required this.ctrl,
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Transform.scale(
          scale: 1.0 + ctrl.value * 0.12,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ROLE CARD
// ─────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final _RoleOption role;
  final bool isSelected;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.pulseCtrl,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.965)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) { _pressCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnim, widget.pulseCtrl]),
        builder: (_, child) {
          final glowOp = widget.isSelected
              ? 0.14 + widget.pulseCtrl.value * 0.12
              : 0.0;
          return Transform.scale(
            scale: _scaleAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: widget.isSelected ? widget.role.bgTint : _white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.isSelected
                      ? widget.role.accentColor.withOpacity(0.65)
                      : const Color(0xFFE8EAF6),
                  width: widget.isSelected ? 2.0 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? widget.role.accentColor.withOpacity(glowOp)
                        : const Color(0xFF6C63FF).withOpacity(0.05),
                    blurRadius: widget.isSelected ? 30 : 12,
                    spreadRadius: widget.isSelected ? 3 : 0,
                    offset: const Offset(0, 6),
                  ),
                  if (!widget.isSelected)
                    BoxShadow(color: Colors.black.withOpacity(0.035),
                        blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            _buildIcon(),
            const SizedBox(width: 16),
            Expanded(child: _buildText()),
            _buildCheck(),
          ]),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 58, height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: widget.isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.role.gradient)
            : null,
        color: widget.isSelected ? null : widget.role.accentColor.withOpacity(0.09),
        boxShadow: widget.isSelected
            ? [BoxShadow(color: widget.role.accentColor.withOpacity(0.33),
                blurRadius: 16, offset: const Offset(0, 4))]
            : null,
      ),
      child: Icon(widget.role.icon, size: 26,
          color: widget.isSelected ? _white : widget.role.accentColor),
    );
  }

  Widget _buildText() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: widget.isSelected ? widget.role.accentColor : _textDark,
        ),
        child: Text(widget.role.title),
      ),
      const SizedBox(height: 5),
      Text(widget.role.subtitle,
          style: const TextStyle(fontSize: 12.5, height: 1.45, color: _textGrey)),
    ]);
  }

  Widget _buildCheck() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: 22, height: 22,
      margin: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.isSelected
            ? LinearGradient(colors: widget.role.gradient,
                begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: widget.isSelected ? null : const Color(0xFFEEF0FA),
        boxShadow: widget.isSelected
            ? [BoxShadow(color: widget.role.accentColor.withOpacity(0.38),
                blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: widget.isSelected
          ? const Icon(Icons.check_rounded, size: 13, color: _white)
          : null,
    );
  }
}
