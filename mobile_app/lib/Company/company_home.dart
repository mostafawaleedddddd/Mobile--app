// ─────────────────────────────────────────────────────────────────────────────
// company_home.dart  —  Full home screen for the Hiring Company role.
// Tabs: Dashboard  |  Post a Job  |  Applicants  |  Profile
//
// Supabase tables:
//   Company_profile  – id, name, email, industry, location, description
//   Job_postings     – id, company_id, title, description, requirements,
//                      location, duration, spots_available, created_at
//   Job_applications – id, job_id, student_id, student_name, student_email,
//                      status (pending|accepted|rejected|interview), applied_at
//   Profile_info     – user_id, about, skills  (comma-separated)
//   Certificates     – id, user_id, title, description, date, image_url
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import 'company_model.dart';
import 'company_session.dart';

// ── COLORS (Brand & Status Accents) ──────────────────────────────────────────
const _teal = Color(0xFF00C6A7);
const _tealDark = Color(0xFF009E87);
const _pendingColor = Color(0xFFF59E0B);
const _acceptColor = Color(0xFF10B981);
const _rejectColor = Color(0xFFEF4444);
const _interviewColor = Color(0xFF7C3AED);

// ─────────────────────────────────────────────────────────────────────────────
// ROOT PAGE
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
  bool _loading = true;
  CompanyProfile? _company;
  List<JobPosting> _jobs = [];
  List<JobApplication> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_loadCompany(), _loadJobs()]);
      await _loadApplications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      setState(
        () => _jobs = (rows as List).map((r) => JobPosting.fromMap(r)).toList(),
      );
    }
  }

  Future<void> _loadApplications() async {
    if (_jobs.isEmpty) return;
    final ids = _jobs.map((j) => j.id).whereType<int>().toList();
    if (ids.isEmpty) return;
    final rows = await _db
        .from('Job_applications')
        .select()
        .inFilter('job_id', ids)
        .order('applied_at', ascending: false);
    if (mounted) {
      setState(
        () => _applications = (rows as List)
            .map((r) => JobApplication.fromMap(r))
            .toList(),
      );
    }
  }

  Future<void> _updateStatus(JobApplication app, String status) async {
    await _db
        .from('Job_applications')
        .update({'status': status})
        .eq('id', app.id!);
    setState(
      () => _applications = _applications
          .map((a) => a.id == app.id ? a.copyWith(status: status) : a)
          .toList(),
    );
    if (!mounted) return;
    final msgs = {
      'accepted': '✅ ${app.studentName} accepted!',
      'rejected': '❌ ${app.studentName} rejected.',
      'interview': '📅 Interview requested for ${app.studentName}!',
    };
    final colors = {
      'accepted': _acceptColor,
      'rejected': _rejectColor,
      'interview': _interviewColor,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msgs[status] ?? 'Updated',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colors[status] ?? _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _removeApplicant(JobApplication app) async {
    await _db.from('Job_applications').delete().eq('id', app.id!);
    setState(() => _applications.removeWhere((a) => a.id == app.id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${app.studentName} removed.'),
          backgroundColor: _rejectColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : 'Good evening';
  }

  String _titleFor(int jobId) {
    try {
      return _jobs.firstWhere((j) => j.id == jobId).title;
    } catch (_) {
      return 'Unknown Role';
    }
  }

  int get _pendingCount =>
      _applications.where((a) => a.status == 'pending').length;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator(color: _teal)),
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
        onUpdateStatus: _updateStatus,
        onRemove: _removeApplicant,
      ),
      _PostJobTab(
        companyId: widget.companyId,
        onPosted: () async {
          await _loadJobs();
          await _loadApplications();
          setState(() => _navIndex = 0);
        },
      ),
      _ApplicantsTab(
        applications: _applications,
        titleFor: _titleFor,
        onUpdateStatus: _updateStatus,
      ),
      _ProfileTab(
        company: _company,
        onLogout: () => Navigator.of(context).pop(),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: pages[_navIndex],
      // Removed the floatingActionButton entirely
      bottomNavigationBar: _BottomBar(
        index: _navIndex,
        pending: _pendingCount,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — DASHBOARD
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final CompanyProfile? company;
  final List<JobPosting> jobs;
  final List<JobApplication> applications;
  final String greeting;
  final int pendingCount;
  final VoidCallback onRefresh;
  final Future<void> Function(JobApplication, String) onUpdateStatus;
  final Future<void> Function(JobApplication) onRemove;

  const _DashboardTab({
    required this.company,
    required this.jobs,
    required this.applications,
    required this.greeting,
    required this.pendingCount,
    required this.onRefresh,
    required this.onUpdateStatus,
    required this.onRemove,
  });

  int get _accepted => applications.where((a) => a.status == 'accepted').length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

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
              _DashHeader(company: company, greeting: greeting),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      'Active Jobs',
                      '${jobs.length}',
                      Icons.work_outline_rounded,
                      const [Color(0xFF00C6A7), Color(0xFF009E87)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      'Applicants',
                      '${applications.length}',
                      Icons.people_alt_outlined,
                      const [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      'Accepted',
                      '$_accepted',
                      Icons.check_circle_outline_rounded,
                      const [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      'Pending',
                      '$pendingCount',
                      Icons.hourglass_empty_rounded,
                      const [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Your Job Postings',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any card to manage applicants',
                style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              if (jobs.isEmpty)
                const _EmptyState(
                  icon: Icons.post_add_rounded,
                  message:
                      'No jobs posted yet.\nTap "Post Job" to get started.',
                )
              else
                ...jobs.map(
                  (j) => _JobCard(
                    job: j,
                    applications: applications,
                    onTap: () => _openManagement(context, j),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openManagement(BuildContext ctx, JobPosting job) {
    final jobApps = applications.where((a) => a.jobId == job.id).toList();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobMgmtSheet(
        job: job,
        applications: jobApps,
        onUpdateStatus: onUpdateStatus,
        onRemove: onRemove,
      ),
    );
  }
}

class _DashHeader extends StatelessWidget {
  final CompanyProfile? company;
  final String greeting;
  const _DashHeader({required this.company, required this.greeting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // Company Initials Avatar
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
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              company?.initials ?? 'C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Greeting and Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
              ),
              Text(
                company?.name ?? 'Company',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: theme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Theme Toggle Button (Transparent style)
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) => IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: _teal,
              size: 24,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Notification Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: theme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<Color> g;
  const _StatCard(this.label, this.value, this.icon, this.g);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: g,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: g.first.withOpacity(0.28),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _JobCard extends StatelessWidget {
  final JobPosting job;
  final List<JobApplication> applications;
  final VoidCallback onTap;
  const _JobCard({
    required this.job,
    required this.applications,
    required this.onTap,
  });
  int get _total => applications.where((a) => a.jobId == job.id).length;
  int get _pending => applications
      .where((a) => a.jobId == job.id && a.status == 'pending')
      .length;
  int get _interview => applications
      .where((a) => a.jobId == job.id && a.status == 'interview')
      .length;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: _teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${job.location} · ${job.duration}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$_total applicants',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_pending > 0)
                      _Badge('$_pending pending', _pendingColor),
                    if (_pending > 0 && _interview > 0)
                      const SizedBox(width: 4),
                    if (_interview > 0)
                      _Badge('$_interview interview', _interviewColor),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String t;
  final Color c;
  const _Badge(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: c.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      t,
      style: TextStyle(fontSize: 9, color: c, fontWeight: FontWeight.w700),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB MANAGEMENT BOTTOM SHEET  (Dashboard → tap job card)
// ─────────────────────────────────────────────────────────────────────────────
class _JobMgmtSheet extends StatefulWidget {
  final JobPosting job;
  final List<JobApplication> applications;
  final Future<void> Function(JobApplication, String) onUpdateStatus;
  final Future<void> Function(JobApplication) onRemove;
  const _JobMgmtSheet({
    required this.job,
    required this.applications,
    required this.onUpdateStatus,
    required this.onRemove,
  });
  @override
  State<_JobMgmtSheet> createState() => _JobMgmtSheetState();
}

class _JobMgmtSheetState extends State<_JobMgmtSheet> {
  late List<JobApplication> _apps;
  @override
  void initState() {
    super.initState();
    _apps = List.from(widget.applications);
  }

  Future<void> _messageAll() async {
    final theme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Message All Applicants',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: theme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_apps.length} applicants will receive this message.',
              style: TextStyle(color: theme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                hintText: 'Type your message here...',
                hintStyle: TextStyle(
                  color: theme.onSurfaceVariant.withOpacity(0.6),
                ),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _teal, width: 1.8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Send',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('Job_messages').insert({
          'company_id': widget.job.companyId,
          'job_id': widget.job.id,
          'message': ctrl.text.trim(),
        });
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to ${_apps.length} applicants!'),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      color: _teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: theme.onSurface,
                          ),
                        ),
                        Text(
                          '${widget.job.location} · ${widget.job.duration}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _messageAll,
                  icon: const Icon(Icons.send_rounded, size: 16, color: _teal),
                  label: const Text(
                    'Message All',
                    style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _teal, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: theme.outline),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${_apps.length} Applicants',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _apps.isEmpty
                  ? const _EmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'No applicants yet.',
                    )
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _apps.length,
                      itemBuilder: (_, i) {
                        final app = _apps[i];
                        return _MgmtRow(
                          app: app,
                          onInterview: app.status == 'pending'
                              ? () async {
                                  await widget.onUpdateStatus(app, 'interview');
                                  setState(() {
                                    final idx = _apps.indexWhere(
                                      (a) => a.id == app.id,
                                    );
                                    if (idx != -1) {
                                      _apps[idx] = app.copyWith(
                                        status: 'interview',
                                      );
                                    }
                                  });
                                }
                              : null,
                          onRemove: () async {
                            await widget.onRemove(app);
                            setState(
                              () => _apps.removeWhere((a) => a.id == app.id),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MgmtRow extends StatelessWidget {
  final JobApplication app;
  final VoidCallback? onInterview;
  final VoidCallback onRemove;
  const _MgmtRow({required this.app, this.onInterview, required this.onRemove});

  Color get _sc {
    switch (app.status) {
      case 'accepted':
        return _acceptColor;
      case 'rejected':
        return _rejectColor;
      case 'interview':
        return _interviewColor;
      default:
        return _pendingColor;
    }
  }

  String get _sl {
    switch (app.status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'interview':
        return 'Interview';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    app.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.studentName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      app.studentEmail,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _sc.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _sl,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _sc,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (onInterview != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onInterview,
                    icon: const Icon(
                      Icons.event_rounded,
                      size: 13,
                      color: _interviewColor,
                    ),
                    label: const Text(
                      'Request Interview',
                      style: TextStyle(
                        fontSize: 11,
                        color: _interviewColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: _interviewColor,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              if (onInterview != null) const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: theme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: Text(
                      'Remove Applicant',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: theme.onSurface,
                      ),
                    ),
                    content: Text(
                      'Remove ${app.studentName}? This cannot be undone.',
                      style: TextStyle(
                        color: theme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: theme.onSurfaceVariant),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRemove();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rejectColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Remove',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(
                  Icons.person_remove_outlined,
                  size: 13,
                  color: _rejectColor,
                ),
                label: const Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 11,
                    color: _rejectColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _rejectColor, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
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
  final int companyId;
  final VoidCallback onPosted;
  const _PostJobTab({required this.companyId, required this.onPosted});
  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(),
      _descCtrl = TextEditingController(),
      _reqCtrl = TextEditingController(),
      _locCtrl = TextEditingController(),
      _durCtrl = TextEditingController(),
      _spotsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (var c in [
      _titleCtrl,
      _descCtrl,
      _reqCtrl,
      _locCtrl,
      _durCtrl,
      _spotsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _db.from('Job_postings').insert({
        'company_id': widget.companyId,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'requirements': _reqCtrl.text.trim(),
        'location': _locCtrl.text.trim(),
        'duration': _durCtrl.text.trim(),
        'spots_available': int.tryParse(_spotsCtrl.text.trim()) ?? 1,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Job posted!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        for (var c in [
          _titleCtrl,
          _descCtrl,
          _reqCtrl,
          _locCtrl,
          _durCtrl,
          _spotsCtrl,
        ]) {
          c.clear();
        }
        widget.onPosted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post a Job',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: theme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in the details for your internship opportunity.',
              style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FL('Job Title'),
                    const SizedBox(height: 6),
                    _FF(
                      _titleCtrl,
                      'e.g. Flutter Development Intern',
                      Icons.work_outline_rounded,
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    const _FL('Description'),
                    const SizedBox(height: 6),
                    _FF(
                      _descCtrl,
                      'Describe the role and what the intern will work on...',
                      Icons.description_outlined,
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      lines: 3,
                    ),
                    const SizedBox(height: 14),
                    const _FL('Requirements'),
                    const SizedBox(height: 6),
                    _FF(
                      _reqCtrl,
                      'Skills and qualifications required...',
                      Icons.checklist_rounded,
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                      lines: 3,
                    ),
                    const SizedBox(height: 14),
                    const _FL('Location'),
                    const SizedBox(height: 6),
                    _FF(
                      _locCtrl,
                      'e.g. Cairo, Egypt',
                      Icons.location_on_outlined,
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FL('Duration'),
                              const SizedBox(height: 6),
                              _FF(
                                _durCtrl,
                                'e.g. 3 months',
                                Icons.schedule_rounded,
                                (v) => (v == null || v.trim().isEmpty)
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
                              const _FL('Spots'),
                              const SizedBox(height: 6),
                              _FF(
                                _spotsCtrl,
                                'e.g. 3',
                                Icons.group_outlined,
                                (v) => (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                                type: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _loading ? 'Posting...' : 'Post Job',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
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

class _FL extends StatelessWidget {
  final String t;
  const _FL(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}

class _FF extends StatelessWidget {
  final TextEditingController c;
  final String h;
  final IconData i;
  final String? Function(String?) v;
  final int lines;
  final TextInputType type;
  const _FF(
    this.c,
    this.h,
    this.i,
    this.v, {
    this.lines = 1,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: type,
      validator: v,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: TextStyle(
        fontSize: 14,
        color: theme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: h,
        hintStyle: TextStyle(
          color: theme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 13,
        ),
        filled: true,
        fillColor: theme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        errorStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFFEF4444),
          height: 1.3,
        ),
        prefixIcon: lines == 1
            ? Icon(i, color: theme.onSurfaceVariant.withOpacity(0.8), size: 18)
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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — APPLICANTS  (tap card → Student Profile Sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _ApplicantsTab extends StatefulWidget {
  final List<JobApplication> applications;
  final String Function(int) titleFor;
  final Future<void> Function(JobApplication, String) onUpdateStatus;
  const _ApplicantsTab({
    required this.applications,
    required this.titleFor,
    required this.onUpdateStatus,
  });
  @override
  State<_ApplicantsTab> createState() => _ApplicantsTabState();
}

class _ApplicantsTabState extends State<_ApplicantsTab> {
  String _filter = 'all';
  List<JobApplication> get _filtered => _filter == 'all'
      ? widget.applications
      : widget.applications.where((a) => a.status == _filter).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applicants',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.applications.length} total · ${widget.applications.where((a) => a.status == 'pending').length} pending',
                  style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ['all', 'pending', 'interview', 'accepted', 'rejected']
                        .map(
                          (f) => _Chip(
                            label: f == 'all'
                                ? 'All'
                                : f[0].toUpperCase() + f.substring(1),
                            active: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final app = _filtered[i];
                      return _AppCard(
                        app: app,
                        jobTitle: widget.titleFor(app.jobId),
                        onAccept: app.status == 'pending'
                            ? () => widget.onUpdateStatus(app, 'accepted')
                            : null,
                        onReject: app.status == 'pending'
                            ? () => widget.onUpdateStatus(app, 'rejected')
                            : null,
                        onInterview: app.status == 'pending'
                            ? () => widget.onUpdateStatus(app, 'interview')
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

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _teal : theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? _teal : theme.outline,
            width: active ? 0 : 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _teal.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : theme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// Applicant Card — tappable to view student profile
class _AppCard extends StatelessWidget {
  final JobApplication app;
  final String jobTitle;
  final VoidCallback? onAccept, onReject, onInterview;
  const _AppCard({
    required this.app,
    required this.jobTitle,
    this.onAccept,
    this.onReject,
    this.onInterview,
  });

  Color get _sc {
    switch (app.status) {
      case 'accepted':
        return _acceptColor;
      case 'rejected':
        return _rejectColor;
      case 'interview':
        return _interviewColor;
      default:
        return _pendingColor;
    }
  }

  String get _sl {
    switch (app.status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'interview':
        return 'Interview';
      default:
        return 'Pending';
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProfileSheet(
          app: app,
          jobTitle: jobTitle,
          onAccept: onAccept,
          onReject: onReject,
          onInterview: onInterview,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      app.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.studentName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app.studentEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _sc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _sl,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _sc,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.work_outline_rounded,
                    size: 13,
                    color: _teal,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Applied for: $jobTitle',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.brightness == Brightness.dark
                            ? Colors.teal.shade200
                            : _tealDark,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 12,
                  color: theme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to view full profile',
                  style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant),
                ),
                const Spacer(),
                if (app.appliedAt != null)
                  Text(
                    _ago(app.appliedAt!),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (app.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: _rejectColor,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 12,
                          color: _rejectColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _rejectColor, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onInterview,
                      icon: const Icon(
                        Icons.event_rounded,
                        size: 14,
                        color: _interviewColor,
                      ),
                      label: const Text(
                        'Interview',
                        style: TextStyle(
                          fontSize: 12,
                          color: _interviewColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: _interviewColor,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Accept',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _acceptColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT PROFILE BOTTOM SHEET
// Fetches Profile_info (about, skills) and Certificates by student_id
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileSheet extends StatefulWidget {
  final JobApplication app;
  final String jobTitle;
  final VoidCallback? onAccept, onReject, onInterview;
  const _ProfileSheet({
    required this.app,
    required this.jobTitle,
    this.onAccept,
    this.onReject,
    this.onInterview,
  });
  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final _db = Supabase.instance.client;
  bool _loading = true;
  String _about = '';
  List<String> _skills = [];
  List<Map<String, dynamic>> _certs = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final info = await _db
          .from('Profile_info')
          .select()
          .eq('user_id', widget.app.studentId)
          .maybeSingle();
      final certs = await _db
          .from('Certificates')
          .select()
          .eq('user_id', widget.app.studentId)
          .order('id', ascending: false);
      if (mounted) {
        setState(() {
          _about = (info?['about'] ?? '') as String;
          final raw = (info?['skills'] ?? '') as String;
          _skills = raw.isEmpty
              ? []
              : raw
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
          _certs = (certs as List)
              .map((c) => c as Map<String, dynamic>)
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _sc {
    switch (widget.app.status) {
      case 'accepted':
        return _acceptColor;
      case 'rejected':
        return _rejectColor;
      case 'interview':
        return _interviewColor;
      default:
        return _pendingColor;
    }
  }

  String get _sl {
    switch (widget.app.status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'interview':
        return 'Interview Requested';
      default:
        return 'Pending Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final theme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _teal))
                  : SingleChildScrollView(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar + Name
                          Row(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF4F46E5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withOpacity(0.30),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    app.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      app.studentName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: theme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      app.studentEmail,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _sc.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _sl,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _sc,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Applied for banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.work_outline_rounded,
                                  size: 16,
                                  color: _teal,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Applied for: ${widget.jobTitle}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.teal.shade200
                                          : _tealDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // About
                          const _SecTitle(
                            'About',
                            Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 10),
                          _about.isEmpty
                              ? const _EmptyField(
                                  'No about information provided.',
                                )
                              : Text(
                                  _about,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.onSurfaceVariant,
                                    height: 1.6,
                                  ),
                                ),
                          const SizedBox(height: 24),

                          // Skills
                          const _SecTitle(
                            'Skills',
                            Icons.lightbulb_outline_rounded,
                          ),
                          const SizedBox(height: 10),
                          _skills.isEmpty
                              ? const _EmptyField('No skills listed.')
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _skills
                                      .map(
                                        (s) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF7C3AED,
                                            ).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF7C3AED,
                                            ).withOpacity(0.25),
                                            ),
                                          ),
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7C3AED),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                          const SizedBox(height: 24),

                          // Certificates
                          _SecTitle(
                            'Certificates (${_certs.length})',
                            Icons.verified_outlined,
                          ),
                          const SizedBox(height: 10),
                          _certs.isEmpty
                              ? const _EmptyField('No certificates uploaded.')
                              : Column(
                                  children: _certs
                                      .map(
                                        (c) => Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color:
                                                theme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: theme.outline,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF10B981,
                                                  ).withOpacity(0.10),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.verified_rounded,
                                                  size: 20,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c['title'] ??
                                                          'Certificate',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: theme.onSurface,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if ((c['description']
                                                                as String?)
                                                            ?.isNotEmpty ==
                                                        true)
                                                      Text(
                                                        c['description'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: theme
                                                              .onSurfaceVariant,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    if ((c['date'] as String?)
                                                            ?.isNotEmpty ==
                                                        true)
                                                      Text(
                                                        c['date'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: theme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              if ((c['image_url'] as String?)
                                                      ?.isNotEmpty ==
                                                  true)
                                                const Icon(
                                                  Icons.image_outlined,
                                                  size: 18,
                                                  color: _teal,
                                                ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),

                          // Action buttons if pending
                          if (widget.app.status == 'pending') ...[
                            const SizedBox(height: 20),
                            Divider(color: theme.outline),
                            const SizedBox(height: 16),
                            Text(
                              'Hiring Decision',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onReject?.call();
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: _rejectColor,
                                    ),
                                    label: const Text(
                                      'Reject',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _rejectColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: _rejectColor,
                                        width: 1.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onInterview?.call();
                                    },
                                    icon: const Icon(
                                      Icons.event_rounded,
                                      size: 14,
                                      color: _interviewColor,
                                    ),
                                    label: const Text(
                                      'Interview',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _interviewColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: _interviewColor,
                                        width: 1.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      widget.onAccept?.call();
                                    },
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Accept',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _acceptColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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

class _SecTitle extends StatelessWidget {
  final String t;
  final IconData i;
  const _SecTitle(this.t, this.i);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(i, size: 14, color: _teal),
        ),
        const SizedBox(width: 8),
        Text(
          t,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _EmptyField extends StatelessWidget {
  final String t;
  const _EmptyField(this.t);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.outline),
      ),
      child: Text(
        t,
        style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 — PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final CompanyProfile? company;
  final VoidCallback onLogout;
  const _ProfileTab({required this.company, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final c = company;
    final theme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_teal, _tealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  c?.initials ?? 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              c?.name ?? 'Company',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              c?.email ?? '',
              style: TextStyle(fontSize: 14, color: theme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _PRow(
                    Icons.category_outlined,
                    'Industry',
                    c?.industry ?? '—',
                  ),
                  Divider(height: 1, color: theme.outline),
                  _PRow(
                    Icons.location_on_outlined,
                    'Location',
                    c?.location ?? '—',
                  ),
                  Divider(height: 1, color: theme.outline),
                  _PRow(Icons.email_outlined, 'Email', c?.email ?? '—'),
                  if (c?.description != null && c!.description!.isNotEmpty) ...[
                    Divider(height: 1, color: theme.outline),
                    _PRow(Icons.description_outlined, 'About', c.description!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: _rejectColor,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: _rejectColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _rejectColor, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PRow extends StatelessWidget {
  final IconData i;
  final String l, v;
  const _PRow(this.i, this.l, this.v);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(i, size: 18, color: _teal),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              l,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int index, pending;
  final ValueChanged<int> onTap;
  const _BottomBar({
    required this.index,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NI(
                Icons.dashboard_outlined,
                'Dashboard',
                index == 0,
                () => onTap(0),
              ),
              _NI(
                Icons.post_add_rounded,
                'Post Job',
                index == 1,
                () => onTap(1),
              ),
              _NI(
                Icons.people_alt_outlined,
                'Applicants',
                index == 2,
                () => onTap(2),
                badge: pending,
              ),
              _NI(
                Icons.business_rounded,
                'Profile',
                index == 3,
                () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NI extends StatelessWidget {
  final IconData i;
  final String l;
  final bool a;
  final VoidCallback t;
  final int badge;

  const _NI(this.i, this.l, this.a, this.t, {this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: t,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // This is the active "pill" background
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // Forces teal background when active, regardless of global theme
                  color: a ? _teal.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  i,
                  // Forces teal icon when active
                  color: a ? _teal : theme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              if (badge > 0)
                Positioned(
                  right: 4,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _pendingColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l,
            style: TextStyle(
              fontSize: 10,
              color: a ? _teal : theme.onSurfaceVariant,
              fontWeight: a ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: _teal, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.onSurfaceVariant,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}