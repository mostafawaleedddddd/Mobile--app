import 'package:flutter/material.dart';
import 'mock_interview_recorder.dart';

const _blue = Color(0xFF3B82F6);
const _blueLight = Color(0xFFEFF6FF);
const _bluePale = Color(0xFFF0F7FF);
const _textDark = Color(0xFF1E293B);
const _textGrey = Color(0xFF64748B);
const _white = Colors.white;

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  final List<Map<String, dynamic>> _interviews = [
    {
      'id': 1,
      'title': '30-Minute Technical Interview',
      'description': 'Quick technical assessment covering core concepts',
      'duration': '30 mins',
      'questions': 3,
      'difficulty': 'Medium',
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 2,
      'title': 'Full Behavioral Interview',
      'description': 'Complete behavioral round with multiple scenarios',
      'duration': '45 mins',
      'questions': 5,
      'difficulty': 'Medium',
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 3,
      'title': 'System Design Challenge',
      'description': 'Design a scalable system architecture',
      'duration': '60 mins',
      'questions': 1,
      'difficulty': 'Hard',
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 4,
      'title': 'Problem Solving Session',
      'description': 'Code or solve real-world problems',
      'duration': '45 mins',
      'questions': 2,
      'difficulty': 'Hard',
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bluePale,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: _Blob(
              size: MediaQuery.of(context).size.width * 0.7,
              color: _blue.withOpacity(0.07),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _Blob(
              size: MediaQuery.of(context).size.width * 0.55,
              color: _blue.withOpacity(0.05),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _textDark,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mock Interview',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Practice full interview simulations',
                              style: TextStyle(fontSize: 12, color: _textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Interviews List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _interviews.length,
                    itemBuilder: (_, i) => _InterviewCard(
                      interview: _interviews[i],
                      onTap: () {
                        final interview = _interviews[i];
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MockInterviewRecorderScreen(
                              title: interview['title'] as String,
                              description: interview['description'] as String,
                              color: interview['color'] as Color,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  final Map<String, dynamic> interview;
  final VoidCallback onTap;

  const _InterviewCard({
    required this.interview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final difficulty = interview['difficulty'] as String;
    final diffColor = difficulty == 'Easy'
        ? const Color(0xFF10B981)
        : difficulty == 'Medium'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              // Top colored section
              Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (interview['color'] as Color).withOpacity(0.15),
                      (interview['color'] as Color).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (interview['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.videocam_outlined,
                          color: interview['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              interview['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom info section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interview['description'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.schedule_outlined,
                          label: interview['duration'] as String,
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.quiz_outlined,
                          label: '${interview['questions']} Q',
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: diffColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: diffColor, width: 0.8),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: diffColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _blue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _blue,
              fontWeight: FontWeight.w600,
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
