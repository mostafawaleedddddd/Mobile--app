// ─────────────────────────────────────────────────────────────────────────────
// company_home.dart
// Full home screen for the Hiring Company role.
// Tabs: Dashboard  |  Post a Job  |  Applicants  |  Profile
//
// Supabase tables used:
//   Company_profile  – id, name, email, industry, location
//   Job_postings     – id, company_id, title, description, requirements,
//                      location, duration, spots_available, created_at
//   Job_applications – id, job_id, student_id, student_name, student_email,
//                      status ('pending'|'accepted'|'rejected'), applied_at
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'company_model.dart';
import 'company_session.dart';

// ─── COLORS ──────────────────────────────────────────────────────────────────
const _teal      = Color(0xFF00C6A7);
const _tealDark  = Color(0xFF009E87);
const _tealLight = Color(0xFFE6FBF7);
const _bg        = Color(0xFFF4FDFB);
const _white     = Colors.white;
const _textDark  = Color(0xFF1E293B);
const _textGrey  = Color(0xFF64748B);
const _border    = Color(0xFFE2E8F0);

// Status colour helpers
const _pendingColor  = Color(0xFFF59E0B);
const _acceptColor   = Color(0xFF10B981);
const _rejectColor   = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────────────────────
// COMPANY HOME PAGE
// ─────────────────────────────────────────────────────────────────────────────
class CompanyHomePage extends StatefulWidget {
  final int companyId;
  const CompanyHomePage({super.key, required this.companyId});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  final _db = Supabase.instance.client;

  int _navIndex = 0;

  // ── State ──
  bool _isLoading    = true;
  CompanyProfile? _company;
  List<JobPosting>     _jobs         = [];
  List<JobApplication> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── DATA LOADING ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadCompany(), _loadJobs()]);
      await _loadApplications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCompany() async {
    final row = await _db
        .from('Company_profile')
        .select()
        .eq('id', widget.companyId)
        .maybeSingle();
    if (row != null && mounted) {
      setState(() => _company = CompanyProfile.fromMap(row));
      CompanySession.setCompany(
        companyEmail: _company!.email,
        id: _company!.id,
        name: _company!.name,
      );
    }
  }

  Future<void> _loadJobs() async {
    final rows = await _db
        .from('Job_postings')
        .select()
        .eq('company_id', widget.companyId)
        .order('created_at', ascending: false);
    if (mounted) {
      setState(() =>
          _jobs = (rows as List).map((r) => JobPosting.fromMap(r)).toList());
    }
  }

  Future<void> _loadApplications() async {
    if (_jobs.isEmpty) return;
    final jobIds = _jobs.map((j) => j.id).whereType<int>().toList();
    if (jobIds.isEmpty) return;

    final rows = await _db
        .from('Job_applications')
        .select()
        .inFilter('job_id', jobIds)
        .order('applied_at', ascending: false);
    if (mounted) {
      setState(() => _applications =
          (rows as List).map((r) => JobApplication.fromMap(r)).toList());
    }
  }

  // ─── APPLICATION ACTIONS ────────────────────────────────────────────────────

  Future<void> _updateApplicationStatus(
      JobApplication app, String newStatus) async {
    try {
      await _db
          .from('Job_applications')
          .update({'status': newStatus})
          .eq('id', app.id!);

      setState(() {
        _applications = _applications.map((a) {
          return a.id == app.id ? a.copyWith(status: newStatus) : a;
        }).toList();
      });

      if (mounted) {
        final msg = newStatus == 'accepted'
            ? '✅ ${app.studentName} accepted!'
            : '❌ ${app.studentName} rejected.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: newStatus == 'accepted' ? _acceptColor : _rejectColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _jobTitleForId(int jobId) {
    try {
      return _jobs.firstWhere((j) => j.id == jobId).title;
    } catch (_) {
      return 'Unknown Role';
    }
  }

  int get _pendingCount =>
      _applications.where((a) => a.status == 'pending').length;

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    final pages = [
      _DashboardTab(
        company: _company,
        jobs: _jobs,
        applications: _applications,
        greeting: _greeting(),
        pendingCount: _pendingCount,
        onRefresh: _loadData,
      ),
      _PostJobTab(
        companyId: widget.companyId,
        onJobPosted: () async {
          await _loadJobs();
          await _loadApplications();
          setState(() => _navIndex = 0);
        },
      ),
      _ApplicantsTab(
        applications: _applications,
        jobTitleForId: _jobTitleForId,
        onUpdateStatus: _updateApplicationStatus,
      ),
      _ProfileTab(
        company: _company,
        onLogout: () => Navigator.of(context).pop(),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: pages[_navIndex],
      bottomNavigationBar: _CompanyBottomBar(
        currentIndex: _navIndex,
        pendingCount: _pendingCount,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final CompanyProfile?     company;
  final List<JobPosting>     jobs;
  final List<JobApplication> applications;
  final String greeting;
  final int    pendingCount;
  final VoidCallback onRefresh;

  const _DashboardTab({
    required this.company,
    required this.jobs,
    required this.applications,
    required this.greeting,
    required this.pendingCount,
    required this.onRefresh,
  });

  int get _accepted  => applications.where((a) => a.status == 'accepted').length;
  int get _rejected  => applications.where((a) => a.status == 'rejected').length;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: _teal,
        onRefresh: () async => onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top header ──
              _DashboardHeader(company: company, greeting: greeting),

              const SizedBox(height: 24),

              // ── Stats row ──
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Active Jobs',
                      value: '${jobs.length}',
                      icon: Icons.work_outline_rounded,
                      gradient: const [Color(0xFF00C6A7), Color(0xFF009E87)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Applicants',
                      value: '${applications.length}',
                      icon: Icons.people_alt_outlined,
                      gradient: const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Accepted',
                      value: '$_accepted',
                      icon: Icons.check_circle_outline_rounded,
                      gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Pending',
                      value: '$pendingCount',
                      icon: Icons.hourglass_empty_rounded,
                      gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Recent Jobs ──
              const Text('Your Job Postings',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _textDark)),

              const SizedBox(height: 14),

              if (jobs.isEmpty)
                _EmptyState(
                  icon: Icons.post_add_rounded,
                  message: 'No jobs posted yet.\nTap "Post Job" to get started.',
                )
              else
                ...jobs.map((j) => _JobSummaryCard(job: j, applications: applications)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final CompanyProfile? company;
  final String greeting;
  const _DashboardHeader({required this.company, required this.greeting});

  @override
  Widget build(BuildContext context) {
    final name = company?.name ?? 'Company';
    final initials = company?.initials ?? 'C';
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_teal, _tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _teal.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting,',
                  style: const TextStyle(fontSize: 13, color: _textGrey)),
              Text(name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: _textGrey, size: 20),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: gradient.first.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.80),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobSummaryCard extends StatelessWidget {
  final JobPosting job;
  final List<JobApplication> applications;
  const _JobSummaryCard({required this.job, required this.applications});

  int get _count => applications.where((a) => a.jobId == job.id).length;
  int get _pending =>
      applications.where((a) => a.jobId == job.id && a.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.work_outline_rounded, color: _teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${job.location} · ${job.duration}',
                    style:
                        const TextStyle(fontSize: 12, color: _textGrey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_count applicants',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _teal)),
              if (_pending > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _pendingColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$_pending pending',
                      style: const TextStyle(
                          fontSize: 10,
                          color: _pendingColor,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — POST A JOB
// ─────────────────────────────────────────────────────────────────────────────
class _PostJobTab extends StatefulWidget {
  final int        companyId;
  final VoidCallback onJobPosted;
  const _PostJobTab({required this.companyId, required this.onJobPosted});

  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  final _db       = Supabase.instance.client;
  final _formKey  = GlobalKey<FormState>();

  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _reqCtrl      = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _spotsCtrl    = TextEditingController();
  bool  _isLoading    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _reqCtrl.dispose();
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    _spotsCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _reqCtrl.clear();
    _locationCtrl.clear();
    _durationCtrl.clear();
    _spotsCtrl.clear();
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _db.from('Job_postings').insert({
        'company_id':       widget.companyId,
        'title':            _titleCtrl.text.trim(),
        'description':      _descCtrl.text.trim(),
        'requirements':     _reqCtrl.text.trim(),
        'location':         _locationCtrl.text.trim(),
        'duration':         _durationCtrl.text.trim(),
        'spots_available':  int.tryParse(_spotsCtrl.text.trim()) ?? 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Job posted successfully!',
                style: TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _clearForm();
        widget.onJobPosted();
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text('Post a Job',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _textDark)),
            const SizedBox(height: 4),
            const Text('Fill in the details for your internship opportunity.',
                style: TextStyle(fontSize: 13, color: _textGrey)),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormLabel('Job Title'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _titleCtrl,
                      hint: 'e.g. Flutter Development Intern',
                      icon: Icons.work_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Job title is required'
                          : null,
                    ),

                    const SizedBox(height: 14),
                    _FormLabel('Job Description'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _descCtrl,
                      hint: 'Describe the role, responsibilities and what the intern will work on...',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required'
                          : null,
                    ),

                    const SizedBox(height: 14),
                    _FormLabel('Requirements'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _reqCtrl,
                      hint: 'e.g. Knowledge of Flutter, Dart basics, strong communication skills...',
                      icon: Icons.checklist_rounded,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requirements are required'
                          : null,
                    ),

                    const SizedBox(height: 14),
                    _FormLabel('Location'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _locationCtrl,
                      hint: 'e.g. Cairo, Egypt  /  Remote',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Location is required'
                          : null,
                    ),

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel('Duration'),
                              const SizedBox(height: 6),
                              _FormField(
                                controller: _durationCtrl,
                                hint: 'e.g. 3 months',
                                icon: Icons.schedule_outlined,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FormLabel('Spots Available'),
                              const SizedBox(height: 6),
                              _FormField(
                                controller: _spotsCtrl,
                                hint: 'e.g. 5',
                                icon: Icons.group_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(v.trim()) == null) {
                                    return 'Must be a number';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isLoading ? 'Posting...' : 'Post Job',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — APPLICANTS
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicantsTab extends StatefulWidget {
  final List<JobApplication> applications;
  final String Function(int) jobTitleForId;
  final Future<void> Function(JobApplication, String) onUpdateStatus;

  const _ApplicantsTab({
    required this.applications,
    required this.jobTitleForId,
    required this.onUpdateStatus,
  });

  @override
  State<_ApplicantsTab> createState() => _ApplicantsTabState();
}

class _ApplicantsTabState extends State<_ApplicantsTab> {
  String _filter = 'all'; // 'all' | 'pending' | 'accepted' | 'rejected'

  List<JobApplication> get _filtered {
    if (_filter == 'all') return widget.applications;
    return widget.applications.where((a) => a.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Applicants',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _textDark)),
                const SizedBox(height: 4),
                Text(
                  '${widget.applications.length} total · '
                  '${widget.applications.where((a) => a.status == 'pending').length} pending review',
                  style: const TextStyle(fontSize: 13, color: _textGrey),
                ),
              ],
            ),
          ),

          // ── Filter chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['all', 'pending', 'accepted', 'rejected']
                    .map((f) => _FilterChip(
                          label: f[0].toUpperCase() + f.substring(1),
                          active: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── List ──
          Expanded(
            child: _filtered.isEmpty
                ? _EmptyState(
                    icon: Icons.inbox_outlined,
                    message: _filter == 'all'
                        ? 'No applications yet.'
                        : 'No $_filter applications.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final app = _filtered[i];
                      return _ApplicantCard(
                        application: app,
                        jobTitle: widget.jobTitleForId(app.jobId),
                        onAccept: app.status == 'pending'
                            ? () => widget.onUpdateStatus(app, 'accepted')
                            : null,
                        onReject: app.status == 'pending'
                            ? () => widget.onUpdateStatus(app, 'rejected')
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _teal : _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? _teal : _border, width: active ? 0 : 1.2),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: _teal.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? _white : _textGrey,
          ),
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final JobApplication application;
  final String        jobTitle;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ApplicantCard({
    required this.application,
    required this.jobTitle,
    this.onAccept,
    this.onReject,
  });

  Color get _statusColor {
    switch (application.status) {
      case 'accepted': return _acceptColor;
      case 'rejected': return _rejectColor;
      default:         return _pendingColor;
    }
  }

  String get _statusLabel {
    switch (application.status) {
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      default:         return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Student info row ──
          Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(application.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(application.studentName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textDark),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(application.studentEmail,
                        style: const TextStyle(
                            fontSize: 12, color: _textGrey),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Applied for ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.work_outline_rounded,
                    size: 13, color: _teal),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Applied for: $jobTitle',
                      style: const TextStyle(
                          fontSize: 12,
                          color: _tealDark,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),

          // ── Accept / Reject buttons (only for pending) ──
          if (application.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: _rejectColor),
                    label: const Text('Reject',
                        style: TextStyle(
                            fontSize: 13,
                            color: _rejectColor,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _rejectColor, width: 1.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Accept',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _acceptColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — COMPANY PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final CompanyProfile? company;
  final VoidCallback    onLogout;
  const _ProfileTab({required this.company, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final c = company;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // ── Avatar + name ──
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_teal, _tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: _teal.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Center(
                child: Text(c?.initials ?? 'C',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
              ),
            ),

            const SizedBox(height: 16),
            Text(c?.name ?? 'Company',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textDark)),
            const SizedBox(height: 4),
            Text(c?.email ?? '',
                style: const TextStyle(fontSize: 14, color: _textGrey)),

            const SizedBox(height: 28),

            // ── Info cards ──
            _ProfileInfoCard(children: [
              _ProfileRow(
                  icon: Icons.category_outlined,
                  label: 'Industry',
                  value: c?.industry ?? '—'),
              const Divider(height: 1, color: _border),
              _ProfileRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: c?.location ?? '—'),
              if (c?.description != null && c!.description!.isNotEmpty) ...[
                const Divider(height: 1, color: _border),
                _ProfileRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    value: c.description!),
              ],
            ]),

            const SizedBox(height: 24),

            // ── Logout ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  CompanySession.clear();
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded,
                    color: _rejectColor, size: 18),
                label: const Text('Log Out',
                    style: TextStyle(
                        color: _rejectColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _rejectColor, width: 1.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileInfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: children),
      );
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _ProfileRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _teal),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textGrey)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textDark),
                  textAlign: TextAlign.end),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAVIGATION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _CompanyBottomBar extends StatelessWidget {
  final int currentIndex;
  final int pendingCount;
  final ValueChanged<int> onTap;

  const _CompanyBottomBar({
    required this.currentIndex,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
              color: _teal.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  active: currentIndex == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.post_add_rounded,
                  label: 'Post Job',
                  active: currentIndex == 1,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Applicants',
                  active: currentIndex == 2,
                  badge: pendingCount,
                  onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.business_rounded,
                  label: 'Profile',
                  active: currentIndex == 3,
                  onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final int      badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? _tealLight : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: active ? _teal : _textGrey, size: 22),
              ),
              if (badge > 0)
                Positioned(
                  right: 8,
                  top: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: _pendingColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? _teal : _textGrey,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED — FORM HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
      );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
          fontSize: 14, color: _textDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        errorStyle: const TextStyle(
            fontSize: 11, color: Color(0xFFEF4444), height: 1.3),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: const Color(0xFF94A3B8), size: 18)
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

// ─────────────────────────────────────────────────────────────────────────────
// SHARED — EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String   message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: _teal, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  color: _textGrey,
                  height: 1.6,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
