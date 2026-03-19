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
      home: const AuthCard(),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final _loginFields = {
    'email': TextEditingController(),
    'password': TextEditingController(),
  };

  final _registerFields = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
    'confirm': TextEditingController(),
  };

  final _showPassword = {
    'login': false,
    'register': false,
    'confirm': false,
  };

  final _errors = {
    'login': <String, String>{},
    'register': <String, String>{},
  };

  bool _isLoginMode = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loginFields.forEach((_, c) => c.dispose());
    _registerFields.forEach((_, c) => c.dispose());
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errors['login']!.clear();
      _errors['register']!.clear();
    });
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isValidPassword(String password) => password.length >= 6;

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone);
  }

  void _validateLoginForm() {
    setState(() {
      _errors['login']!.clear();
      final email = _loginFields['email']!.text;
      final password = _loginFields['password']!.text;

      if (email.isEmpty) {
        _errors['login']!['email'] = 'Email required';
      } else if (!_isValidEmail(email)) {
        _errors['login']!['email'] = 'Invalid email';
      }

      if (password.isEmpty) {
        _errors['login']!['password'] = 'Password required';
      } else if (!_isValidPassword(password)) {
        _errors['login']!['password'] = 'Min 6 characters';
      }

      if (_errors['login']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Login successful!')),
        );
      }
    });
  }

  void _validateRegisterForm() {
    setState(() {
      _errors['register']!.clear();
      final name = _registerFields['name']!.text;
      final email = _registerFields['email']!.text;
      final phone = _registerFields['phone']!.text;
      final password = _registerFields['password']!.text;
      final confirm = _registerFields['confirm']!.text;

      if (name.isEmpty) _errors['register']!['name'] = 'Name required';
      if (email.isEmpty) {
        _errors['register']!['email'] = 'Email required';
      } else if (!_isValidEmail(email)) {
        _errors['register']!['email'] = 'Invalid email';
      }
      if (phone.isEmpty) {
        _errors['register']!['phone'] = 'Phone required';
      } else if (!_isValidPhone(phone)) {
        _errors['register']!['phone'] = 'Invalid phone';
      }
      if (password.isEmpty) {
        _errors['register']!['password'] = 'Password required';
      } else if (!_isValidPassword(password)) {
        _errors['register']!['password'] = 'Min 6 characters';
      }
      if (confirm.isEmpty) {
        _errors['register']!['confirm'] = 'Confirm required';
      } else if (confirm != password) {
        _errors['register']!['confirm'] = 'Mismatch';
      }

      if (_errors['register']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Registration successful!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final angle = _flipAnimation.value * 3.14159265359;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: angle > 1.5708
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(3.14159265359),
                      alignment: Alignment.center,
                      child: _buildCard(_buildRegisterForm()),
                    )
                  : _buildCard(_buildLoginForm()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Login',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3333CC),
            )),
        const SizedBox(height: 32),
        AuthField(
          controller: _loginFields['email']!,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          error: _errors['login']!['email'],
        ),
        const SizedBox(height: 16),
        AuthPasswordField(
          controller: _loginFields['password']!,
          hint: 'Password',
          showPassword: _showPassword['login']!,
          onToggle: () => setState(() => _showPassword['login'] = !_showPassword['login']!),
          error: _errors['login']!['password'],
        ),
        const SizedBox(height: 28),
        _buildButton('LOGIN', _validateLoginForm),
        const SizedBox(height: 16),
        _buildToggleLink("Don't have account? Register"),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Register',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3333CC),
            )),
        const SizedBox(height: 28),
        AuthField(
          controller: _registerFields['name']!,
          hint: 'Full Name',
          error: _errors['register']!['name'],
        ),
        const SizedBox(height: 12),
        AuthField(
          controller: _registerFields['email']!,
          hint: 'Email',
          keyboardType: TextInputType.emailAddress,
          error: _errors['register']!['email'],
        ),
        const SizedBox(height: 12),
        AuthField(
          controller: _registerFields['phone']!,
          hint: 'Phone',
          keyboardType: TextInputType.phone,
          error: _errors['register']!['phone'],
        ),
        const SizedBox(height: 12),
        AuthPasswordField(
          controller: _registerFields['password']!,
          hint: 'Password',
          showPassword: _showPassword['register']!,
          onToggle: () => setState(() => _showPassword['register'] = !_showPassword['register']!),
          error: _errors['register']!['password'],
        ),
        const SizedBox(height: 12),
        AuthPasswordField(
          controller: _registerFields['confirm']!,
          hint: 'Confirm Password',
          showPassword: _showPassword['confirm']!,
          onToggle: () => setState(() => _showPassword['confirm'] = !_showPassword['confirm']!),
          error: _errors['register']!['confirm'],
        ),
        const SizedBox(height: 24),
        _buildButton('Register', _validateRegisterForm),
        const SizedBox(height: 12),
        _buildToggleLink('Have account? Sign In'),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        width: 140,
        height: 44,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3333CC),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleLink(String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleFlip,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3333CC),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  AUTH FIELD WIDGET
// ─────────────────────────────────────────
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? error;

  const AuthField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: _buildBorder(),
            enabledBorder: _buildBorder(),
            focusedBorder: _buildBorder(focused: true),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 20),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _buildBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: error != null
            ? Colors.red
            : (focused ? const Color(0xFF3333CC) : const Color(0xFFBBBBEE)),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}

// ─────────────────────────────────────────
//  AUTH PASSWORD FIELD WIDGET
// ─────────────────────────────────────────
class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool showPassword;
  final VoidCallback onToggle;
  final String? error;

  const AuthPasswordField({
    required this.controller,
    required this.hint,
    required this.showPassword,
    required this.onToggle,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: !showPassword,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF3333CC),
                  size: 20,
                ),
              ),
            ),
            border: _buildBorder(),
            enabledBorder: _buildBorder(),
            focusedBorder: _buildBorder(focused: true),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 20),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  OutlineInputBorder _buildBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: error != null
            ? Colors.red
            : (focused ? const Color(0xFF3333CC) : const Color(0xFFBBBBEE)),
        width: focused ? 2 : 1.5,
      ),
    );
  }
}