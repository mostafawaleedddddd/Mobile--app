import 'package:flutter/material.dart';

const _blue = Color(0xFF3B82F6);
const _bluePale = Color(0xFFF0F7FF);
const _textDark = Color(0xFF1E293B);
const _textGrey = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _white = Colors.white;
const _amber = Color(0xFFF59E0B);

class TipsAndTricksScreen extends StatefulWidget {
  const TipsAndTricksScreen({super.key});

  @override
  State<TipsAndTricksScreen> createState() => _TipsAndTricksScreenState();
}

class _TipsAndTricksScreenState extends State<TipsAndTricksScreen> {
  final List<Map<String, dynamic>> _tips = [
    {
      'id': 1,
      'title': 'Research the Company',
      'description': 'Learn about the company\'s mission, recent news, and culture',
      'tips': [
        'Read their latest press releases',
        'Check their LinkedIn company page',
        'Understand their products/services',
        'Know their competitors',
      ],
    },
    {
      'id': 2,
      'title': 'Master the STAR Method',
      'description': 'Structure behavioral answers using Situation, Task, Action, Result',
      'tips': [
        'Situation: Set the context',
        'Task: Explain what you needed to achieve',
        'Action: Describe what you actually did',
        'Result: Share the measurable outcomes',
      ],
    },
    {
      'id': 3,
      'title': 'Practice Mock Interviews',
      'description': 'Simulate real interviews to build confidence',
      'tips': [
        'Record yourself to identify improvements',
        'Practice with a friend or mentor',
        'Time your responses (aim for 2-3 minutes)',
        'Get feedback on your communication',
      ],
    },
    {
      'id': 4,
      'title': 'Body Language Matters',
      'description': 'Non-verbal communication is crucial in interviews',
      'tips': [
        'Maintain good posture and eye contact',
        'Smile genuinely and be friendly',
        'Avoid nervous habits (fidgeting, crossing arms)',
        'Use hand gestures to emphasize points',
      ],
    },
    {
      'id': 5,
      'title': 'Prepare Smart Questions',
      'description': 'Ask thoughtful questions about the role and company',
      'tips': [
        'Ask about day-to-day responsibilities',
        'Inquire about team dynamics',
        'Ask about growth opportunities',
        'Show genuine interest in the role',
      ],
    },
    {
      'id': 6,
      'title': 'Follow-Up After Interview',
      'description': 'Reinforce your interest with a professional follow-up',
      'tips': [
        'Send within 24 hours',
        'Thank them for the opportunity',
        'Highlight relevant points from conversation',
        'Reiterate your enthusiasm for the role',
      ],
    },
  ];

  int _expandedIndex = -1;

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
                              'Tips & Tricks',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Interview strategies and best practices',
                              style: TextStyle(fontSize: 12, color: _textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Tips List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _tips.length,
                    itemBuilder: (_, i) => _TipCard(
                      tip: _tips[i],
                      isExpanded: _expandedIndex == i,
                      onTap: () => setState(() {
                        _expandedIndex = _expandedIndex == i ? -1 : i;
                      }),
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

class _TipCard extends StatelessWidget {
  final Map<String, dynamic> tip;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TipCard({
    required this.tip,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(isExpanded ? 0.15 : 0.07),
                blurRadius: isExpanded ? 20 : 16,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: _amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tip['description'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: _blue,
                      size: 24,
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const Divider(color: _border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...(tip['tips'] as List<String>).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _amber.withOpacity(0.15),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 12,
                                color: _amber,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textGrey,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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
