import 'package:flutter/material.dart';
import 'interview_prep/behavioral_questions.dart';
import 'interview_prep/technical_questions.dart';
import 'interview_prep/mock_interview.dart';
import 'interview_prep/tips_and_tricks.dart';

// ─── COLORS (preserve brand accent) ──────────────────────────────────────────
const _blue      = Color(0xFF3B82F6);

// ─────────────────────────────────────────────────────────────────────────────
// INTERVIEW PREP SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class InterviewPrepScreen extends StatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  State<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends State<InterviewPrepScreen> {
  final _searchCtrl = TextEditingController();
  
  final List<Map<String, dynamic>> _prepItems = [
    {
      'id': 1,
      'title': 'Behavioral Questions',
      'description': 'Practice common behavioral interview questions',
      'icon': Icons.person_outline_rounded,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 2,
      'title': 'Technical Questions',
      'description': 'Prepare for technical assessments',
      'icon': Icons.code_rounded,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'id': 3,
      'title': 'Mock Interview',
      'description': 'Practice interview simulation',
      'icon': Icons.videocam_outlined,
      'color': const Color(0xFFEC4899),
    },
    {
      'id': 4,
      'title': 'Tips & Tricks',
      'description': 'Interview strategies and best practices',
      'icon': Icons.lightbulb_outline_rounded,
      'color': const Color(0xFFF59E0B),
    },
  ];

  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.from(_prepItems);
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_prepItems)
          : _prepItems.where((item) {
              final title = (item['title'] ?? '').toString().toLowerCase();
              final desc = (item['description'] ?? '').toString().toLowerCase();
              return title.contains(q) || desc.contains(q);
            }).toList();
    });
  }

  void _showDetail(Map<String, dynamic> item) {
    final title = item['title'] as String;
    
    late Widget screen;
    if (title == 'Behavioral Questions') {
      screen = const BehavioralQuestionsScreen();
    } else if (title == 'Technical Questions') {
      screen = const TechnicalQuestionsScreen();
    } else if (title == 'Mock Interview') {
      screen = const MockInterviewScreen();
    } else if (title == 'Tips & Tricks') {
      screen = const TipsAndTricksScreen();
    } else {
      screen = const Scaffold(
        body: Center(
          child: Text('Coming soon!'),
        ),
      );
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: theme.surface,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80, left: -60,
            child: _Blob(
                size: MediaQuery.of(context).size.width * 0.7,
                color: _blue.withOpacity(0.07)),
          ),
          Positioned(
            bottom: -60, right: -40,
            child: _Blob(
                size: MediaQuery.of(context).size.width * 0.55,
                color: _blue.withOpacity(0.05)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: theme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: _blue.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: theme.onSurface, size: 16),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Interview Prep',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: theme.onSurface,
                                    letterSpacing: -0.3)),
                            Text('Practice & master your interview skills',
                                style: TextStyle(
                                    fontSize: 12, color: theme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Search bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: _blue.withOpacity(0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(fontSize: 14, color: theme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Search prep materials...',
                        hintStyle: TextStyle(
                            color: theme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: theme.onSurfaceVariant.withOpacity(0.8), size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 18, color: theme.onSurfaceVariant.withOpacity(0.8)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: _blue, width: 1.5)),
                      ),
                    ),
                  ),
                ),
                // ── Count label ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                  child: Text(
                    '${_filtered.length} prep item${_filtered.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.onSurfaceVariant),
                  ),
                ),
                // ── Grid ──
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text('No prep materials found.',
                              style: TextStyle(color: theme.onSurfaceVariant)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.95,
                              ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _PrepCard(
                            item: _filtered[i],
                            onTap: () => _showDetail(_filtered[i]),
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

// ─────────────────────────────────────────────────────────────────────────────
// PREP CARD
// ─────────────────────────────────────────────────────────────────────────────
class _PrepCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  const _PrepCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _blue.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            // Icon section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.10),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18)),
                ),
                child: Center(
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Text section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.onSurface),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] as String,
                    style: TextStyle(
                        fontSize: 10, color: theme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOB
// ─────────────────────────────────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}