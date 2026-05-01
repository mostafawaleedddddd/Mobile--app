import 'package:flutter/material.dart';

const _blue = Color(0xFF3B82F6);
const _blueLight = Color(0xFFEFF6FF);
const _bluePale = Color(0xFFF0F7FF);
const _textDark = Color(0xFF1E293B);
const _textGrey = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _white = Colors.white;
const _green = Color(0xFF10B981);

class TechnicalQuestionsScreen extends StatefulWidget {
  const TechnicalQuestionsScreen({super.key});

  @override
  State<TechnicalQuestionsScreen> createState() => _TechnicalQuestionsScreenState();
}

class _TechnicalQuestionsScreenState extends State<TechnicalQuestionsScreen> {
  final List<Map<String, dynamic>> _questions = [
    {
      'id': 1,
      'question': 'What is the difference between var, let, and const in JavaScript?',
      'tips': ['var is function-scoped, let and const are block-scoped', 'const cannot be reassigned', 'Use const by default, let when needed'],
      'answer': 'var is function-scoped and can be redeclared. let is block-scoped and cannot be redeclared but can be reassigned. const is block-scoped, cannot be redeclared or reassigned. Best practice: use const by default.',
    },
    {
      'id': 2,
      'question': 'Explain the concept of asynchronous programming.',
      'tips': ['JavaScript is single-threaded', 'Callbacks, Promises, and async/await are solutions', 'Use async/await for cleaner code'],
      'answer': 'Asynchronous programming allows operations to run without blocking the main thread. JavaScript uses callbacks, Promises, and async/await patterns to handle async operations efficiently.',
    },
    {
      'id': 3,
      'question': 'What is the difference between REST and GraphQL?',
      'tips': ['REST uses multiple endpoints, GraphQL uses a single endpoint', 'GraphQL allows clients to request only needed data', 'GraphQL has a stronger learning curve'],
      'answer': 'REST uses multiple endpoints for different resources. GraphQL uses a single endpoint with a query language to request specific fields. GraphQL reduces over-fetching but is more complex.',
    },
    {
      'id': 4,
      'question': 'How do you optimize a slow database query?',
      'tips': ['Use indexes on frequently queried columns', 'Minimize joins and use proper relationships', 'Consider caching and pagination'],
      'answer': 'Add indexes to columns used in WHERE clauses, optimize JOIN queries, use explain plans to analyze, implement caching, and consider pagination for large datasets.',
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
                              'Technical Questions',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Test your technical knowledge',
                              style: TextStyle(fontSize: 12, color: _textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Questions List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _questions.length,
                    itemBuilder: (_, i) => _QuestionCard(
                      question: _questions[i],
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

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final bool isExpanded;
  final VoidCallback onTap;

  const _QuestionCard({
    required this.question,
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
                    Expanded(
                      child: Text(
                        question['question'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                          height: 1.5,
                        ),
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
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
                      const Text(
                        'Key Points:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(question['tips'] as List<String>).map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: _green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textGrey,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _blueLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Answer:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _blue,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question['answer'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textGrey,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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
