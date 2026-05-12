// ─────────────────────────────────────────────────────────────────────────────
// company_auth.dart
// Login & Register screen for the Hiring Company role.
// Same flip-card pattern as Login_Signup.dart; teal accent to match UserRole.
// Supabase table assumed: "Company_profile"
//   columns: id (int8 pk), name (text), email (text unique),
//            password (text), industry (text), location (text)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'company_session.dart';
import 'company_home.dart';

// ─── COLORS (Brand Accents) ──────────────────────────────────────────────────
const _teal     = Color(0xFF00C6A7);   // primary accent – matches UserRole teal
const _tealDark = Color(0xFF009E87);   // darker shade for depth

// ─── SUPABASE CLIENT ─────────────────────────────────────────────────────────
final _db = Supabase.instance.client;

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY AUTH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CompanyAuthScreen extends StatefulWidget {
  const CompanyAuthScreen({super.key});

  @override
  State<CompanyAuthScreen> createState() => _CompanyAuthScreenState();
}

class _CompanyAuthScreenState extends State<CompanyAuthScreen>
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
    final theme = Theme.of(context).colorScheme;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.surface,
      body: Stack(
        children: [
          // ─── BACKGROUND BLOBS ───
          Positioned(
            top: -sh * 0.07,
            left: -sw * 0.18,
            child: _Blob(size: sw * 0.85, color: _teal.withOpacity(0.09)),
          ),
          Positioned(
            bottom: -sh * 0.06,
            right: -sw * 0.14,
            child: _Blob(size: sw * 0.65, color: _teal.withOpacity(0.07)),
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

          // ─── BACK BUTTON (ON TOP) ───
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
                      color: theme.surfaceContainerHighest,
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
                      color: theme.onSurface,
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
    final theme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
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
class _LoginCard extends StatefulWidget {
  final VoidCallback onFlip;
  const _LoginCard({required this.onFlip});

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
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
          .from('Company_profile')
          .select()
          .eq('email', _emailCtrl.text.trim())
          .eq('password', _passCtrl.text.trim())
          .maybeSingle();

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid email or password. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      CompanySession.setCompany(
        companyEmail: (data['email'] as String?) ?? _emailCtrl.text.trim(),
        id:   data['id'] as int,
        name: (data['name'] ?? 'Company') as String,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyHomePage(companyId: data['id'] as int),
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
    final theme = Theme.of(context).colorScheme;

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
                      colors: [_teal, _tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.business_center_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Company Sign In',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.onSurface)),
                    Text('Welcome back, let\'s recruit!',
                        style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _Label('Email Address'),
            const SizedBox(height: 6),
            _Field(
              controller: _emailCtrl,
              hint: 'company@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 14),

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

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
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
                plain: 'New company? ',
                linked: 'Create Account',
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
class _RegisterCard extends StatefulWidget {
  final VoidCallback onFlip;
  const _RegisterCard({required this.onFlip});

  @override
  State<_RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<_RegisterCard> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _isLoading     = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _locationCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Check if email already exists
      final existing = await _db
          .from('Company_profile')
          .select('id')
          .eq('email', _emailCtrl.text.trim())
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An account with this email already exists.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Insert new company
      final inserted = await _db
          .from('Company_profile')
          .insert({
            'name':     _nameCtrl.text.trim(),
            'email':    _emailCtrl.text.trim(),
            'password': _passCtrl.text.trim(),
            'industry': _industryCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
          })
          .select()
          .single();

      CompanySession.setCompany(
        companyEmail: inserted['email'] as String,
        id:   inserted['id'] as int,
        name: inserted['name'] as String,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: _teal,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyHomePage(companyId: inserted['id'] as int),
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
    final theme = Theme.of(context).colorScheme;

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
                      colors: [_teal, _tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_business_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Company',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: theme.onSurface)),
                    Text('Register your hiring account',
                        style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            const _Label('Company Name'),
            const SizedBox(height: 6),
            _Field(
              controller: _nameCtrl,
              hint: 'Acme Technologies',
              icon: Icons.business_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
            ),

            const SizedBox(height: 12),

            const _Label('Industry'),
            const SizedBox(height: 6),
            _Field(
              controller: _industryCtrl,
              hint: 'e.g. Software, Finance, Healthcare',
              icon: Icons.category_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Industry is required' : null,
            ),

            const SizedBox(height: 12),

            const _Label('Location'),
            const SizedBox(height: 6),
            _Field(
              controller: _locationCtrl,
              hint: 'City, Country',
              icon: Icons.location_on_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Location is required' : null,
            ),

            const SizedBox(height: 12),

            const _Label('Email Address'),
            const SizedBox(height: 6),
            _Field(
              controller: _emailCtrl,
              hint: 'hr@company.com',
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
              icon: Icons.lock_outline_rounded,
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
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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

// ─── SHARED: LABEL ───────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600, 
            color: Theme.of(context).colorScheme.onSurface),
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
    final theme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscure && _hide,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
          fontSize: 14, color: theme.onSurface, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: theme.onSurfaceVariant.withOpacity(0.6), fontSize: 14),
        filled: true,
        fillColor: theme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        errorStyle: const TextStyle(
            fontSize: 11, color: Color(0xFFEF4444), height: 1.3),
        prefixIcon:
            Icon(widget.icon, color: theme.onSurfaceVariant.withOpacity(0.8), size: 18),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hide
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 17,
                  color: theme.onSurfaceVariant.withOpacity(0.8),
                ),
                onPressed: () => setState(() => _hide = !_hide),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.outline, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.outline, width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 1.8),
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
    final theme = Theme.of(context).colorScheme;

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
                    style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant)),
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