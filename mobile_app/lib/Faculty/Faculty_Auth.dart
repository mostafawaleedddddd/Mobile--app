import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Faculty_Session.dart';
import 'Faculty_Home.dart';

// ─── COLORS (Strict Light Mode Branding) ─────────────────────────────────────
const _teal          = Color(0xFFFF6B6B);  // primary accent – matches UserRole teal
const _facultyIndigo = Color(0xFF303F9F);  // Academic-style primary color
const _bgAccent      = Color(0xFFF5F7FA);  // Light academic background
const _textDark      = Color(0xFF1E293B);
const _textGrey      = Color(0xFF64748B);
const _border        = Color(0xFFCBD5E1);
const _fieldBg       = Color(0xFFF8FAFC);
const _white         = Colors.white;

// ─── SUPABASE CLIENT ─────────────────────────────────────────────────────────
final _db = Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────────────────
// Faculty AUTH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class FacultyAuthScreen extends StatefulWidget {
  const FacultyAuthScreen({super.key});

  @override
  State<FacultyAuthScreen> createState() => _FacultyAuthScreenState();
}

class _FacultyAuthScreenState extends State<FacultyAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
      backgroundColor: _bgAccent, // Locked to Light Background
      body: Stack(
        children: [
          // ─── BACKGROUND BLOBS ───
          Positioned(
            top: -sh * 0.07,
            left: -sw * 0.18,
            child: _Blob(size: sw * 0.85, color: _facultyIndigo.withOpacity(0.09)),
          ),
          Positioned(
            bottom: -sh * 0.06,
            right: -sw * 0.14,
            child: _Blob(size: sw * 0.65, color: _facultyIndigo.withOpacity(0.07)),
          ),

          // ─── MAIN CONTENT ───
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
                          ? _FacultyLoginCard(onFlip: _flip) 
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: _FacultyRegisterCard(onFlip: _flip), 
                            ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ─── BACK BUTTON ───
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: _textDark,
                      onPressed: () {
                        if (_showRegister) {
                          _flip(); // go back to login
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BLOB ─────────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

// ─── CARD SHELL ───────────────────────────────────────────────────────────────
class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withOpacity(0.10),
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

// ─── LOGIN CARD ───────────────────────────────────────────────────────────────
class _FacultyLoginCard extends StatefulWidget {
  final VoidCallback onFlip;
  const _FacultyLoginCard({required this.onFlip});

  @override
  State<_FacultyLoginCard> createState() => _FacultyLoginCardState();
}

class _FacultyLoginCardState extends State<_FacultyLoginCard> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _isLoading  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final data = await _db
          .from('faculty_profile') 
          .select()
          .eq('email', _emailCtrl.text.trim())
          .eq('password', _passCtrl.text.trim())
          .maybeSingle();

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid faculty credentials. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      // 2. Use the FacultySession we created earlier
      FacultySession.setFaculty(
        facultyEmail: (data['email'] as String?) ?? _emailCtrl.text.trim(),
        id:   data['id'] as int,
        facultyName: (data['name'] ?? 'Faculty Member') as String,
        dept: data['department'] as String?, // Optional
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacultyHomePage(facultyId: data['id'] as int),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_facultyIndigo, Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.school_rounded, // Academic Icon
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faculty Sign In',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _textDark)),
                    Text('Access your academic portal',
                        style: TextStyle(fontSize: 12, color: _textGrey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _Label('University Email'),
            const SizedBox(height: 6),
            _Field(
              controller: _emailCtrl,
              hint: 'professor@university.edu',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                return null;
              },
            ),

            const SizedBox(height: 14),

            const _Label('Password'),
            const SizedBox(height: 6),
            _Field(
              controller: _passCtrl,
              hint: '••••••••',
              icon: Icons.lock_open_rounded,
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _facultyIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Sign In',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3)),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: _InkLink(
                plain: 'Not registered? ',
                linked: 'Join Faculty',
                onTap: widget.onFlip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── REGISTER CARD ────────────────────────────────────────────────────────────
class _FacultyRegisterCard extends StatefulWidget {
  final VoidCallback onFlip;
  const _FacultyRegisterCard({required this.onFlip});

  @override
  State<_FacultyRegisterCard> createState() => _FacultyRegisterCardState();
}

class _FacultyRegisterCardState extends State<_FacultyRegisterCard> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _deptCtrl     = TextEditingController();
  final _designationCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _isLoading     = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    _designationCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Check if Faculty email exists
      final existing = await _db
          .from('faculty_profile')
          .select('id')
          .eq('email', _emailCtrl.text.trim())
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A faculty account with this email already exists.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. Insert new faculty member
      final inserted = await _db
          .from('faculty_profile')
          .insert({
            'name':       _nameCtrl.text.trim(),
            'email':      _emailCtrl.text.trim(),
            'password':   _passCtrl.text.trim(),
            'department': _deptCtrl.text.trim(),
            'designation': _designationCtrl.text.trim(),
          })
          .select()
          .single();

      // 3. Update Faculty Session
      FacultySession.setFaculty(
        facultyEmail: inserted['email'] as String,
        id:   inserted['id'] as int,
        facultyName: inserted['name'] as String,
        dept: inserted['department'] as String?,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty account created successfully!'),
            backgroundColor: Color(0xFF303F9F),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FacultyHomePage(facultyId: inserted['id'] as int),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_facultyIndigo, Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Faculty Registry',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _textDark)),
                    Text('Create your academic profile',
                        style: TextStyle(fontSize: 12, color: _textGrey)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _Label('Full Name'),
            const SizedBox(height: 6),
            _Field(
              controller: _nameCtrl,
              hint: 'Dr. Jane Smith',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),

            const SizedBox(height: 12),

            const _Label('Department'),
            const SizedBox(height: 6),
            _Field(
              controller: _deptCtrl,
              hint: 'e.g. Computer Science, Physics',
              icon: Icons.account_tree_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Department is required' : null,
            ),

            const SizedBox(height: 12),

            const _Label('Designation'),
            const SizedBox(height: 6),
            _Field(
              controller: _designationCtrl,
              hint: 'e.g. Associate Professor',
              icon: Icons.workspace_premium_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
            ),

            const SizedBox(height: 12),

            const _Label('University Email'),
            const SizedBox(height: 6),
            _Field(
              controller: _emailCtrl,
              hint: 'jane.smith@university.edu',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 12),

            const _Label('Password'),
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

            const _Label('Confirm Password'),
            const SizedBox(height: 6),
            _Field(
              controller: _confirmCtrl,
              hint: '••••••••',
              icon: Icons.check_circle_outline,
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm password';
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _facultyIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text('Create Account',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3)),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: _InkLink(
                plain: 'Already registered? ',
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

// ─── SHARED: LABEL ───────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600, 
            color: _textDark),
      );
}

// ─── SHARED: TEXT FIELD ──────────────────────────────────────────────────────
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
        hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 14),
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
          borderSide: const BorderSide(color: _facultyIndigo, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }
}

// ─── SHARED: INKWELL LINK ────────────────────────────────────────────────────
class _InkLink extends StatelessWidget {
  final String plain;
  final String linked;
  final VoidCallback onTap;
  const _InkLink({required this.plain, required this.linked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          splashColor: _teal.withOpacity(0.12),
          highlightColor: _teal.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: plain,
                      style: const TextStyle(fontSize: 13, color: _textGrey)),
                  TextSpan(
                      text: linked,
                      style: const TextStyle(
                          fontSize: 13,
                          color: _teal,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      );
  }
}