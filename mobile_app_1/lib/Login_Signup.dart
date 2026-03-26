import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth',
      debugShowCheckedModeBanner: false,
      home: const AuthScreen(),
    );
  }
}

// ─── COLORS ────────────────────────────
const _blue      = Color(0xFF3B82F6);
const _textDark  = Color(0xFF1E293B);
const _textGrey  = Color(0xFF64748B);
const _border    = Color(0xFFCBD5E1);
const _fieldBg   = Color(0xFFF8FAFC);

// ─── AUTH SCREEN ───────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    _showRegister ? _ctrl.reverse() : _ctrl.forward();
    setState(() => _showRegister = !_showRegister);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Stack(
        children: [
          // top-left soft circle
          Positioned(
            top: -sh * 0.07,
            left: -sw * 0.18,
            child: _Blob(size: sw * 0.85, color: _blue.withOpacity(0.09)),
          ),
          // bottom-right soft circle
          Positioned(
            bottom: -sh * 0.06,
            right: -sw * 0.14,
            child: _Blob(size: sw * 0.65, color: _blue.withOpacity(0.07)),
          ),

          // scrollable card area
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.06,
                  vertical: 32,
                ),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) {
                    final angle = _anim.value * pi;
                    final showFront = angle < pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: showFront
                          ? _LoginCard(onFlip: _flip)
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _RegisterCard(onFlip: _flip),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

// ─── CARD SHELL ────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.10),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── LOGIN CARD ────────────────────────
class _LoginCard extends StatefulWidget {
  final VoidCallback onFlip;
  const _LoginCard({required this.onFlip});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign In',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textDark)),
            const SizedBox(height: 4),
            const Text('Welcome back! Enter your details.',
                style: TextStyle(fontSize: 13, color: _textGrey)),

            const SizedBox(height: 26),

            _Label('Email'),
            const SizedBox(height: 6),
            _Field(
              controller: _emailCtrl,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim()))
                  return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 14),

            _Label('Password'),
            const SizedBox(height: 6),
            _Field(
              controller: _passCtrl,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Forgot password?',
                    style: TextStyle(
                        fontSize: 12,
                        color: _blue,
                        fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Sign In',
              onTap: () => _formKey.currentState!.validate(),
            ),

            const SizedBox(height: 18),
            Center(
              child: _InkLink(
                plain: "Don't have an account? ",
                linked: 'Register',
                onTap: widget.onFlip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REGISTER CARD ─────────────────────
class _RegisterCard extends StatefulWidget {
  final VoidCallback onFlip;
  const _RegisterCard({required this.onFlip});

  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _type = 'Student';

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Register',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textDark)),
            const SizedBox(height: 4),
            const Text('Create your account to get started.',
                style: TextStyle(fontSize: 13, color: _textGrey)),

            const SizedBox(height: 20),

            // ── Account type (no box) ──
            _Label('Account type'),
            const SizedBox(height: 4),
            Row(
              children: [
                _RadioOption(
                  label: 'Student',
                  value: 'Student',
                  groupValue: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(width: 24),
                _RadioOption(
                  label: 'Company',
                  value: 'Company',
                  groupValue: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _Label('Full name'),
            const SizedBox(height: 6),
            _Field(
              controller: _nameCtrl,
              hint: 'John Doe',
              icon: Icons.person_outline_rounded,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim()))
                  return 'Letters only';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Label('Email'),
            const SizedBox(height: 6),
            _Field(
              controller: _emailCtrl,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(v.trim()))
                  return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Label('Phone'),
            const SizedBox(height: 6),
            _Field(
              controller: _phoneCtrl,
              hint: '+1 234 567 8900',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Phone is required';
                if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim()))
                  return 'Enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Label('Password'),
            const SizedBox(height: 6),
            _Field(
              controller: _passCtrl,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),

            _Label('Confirm password'),
            const SizedBox(height: 6),
            _Field(
              controller: _confirmCtrl,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 22),
            _PrimaryButton(
              label: 'Create Account',
              onTap: () => _formKey.currentState!.validate(),
            ),

            const SizedBox(height: 16),
            Center(
              child: _InkLink(
                plain: 'Already have an account? ',
                linked: 'Sign In',
                onTap: widget.onFlip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── RADIO OPTION (plain, no box) ──────
class _RadioOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
              activeColor: _blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(
                horizontal: VisualDensity.minimumDensity,
                vertical: VisualDensity.minimumDensity,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? _blue : _textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED: LABEL ─────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
      );
}

// ─── SHARED: TEXT FIELD ────────────────
class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _hide = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscure && _hide,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
          fontSize: 14, color: _textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle:
            const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
        filled: true,
        fillColor: _fieldBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        errorStyle: const TextStyle(
            fontSize: 11, color: Color(0xFFEF4444), height: 1.3),
        prefixIcon:
            Icon(widget.icon, color: const Color(0xFF94A3B8), size: 18),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 17,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() => _hide = !_hide),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }
}

// ─── SHARED: PRIMARY BUTTON ────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3),
        ),
      ),
    );
  }
}

// ─── SHARED: INKWELL LINK ──────────────
class _InkLink extends StatelessWidget {
  final String plain;
  final String linked;
  final VoidCallback onTap;
  const _InkLink(
      {required this.plain, required this.linked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        splashColor: _blue.withOpacity(0.12),
        highlightColor: _blue.withOpacity(0.06),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: plain,
                    style: const TextStyle(
                        fontSize: 13, color: _textGrey)),
                TextSpan(
                    text: linked,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _blue,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}