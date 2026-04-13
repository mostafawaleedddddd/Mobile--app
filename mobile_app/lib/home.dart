import 'package:flutter/material.dart';
import 'Login_Signup.dart';

import 'package:supabase_flutter/supabase_flutter.dart'; // ← add this import

Future<void> main() async {                    
  WidgetsFlutterBinding.ensureInitialized();   
  await Supabase.initialize(                   
    url: 'https://vkkwzzrpmdkvgnxlvddz.supabase.co',
    anonKey: 'sb_publishable_q_3tICsMxAFw8x0tyMzBPQ_RrN6h_be', // your full key
  );
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
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

// ─── LANDING PAGE ──────────────────────
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const String networkImageUrl =
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=1600&auto=format&fit=crop';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.network(
              networkImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[200],
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
                return Container(color: Colors.indigo[900]);
              },
            ),
          ),

          // 2. Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
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
                  // ── Header ──
                  Column(
                    children: [
                      const SizedBox(height: 60),
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
                      Text(
                        'Bridging the Gap Between Education and Industry.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'A unified platform for students to find trainings, staff to manage certifications, and industry trainers to find top talent.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),

                  // ── Buttons ──
                  Column(
                    children: [
                      // SIGN IN — goes to AuthScreen (Login/Register flip card)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
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

                      // CREATE ACCOUNT — also goes to AuthScreen
                      // (user can flip to Register card there)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white, width: 2.5),
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
}

// ─── PLACEHOLDER DASHBOARDS ────────────
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: const Center(
          child: Text('Welcome Student! (Manage Internships)')));
}

class StaffPortal extends StatelessWidget {
  const StaffPortal({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('University Staff Portal')),
      body: const Center(child: Text('Welcome Staff! (Track Reports)')));
}

class TrainerConsole extends StatelessWidget {
  const TrainerConsole({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Trainer Console')),
      body:
          const Center(child: Text('Welcome Trainer! (Review Applicants)')));
}