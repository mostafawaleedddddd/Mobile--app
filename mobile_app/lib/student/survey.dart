import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────
const _white = Colors.white; 

// accent palette — one per section 
const _accentBlue   = Color(0xFF3B82F6);
const _accentPurple = Color(0xFF8B5CF6);
const _accentTeal   = Color(0xFF0EA5E9);
const _accentGreen  = Color(0xFF10B981);
const _accentOrange = Color(0xFFF59E0B);
const _accentIndigo = Color(0xFF6366F1);

class SurveyScreen extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> internships; // from profile screen

  const SurveyScreen({
    super.key,
    required this.userId,
    required this.internships,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with SingleTickerProviderStateMixin {
  final _db = Supabase.instance.client;

  // ── state ──────────────────────────────────
  Map<String, dynamic>? _selectedInternship;
  bool _alreadySubmitted    = false;
  bool _isCheckingDuplicate = false;
  bool _isSubmitting        = false;
  bool _submitted           = false;

  // ── picker state ───────────────────────────
  final _searchCtrl          = TextEditingController();
  List<_SurveyOption> _allOptions      = [];
  List<_SurveyOption> _filteredOptions = [];
  bool _searchLoading = false;
  bool _dropdownOpen  = false;

  // Section A: General Experience
  int  _overallRating    = 0;
  bool _wouldRecommend   = true;

  // Section B: Work Environment
  int    _mentorQuality  = 0;
  int    _communication  = 0;
  String _workMode       = 'Onsite';

  // Section C: Tasks & Feedback
  bool   _tasksAligned      = true;
  final _improvementCtrl    = TextEditingController();
  // Section D: Open Feedback
  final _bestPartCtrl       = TextEditingController();
  final _biggestChalCtrl    = TextEditingController();

  late AnimationController _successCtrl;
  late Animation<double>   _successAnim;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _successAnim =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _searchCtrl.addListener(_onSearchChanged);
    _buildOptions();
  }

  @override
  void dispose() {
    _improvementCtrl.dispose();
    _bestPartCtrl.dispose();
    _biggestChalCtrl.dispose();
    _searchCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── options builder ─────────────────────────
  Future<void> _buildOptions() async {
    setState(() => _searchLoading = true);
    final List<_SurveyOption> opts = [];

    // 1. Manual internships already on profile
    for (final i in widget.internships) {
      opts.add(_SurveyOption(
        id:      i['id'] as int,
        company: i['company'] ?? '',
        role:    i['department'] ?? '',
        source:  'manual',
        raw:     i,
      ));
    }

    // 2. Job applications from DB (applied through InternshipsPage)
    try {
      final apps = await _db
          .from('Job_applications')
          .select('id, job_id, Job_postings(id, title, Company_profile(name))')
          .eq('student_id', widget.userId);
      for (final a in (apps as List)) {
        final posting = a['Job_postings'];
        if (posting == null) continue;
        final company = posting['Company_profile']?['name'] ?? '';
        final jobId   = posting['id'] as int;
        // avoid duplicate if same job already listed
        if (opts.any((o) => o.source == 'applied' && o.id == jobId)) continue;
        opts.add(_SurveyOption(
          id:      jobId,
          company: company,
          role:    posting['title'] ?? '',
          source:  'applied',
          raw:     {'id': jobId, 'company': company},
        ));
      }
    } catch (_) {}

    // 3. All companies from DB (so user can select even without a prior application)
    try {
      final companies = await _db
          .from('Company_profile')
          .select('id, name, industry');
      for (final c in (companies as List)) {
        final name = c['name'] ?? '';
        if (opts.any((o) => o.company.toLowerCase() == name.toLowerCase())) continue;
        opts.add(_SurveyOption(
          id:      c['id'] as int,
          company: name,
          role:    c['industry'] ?? '',
          source:  'company',
          raw:     {'id': c['id'], 'company': name},
        ));
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _allOptions      = opts;
        _filteredOptions = List.from(opts);
        _searchLoading   = false;
      });
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _dropdownOpen    = q.isNotEmpty;
      _filteredOptions = q.isEmpty
          ? List.from(_allOptions)
          : _allOptions.where((o) {
              return o.company.toLowerCase().contains(q) ||
                  o.role.toLowerCase().contains(q);
            }).toList();
    });
  }

  void _selectOption(_SurveyOption opt) async {
    setState(() {
      _selectedInternship = opt.raw;
      _searchCtrl.text    = opt.company + (opt.role.isNotEmpty ? ' — ${opt.role}' : '');
      _dropdownOpen       = false;
    });
    FocusScope.of(context).unfocus();

    // Check for duplicate survey
    setState(() => _isCheckingDuplicate = true);
    try {
      final existing = await _db
          .from('Survey')
          .select('id')
          .eq('user_id', widget.userId)
          .eq('internship_id', opt.id)
          .maybeSingle();
      if (mounted) setState(() { _alreadySubmitted = existing != null; _isCheckingDuplicate = false; });
    } catch (_) {
      if (mounted) setState(() => _isCheckingDuplicate = false);
    }
  }

  // ── validation ──────────────────────────────
  String? _validate() {
    if (_selectedInternship == null)  return 'Please select an internship.';
    if (_overallRating    == 0)       return 'Please rate your overall experience.';
    if (_mentorQuality    == 0)       return 'Please rate mentor quality.';
    if (_communication    == 0)       return 'Please rate communication.';
    return null;
  }

  // ── submit ──────────────────────────────────
  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _db.from('Survey').insert({
        'user_id':               widget.userId,
        'internship_id':         _selectedInternship!['id'],
        'company_name':          _selectedInternship!['company'],
        // A: General Experience
        'overall_rating':        _overallRating,
        'would_recommend':       _wouldRecommend,
        // B: Work Environment
        'mentor_quality':        _mentorQuality,
        'communication':         _communication,
        'remote_or_onsite':      _workMode,
        // C: Tasks & Feedback
        'tasks_aligned':         _tasksAligned,
        'improvement_suggestions': _improvementCtrl.text.trim(),
        // D: Open Feedback
        'best_part':             _bestPartCtrl.text.trim(),
        'biggest_challenge':     _biggestChalCtrl.text.trim(),
      });

      setState(() { _isSubmitting = false; _submitted = true; });
      _successCtrl.forward();
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── build ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    if (_submitted) return _buildSuccess(theme);

    return Scaffold(
      backgroundColor: theme.surface,
      body: Stack(
        children: [
          // subtle background decoration
          Positioned(top: -60, right: -40,
              child: _Circle(size: 200, color: _accentPurple.withOpacity(0.06))),
          Positioned(bottom: 100, left: -50,
              child: _Circle(size: 180, color: _accentTeal.withOpacity(0.06))),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(theme),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInternshipPicker(theme),
                        if (_alreadySubmitted)   _buildAlreadySubmittedBanner(theme)
                        else if (_selectedInternship != null) ...[
                          _buildSectionA(theme),
                          _buildSectionB(theme),
                          _buildSectionC(theme),
                          _buildSectionD(theme),
                          const SizedBox(height: 16),
                          _buildSubmitButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(child: CircularProgressIndicator(color: _white)),
            ),
        ],
      ),
    );
  }

  // ── top bar ─────────────────────────────────
  Widget _buildTopBar(ColorScheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(color: theme.surfaceContainerHighest,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_accentBlue, _accentPurple]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment_turned_in_rounded, color: _white, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Internship Survey',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: theme.onSurface, letterSpacing: -0.3)),
          Text('Share your experience to help others',
              style: TextStyle(fontSize: 11.5, color: theme.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  // ── internship picker ───────────────────────
  Widget _buildInternshipPicker(ColorScheme theme) {
    return _SurveyCard(
      accent: _accentBlue,
      icon: Icons.business_center_rounded,
      title: 'Select Internship / Company',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search field ──
          TextField(
            controller: _searchCtrl,
            style: TextStyle(fontSize: 14, color: theme.onSurface),
            decoration: InputDecoration(
              hintText: 'Type a company or internship name...',
              hintStyle: TextStyle(color: theme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
              filled: true,
              fillColor: theme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              prefixIcon: Icon(Icons.search_rounded, color: theme.onSurfaceVariant.withOpacity(0.8), size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded, size: 16, color: theme.onSurfaceVariant.withOpacity(0.8)),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _selectedInternship = null;
                          _dropdownOpen = false;
                          _alreadySubmitted = false;
                        });
                      })
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outline)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outline)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentBlue, width: 1.8)),
            ),
          ),

          // ── Loading indicator ──
          if (_searchLoading)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accentBlue)),
                const SizedBox(width: 8),
                Text('Loading options...', style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
              ]),
            ),

          // ── Dropdown results ──
          if (_dropdownOpen && _filteredOptions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.outline),
                boxShadow: [
                  BoxShadow(color: _accentBlue.withOpacity(0.08),
                      blurRadius: 14, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _filteredOptions.length,
                  itemBuilder: (_, i) {
                    final opt = _filteredOptions[i];
                    final isLast = i == _filteredOptions.length - 1;
                    return InkWell(
                      onTap: () => _selectOption(opt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : Border(
                                  bottom: BorderSide(color: theme.outline, width: 0.8)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: _sourceColor(opt.source).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_sourceIcon(opt.source),
                                  size: 16, color: _sourceColor(opt.source)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(opt.company,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: theme.onSurface),
                                      overflow: TextOverflow.ellipsis),
                                  if (opt.role.isNotEmpty)
                                    Text(opt.role,
                                        style: TextStyle(
                                            fontSize: 11, color: theme.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _sourceColor(opt.source).withOpacity(0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_sourceLabel(opt.source),
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _sourceColor(opt.source))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          if (_dropdownOpen && _filteredOptions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('No matches found.',
                  style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
            ),

          // ── Selected confirmation ──
          if (_selectedInternship != null && !_dropdownOpen) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _accentBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accentBlue.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: _accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedInternship!['company']}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accentBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
          ],

          if (_isCheckingDuplicate)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(children: [
                const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accentBlue)),
                const SizedBox(width: 8),
                Text('Checking...', style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
              ]),
            ),
        ],
      ),
    );
  }

  Color _sourceColor(String src) {
    switch (src) {
      case 'manual':  return _accentPurple;
      case 'applied': return _accentGreen;
      default:        return _accentBlue;
    }
  }

  IconData _sourceIcon(String src) {
    switch (src) {
      case 'manual':  return Icons.history_edu_rounded;
      case 'applied': return Icons.check_circle_outline_rounded;
      default:        return Icons.business_rounded;
    }
  }

  String _sourceLabel(String src) {
    switch (src) {
      case 'manual':  return 'MY HISTORY';
      case 'applied': return 'APPLIED';
      default:        return 'COMPANY';
    }
  }

  Widget _buildAlreadySubmittedBanner(ColorScheme theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentOrange.withOpacity(0.4)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: _accentOrange.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.info_rounded, color: _accentOrange, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text(
          'You already submitted a survey for this internship.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface),
        )),
      ]),
    );
  }

  // ── SECTION A: General Experience ───────────
  Widget _buildSectionA(ColorScheme theme) {
    return _SurveyCard(
      accent: _accentPurple,
      icon: Icons.star_rounded,
      title: 'A — General Experience',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _starQuestion('Overall Experience', _overallRating, _accentPurple, theme,
            (v) => setState(() => _overallRating = v)),
        const SizedBox(height: 18),
        _yesNoQuestion(
          'Would you recommend this internship to a friend?',
          _wouldRecommend,
          _accentPurple,
          theme,
          (v) => setState(() => _wouldRecommend = v),
        ),
      ]),
    );
  }

  // ── SECTION B: Work Environment ─────────────
  Widget _buildSectionB(ColorScheme theme) {
    return _SurveyCard(
      accent: _accentTeal,
      icon: Icons.groups_rounded,
      title: 'B — Work Environment',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _starQuestion('Mentor Quality', _mentorQuality, _accentTeal, theme,
            (v) => setState(() => _mentorQuality = v)),
        const SizedBox(height: 16),
        _starQuestion('Communication', _communication, _accentTeal, theme,
            (v) => setState(() => _communication = v)),
        const SizedBox(height: 18),
        _qLabel('Work Mode', theme),
        const SizedBox(height: 10),
        Row(children: ['Remote','Onsite','Hybrid'].map((mode) {
          final sel = _workMode == mode;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _workMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? _accentTeal : _accentTeal.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? _accentTeal : theme.outline),
                ),
                child: Text(mode, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: sel ? _white : theme.onSurfaceVariant)),
              ),
            ),
          ));
        }).toList()),
      ]),
    );
  }

  // ── SECTION C: Tasks & Feedback ───────────────
  Widget _buildSectionC(ColorScheme theme) {
    return _SurveyCard(
      accent: _accentGreen,
      icon: Icons.build_rounded,
      title: 'C — Tasks & Feedback',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _yesNoQuestion(
          'Did the tasks align with your expectations?',
          _tasksAligned, _accentGreen, theme,
          (v) => setState(() => _tasksAligned = v),
        ),
        const SizedBox(height: 18),
        _qLabel('Suggestions for Improvement (optional)', theme),
        const SizedBox(height: 8),
        _textField(_improvementCtrl, 'What could the company improve for interns?', theme, maxLines: 3, maxLength: 500),
      ]),
    );
  }

  // ── SECTION D: Open Feedback ──────────────────
  Widget _buildSectionD(ColorScheme theme) {
    return _SurveyCard(
      accent: _accentIndigo,
      icon: Icons.chat_bubble_rounded,
      title: 'D — Open Feedback',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _qLabel('What was the best part of your internship?', theme),
        const SizedBox(height: 8),
        _textField(_bestPartCtrl, 'Share what you loved...', theme, maxLines: 3),
        const SizedBox(height: 18),
        _qLabel('What was your biggest challenge?', theme),
        const SizedBox(height: 8),
        _textField(_biggestChalCtrl, 'Describe a challenge you faced...', theme, maxLines: 3),
      ]),
    );
  }

  // ── submit button ────────────────────────────
  Widget _buildSubmitButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accentBlue, _accentPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: _accentBlue.withOpacity(0.38),
                blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: InkWell(
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(18),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.send_rounded, color: _white, size: 20),
            SizedBox(width: 10),
            Text('Submit Survey', style: TextStyle(
                color: _white, fontSize: 16,
                fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          ]),
        ),
      ),
    );
  }

  // ── success screen ───────────────────────────
  Widget _buildSuccess(ColorScheme theme) {
    return Scaffold(
      backgroundColor: theme.surface,
      body: Center(
        child: ScaleTransition(
          scale: _successAnim,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_accentGreen, _accentTeal],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _accentGreen.withOpacity(0.35),
                        blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.check_rounded, color: _white, size: 52),
                ),
                const SizedBox(height: 28),
                const Text('Survey Submitted Successfully!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                        color: _accentGreen, letterSpacing: -0.5)),
                const SizedBox(height: 10),
                Text(
                  'Thank you for sharing your experience.\nYour feedback helps future interns!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: theme.onSurfaceVariant, height: 1.55),
                ),
                const SizedBox(height: 36),
                GestureDetector(
                  onTap: () => setState(() {
                    _submitted = false;
                    _successCtrl.reset();
                    _selectedInternship = null;
                    _searchCtrl.clear();
                    _dropdownOpen = false;
                    _alreadySubmitted = false;
                    _overallRating = _mentorQuality = _communication = 0;
                    _workMode = 'Onsite';
                    _tasksAligned = true;
                    _wouldRecommend = true;
                    _improvementCtrl.clear();
                    _bestPartCtrl.clear();
                    _biggestChalCtrl.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_accentBlue, _accentPurple]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _accentBlue.withOpacity(0.3),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: const Text('Fill Another Survey',
                        style: TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── reusable question widgets ─────────────────

  Widget _starQuestion(String label, int value, Color accent, ColorScheme theme, ValueChanged<int> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qLabel(label, theme),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) {
        final filled = i < value;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.only(right: 6),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled ? accent : theme.outline,
              size: 34,
            ),
          ),
        );
      })),
      if (value > 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_starLabel(value),
              style: TextStyle(fontSize: 11.5, color: accent, fontWeight: FontWeight.w600)),
        ),
    ]);
  }

  Widget _yesNoQuestion(String label, bool value, Color accent, ColorScheme theme, ValueChanged<bool> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _qLabel(label, theme),
      const SizedBox(height: 10),
      Row(children: [
        _choiceBtn('Yes', value == true, accent, theme, () => onChanged(true)),
        const SizedBox(width: 10),
        _choiceBtn('No', value == false, accent, theme, () => onChanged(false)),
      ]),
    ]);
  }

  Widget _choiceBtn(String label, bool active, Color accent, ColorScheme theme, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? accent : accent.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? accent : theme.outline),
            boxShadow: active
                ? [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]
                : [],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(active
                ? (label == 'Yes' ? Icons.thumb_up_rounded : Icons.thumb_down_rounded)
                : (label == 'Yes' ? Icons.thumb_up_outlined : Icons.thumb_down_outlined),
                size: 16, color: active ? _white : theme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: active ? _white : theme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }

  Widget _qLabel(String text, ColorScheme theme) => Text(text,
      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: theme.onSurface, height: 1.4));

  
  Widget _textField(TextEditingController ctrl, String hint, ColorScheme theme, {int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      style: TextStyle(fontSize: 13.5, color: theme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
        filled: true, fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        counterStyle: TextStyle(fontSize: 11, color: theme.onSurfaceVariant),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accentBlue, width: 1.8)),
      ),
    );
  }

  String _starLabel(int v) =>
      ['', '😞 Poor', '😕 Fair', '😊 Good', '😄 Great', '🤩 Excellent'][v];
}

// ─────────────────────────────────────────────
// SURVEY CARD SHELL
// ─────────────────────────────────────────────
class _SurveyCard extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String title;
  final Widget child;

  const _SurveyCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.08), blurRadius: 20,
              spreadRadius: 0, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // colored header strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: accent.withOpacity(0.15))),
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: _white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: accent, letterSpacing: -0.2)),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ─────────────────────────────────────────────
// SURVEY OPTION MODEL
// ─────────────────────────────────────────────
class _SurveyOption {
  final int    id;
  final String company;
  final String role;
  final String source; // 'manual' | 'applied' | 'company'
  final Map<String, dynamic> raw;

  const _SurveyOption({
    required this.id,
    required this.company,
    required this.role,
    required this.source,
    required this.raw,
  });
}