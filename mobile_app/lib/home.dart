import 'package:flutter/material.dart';
import 'Login_Signup.dart';
import 'User_profile.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProPath',
       debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use a professional, tech-focused blue/indigo palette
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

// --- Mock Authentication Service ---
// Simulates checking the user's role from your backend.

enum UserRole { student, staff, trainer, unknown }

class AuthService {
  // Simulate an API call. In a real app, this would be a POST request to your auth endpoint.
  static Future<UserRole> signIn(String email, String password) async {
    // Simulate network latency
    await Future.delayed(const Duration(seconds: 2));

    if (email.contains('student')) {
      return UserRole.student;
    } else if (email.contains('staff')) {
      return UserRole.staff;
    } else if (email.contains('trainer')) {
      return UserRole.trainer;
    } else {
      // For any other input, return unknown (to trigger an error)
      return UserRole.unknown;
    }
  }
}

// --- The Landing Page (ProPath Gateway) ---

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // A high-quality, tech-focused professional image from Unsplash
    const String networkImageUrl =
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=1600&auto=format&fit=crop';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image using Image.network
          Positioned.fill(
            child: Image.network(
              networkImageUrl,
              fit: BoxFit.cover,
              // We use loadingBuilder to handle the image loading gracefully
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200], // Background color while loading
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.indigo,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case the image fails to load
                return Container(color: Colors.indigo[900]);
              },
            ),
          ),
          // 2. Dark Overlay for Text Readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          // 3. Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- App Definition Header ---
                  Column(
                    children: [
                      const SizedBox(height: 60),
                      // App Name
                      const Text(
                        'PROPATH',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Core Value Statement
                      Text(
                        'Bridging the Gap Between Education and Industry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Purpose Breakdown
                      Text(
                        'A unified platform for students to find trainings, staff to manage certifications, and industry trainers to find top talent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  // --- Authentication Buttons ---
                  Column(
                    children: [
                      // SIGN IN Button (Primary Action)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                              Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AuthScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text(
                            'SIGN IN',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // CREATE ACCOUNT Button (Outlined/Secondary)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                             // Opens the Login Bottom Sheet (Simplified for demo)
                             _showAuthSheet(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 2.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          child: const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to display the login sheet
  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Sheet can expand when the keyboard appears
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 20.0), // Padding above the keyboard
          child: AuthSheetContent(),
        );
      },
    );
  }
}

// --- The Form Content inside the Login Sheet ---

class AuthSheetContent extends StatefulWidget {
  const AuthSheetContent({super.key});

  @override
  State<AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends State<AuthSheetContent> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  void _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ''; 
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    // 1. Keep your simulation or API call
    UserRole role = await AuthService.signIn(email, password);

    if (!mounted) return;

    setState(() { _isLoading = false; });

    
    if (role != UserRole.unknown) {
      // Close the login sheet
      Navigator.pop(context);

      // Navigate to your actual Profile Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials. Try "student@miu.edu"';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // viewInsets handles the content resizing when the keyboard appears
      padding: EdgeInsets.only(
          left: 28.0,
          right: 28.0,
          top: 35.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 25),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Wrap content height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your credentials to access your ProPath dashboard.',
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.3),
          ),
          const SizedBox(height: 35),
          // Email Address Input
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          // Password Input
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 18),
          // Error Message display
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          const SizedBox(height: 20),
          // SIGN IN Button inside the form
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'SIGN IN',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// --- Placeholder Dashboards for Demonstration ---

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: const Center(child: Text("Welcome Student! (Manage Internships)")));
}

class StaffPortal extends StatelessWidget {
  const StaffPortal({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("University Staff Portal")),
      body: const Center(child: Text("Welcome Staff! (Track Reports)")));
}

class TrainerConsole extends StatelessWidget {
  const TrainerConsole({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text("Trainer Console")),
      body: const Center(child: Text("Welcome Trainer! (Review Applicants)")));
}