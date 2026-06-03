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
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_provider.dart';
import 'company_model.dart';
import 'company_session.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

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
  final Set<int> _seenApplications = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await _loadSeenApplications();
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

  Future<void> _loadSeenApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'company_${widget.companyId}_seen_notifications';
    final saved = prefs.getStringList(key);
    if (saved != null) {
      _seenApplications
        ..clear()
        ..addAll(saved.map(int.tryParse).whereType<int>());
    }
  }

  Future<void> _saveSeenApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'company_${widget.companyId}_seen_notifications';
    await prefs.setStringList(
      key,
      _seenApplications.map((id) => id.toString()).toList(),
    );
  }

  int _newApplicationsForJob(JobPosting job) => _applications
      .where((a) =>
          a.jobId == job.id &&
          a.status == 'pending' &&
          a.id != null &&
          !_seenApplications.contains(a.id))
      .length;

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

  int get _notificationCount => _applications
      .where((a) => a.status == 'pending' && a.id != null && !_seenApplications.contains(a.id))
      .length;

  Future<void> _markAllNotificationsSeen() async {
    setState(() {
      for (final app in _applications) {
        if (app.id != null) _seenApplications.add(app.id!);
      }
    });
    await _saveSeenApplications();
  }

  Future<void> _markAsSeen(JobApplication app) async {
    if (app.id == null) return;
    if (_seenApplications.contains(app.id)) return;
    setState(() => _seenApplications.add(app.id!));
    await _saveSeenApplications();
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
        notificationCount: _notificationCount,
        onNotificationsOpened: _markAllNotificationsSeen,
        newCountForJob: _newApplicationsForJob,
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
        onView: _markAsSeen,
      ),
      _ProfileTab(
        company: _company,
        jobs: _jobs,
        applications: _applications,
        onLogout: () => Navigator.of(context).pop(),
        onRefresh: _loadData,
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
  final int notificationCount;
  final VoidCallback onNotificationsOpened;
  final int Function(JobPosting) newCountForJob;
  final VoidCallback onRefresh;
  final Future<void> Function(JobApplication, String) onUpdateStatus;
  final Future<void> Function(JobApplication) onRemove;

  const _DashboardTab({
    required this.company,
    required this.jobs,
    required this.applications,
    required this.greeting,
    required this.pendingCount,
    required this.notificationCount,
    required this.onNotificationsOpened,
    required this.newCountForJob,
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
              _DashHeader(
                company: company,
                greeting: greeting,
                notificationCount: notificationCount,
                onNotificationsOpened: onNotificationsOpened,
              ),
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
                    newCount: newCountForJob(j),
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
  final int notificationCount;
  final VoidCallback onNotificationsOpened;
  const _DashHeader({
    required this.company,
    required this.greeting,
    required this.notificationCount,
    required this.onNotificationsOpened,
  });

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

        // Notification Icon (opens a popup showing recent student applications)
        Builder(
          builder: (iconCtx) => InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              if (company == null) return;

              // compute anchor position
              final renderBox = iconCtx.findRenderObject() as RenderBox?;
              final overlay = Overlay.of(iconCtx).context.findRenderObject() as RenderBox?;
              Rect rect = Rect.fromLTWH(0, 0, 40, 40);
              if (renderBox != null && overlay != null) {
                final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
                rect = offset & renderBox.size;
              }

              final items = await Supabase.instance.client
                  .from('Job_applications')
                  .select('id, student_name, applied_at, Job_postings!inner(title, company_id)')
                  .eq('Job_postings.company_id', company!.id)
                  .order('applied_at', ascending: false)
                  .then((v) => List<Map<String, dynamic>>.from(v as List));

              final menuWidth = MediaQuery.of(context).size.width * 0.85;
              final maxHeight = MediaQuery.of(context).size.height * 0.6;

              String formatTimeAgo(String? ts) {
                if (ts == null) return 'Just now';
                try {
                  final dt = DateTime.parse(ts).toLocal();
                  final diff = DateTime.now().difference(dt);
                  if (diff.inSeconds < 60) return 'Just now';
                  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
                  if (diff.inHours < 24) return '${diff.inHours}h ago';
                  if (diff.inDays < 7) return '${diff.inDays}d ago';
                  return '${dt.day}/${dt.month}/${dt.year}';
                } catch (_) {
                  return 'Just now';
                }
              }

              final double itemH = 76.0;
              final double contentHeight = ((items.length * itemH + 64).clamp(120.0, maxHeight)).toDouble();

              await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(rect.left, rect.bottom, rect.right, rect.top),
                color: theme.surface,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                items: [
                  PopupMenuItem(
                    enabled: false,
                    child: SizedBox(
                      width: menuWidth,
                      height: contentHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, top: 8.0),
                            child: Text('Recent Applications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.onSurface)),
                          ),
                          Expanded(
                            child: items.isEmpty
                                ? Center(child: Text('No recent applications', style: TextStyle(color: theme.onSurfaceVariant)))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: items.length,
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final it = items[i];
                                      final student = (it['student_name'] ?? 'Student').toString();
                                      String jobTitle = '';
                                      try {
                                        final jp = it['Job_postings'];
                                        if (jp is Map && jp['title'] != null) jobTitle = jp['title']?.toString() ?? '';
                                      } catch (_) {}
                                      final appliedAt = it['applied_at']?.toString();

                                      final initials = student.trim().isEmpty
                                          ? 'S'
                                          : student
                                              .trim()
                                              .split(' ')
                                              .where((e) => e.isNotEmpty)
                                              .take(2)
                                              .map((e) => e[0].toUpperCase())
                                              .join();

                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: theme.primary.withOpacity(0.12),
                                              child: Text(initials, style: TextStyle(color: theme.primary, fontWeight: FontWeight.w800)),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(student, style: TextStyle(fontWeight: FontWeight.w800, color: theme.onSurface)),
                                                  const SizedBox(height: 4),
                                                  Text('Applied on: ${jobTitle}', style: TextStyle(color: theme.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(formatTimeAgo(appliedAt), style: TextStyle(color: theme.onSurfaceVariant, fontSize: 12)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
              onNotificationsOpened();
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                  child: Icon(Icons.notifications_none_rounded, color: theme.onSurfaceVariant, size: 20),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 58, 11),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.surface, width: 1.5),
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
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
  final int newCount;
  final VoidCallback onTap;
  const _JobCard({
    required this.job,
    required this.applications,
    required this.newCount,
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
      final text = ctrl.text.trim();
      try {
        // build unique list of student ids to message
        final ids = _apps.map((a) => a.studentId).where((id) => id != null).toSet().toList();
        if (ids.isNotEmpty) {
          final payloads = ids
              .map((sid) => {
                    'company_id': widget.job.companyId,
                    'student_id': sid,
                    'job_id': widget.job.id,
                    'message': text,
                    'is_read': false,
                  })
              .toList();

          await Supabase.instance.client.from('direct_messages').insert(payloads);
        }
      } catch (e) {
        // ignore or log
      }
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

  // ── Send a private message to one specific student ──────────────────────────
  Future<void> _messageSingle(JobApplication app) async {
    final theme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  app.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
                    'Message ${app.studentName}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: theme.onSurface,
                    ),
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
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              maxLines: 4,
              autofocus: true,
              style: TextStyle(color: theme.onSurface),
              decoration: InputDecoration(
                hintText: 'Write your message to ${app.studentName}...',
                hintStyle: TextStyle(
                  color: theme.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: theme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.outline),
                ),
                enabledBorder: OutlineInputBorder(
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
            child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send_rounded, size: 14),
            label: const Text('Send', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (ok == true && ctrl.text.trim().isNotEmpty) {
      try {
        await Supabase.instance.client.from('direct_messages').insert({
          'company_id': widget.job.companyId,
          'student_id': app.studentId,
          'job_id': widget.job.id,
          'message': ctrl.text.trim(),
          'is_read': false,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✉️ Message sent to ${app.studentName}!'),
              backgroundColor: _teal,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
              backgroundColor: _rejectColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
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
                          onMessage: () => _messageSingle(app),
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
  final VoidCallback? onMessage;
  const _MgmtRow({
    required this.app,
    this.onInterview,
    required this.onRemove,
    this.onMessage,
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
                      'Interview',
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
              if (onInterview != null) const SizedBox(width: 6),
              // ── Message button ──────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: onMessage,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 13,
                  color: _teal,
                ),
                label: const Text(
                  'Message',
                  style: TextStyle(
                    fontSize: 11,
                    color: _teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _teal, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // ── Remove button ───────────────────────────────────────────
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
  final void Function(JobApplication) onView;
  const _ApplicantsTab({
    required this.applications,
    required this.titleFor,
    required this.onUpdateStatus,
    required this.onView,
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
                        onViewed: () => widget.onView(app),
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
  final VoidCallback? onViewed;
  final VoidCallback? onAccept, onReject, onInterview;
  const _AppCard({
    required this.app,
    required this.jobTitle,
    this.onViewed,
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
      onTap: () {
        onViewed?.call();
        showModalBottomSheet(
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
        );
      },
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
  String _cvUrl = '';

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
          _cvUrl = (info?['cv_url'] ?? '') as String;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Uint8List? _decodeCertificateImageValue(String? value) {
    if (value == null || value.isEmpty || !value.startsWith('data:')) return null;
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1 || commaIndex >= value.length - 1) return null;
    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  void _showCertificate(Map<String, dynamic> item) {
    final imageUrl = (item['image_url'] ?? '').toString();
    if (imageUrl.isEmpty) return;
    final imageBytes = _decodeCertificateImageValue(imageUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: theme.surfaceContainerHighest,
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (item['title'] ?? 'Certificate').toString(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.onSurface),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: theme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageBytes != null
                      ? Image.memory(imageBytes, fit: BoxFit.contain)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, _, __) => Container(
                            height: 220,
                            color: _teal.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: _teal, size: 36),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _viewCv() async {
    if (_cvUrl.isEmpty) return;
    try {
      final uri = Uri.parse(_cvUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open CV')),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open CV: $e')));
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

                          // CV / Resume
                          _SecTitle('CV / Resume', Icons.picture_as_pdf_rounded),
                          const SizedBox(height: 10),
                          _cvUrl.isEmpty
                              ? const _EmptyField('No CV uploaded.')
                              : Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.outline),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _teal.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.picture_as_pdf_rounded, color: _teal, size: 28),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('CV / Resume', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.onSurface)),
                                        const SizedBox(height: 2),
                                        Text('PDF, DOC, or DOCX', style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
                                      ]),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _viewCv,
                                      icon: const Icon(Icons.visibility_rounded, size: 18),
                                      label: const Text('View CV'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _teal,
                                        side: BorderSide(color: _teal),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ]),
                                ),

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
                                      .map((c) {
                                        final hasImage = (c['image_url'] as String?)?.isNotEmpty == true;
                                        final card = Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: theme.surfaceContainerHighest,
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
                                              if (hasImage)
                                                const Icon(
                                                  Icons.image_outlined,
                                                  size: 18,
                                                  color: _teal,
                                                ),
                                            ],
                                          ),
                                        );

                                        return hasImage
                                            ? InkWell(
                                                borderRadius: BorderRadius.circular(14),
                                                onTap: () => _showCertificate(c),
                                                child: card,
                                              )
                                            : card;
                                      }).toList(),
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
class _ProfileTab extends StatefulWidget {
  final CompanyProfile? company;
  final List<JobPosting> jobs;
  final List<JobApplication> applications;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  const _ProfileTab({
    required this.company,
    required this.jobs,
    required this.applications,
    required this.onLogout,
    required this.onRefresh,
  });
  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  // ── Edit Profile ───────────────────────────────────────────────────────────
  Future<void> _editProfile() async {
    final c = widget.company;
    if (c == null) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(company: c),
    );

    if (saved == true && mounted) {
      widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated!', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Delete a job posting ───────────────────────────────────────────────────
  Future<void> _deleteJob(JobPosting job) async {
    final theme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Job Posting', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "${job.title}"? This will also remove all its applications.',
          style: TextStyle(color: theme.onSurfaceVariant, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _rejectColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('Job_applications')
            .delete()
            .eq('job_id', job.id!);
        await Supabase.instance.client
            .from('Job_postings')
            .delete()
            .eq('id', job.id!);
        if (mounted) {
          widget.onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${job.title}" deleted.'),
            backgroundColor: _rejectColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final theme = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: theme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: TextStyle(color: theme.onSurface),
            decoration: InputDecoration(
              hintText: 'New password',
              hintStyle: TextStyle(color: theme.onSurfaceVariant.withOpacity(0.6)),
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
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: theme.onSurfaceVariant),
                onPressed: () => setSt(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().length < 6) return;
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: ctrl.text.trim()),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Password updated!', style: TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: _acceptColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                } catch (e) {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    final theme = Theme.of(context).colorScheme;
    final apps = widget.applications;
    final jobs = widget.jobs;

    final totalApps = apps.length;
    final accepted = apps.where((a) => a.status == 'accepted').length;
    final pending = apps.where((a) => a.status == 'pending').length;
    final interviews = apps.where((a) => a.status == 'interview').length;

    return SafeArea(
      child: RefreshIndicator(
        color: _teal,
        onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: _editProfile,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded, color: _teal, size: 18),
                    ),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),
              // ── Avatar + name ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_teal, _tealDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _teal.withOpacity(0.40),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              c?.initials ?? 'C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _editProfile,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _teal,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.surface, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      c?.name ?? 'Company',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: theme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          c?.location ?? 'Location not set',
                          style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 3, height: 3, decoration: BoxDecoration(color: theme.onSurfaceVariant, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          c?.industry ?? 'Industry not set',
                          style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Hiring Stats Bar ──────────────────────────────────────────
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, _tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _teal.withOpacity(0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniStat('${jobs.length}', 'Jobs Posted'),
                    _Divider(),
                    _MiniStat('$totalApps', 'Total Applicants'),
                    _Divider(),
                    _MiniStat('$accepted', 'Hired'),
                    _Divider(),
                    _MiniStat('$interviews', 'Interviews'),
                  ],
                ),
              ),

              // ── Company Info ──────────────────────────────────────────────
              const SizedBox(height: 24),
              _SectionHeader('Company Info', Icons.business_rounded),
              const SizedBox(height: 12),
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
                    _PRow(Icons.category_outlined, 'Industry', c?.industry ?? '—'),
                    Divider(height: 1, color: theme.outline),
                    _PRow(Icons.location_on_outlined, 'Location', c?.location ?? '—'),
                    Divider(height: 1, color: theme.outline),
                    _PRow(Icons.email_outlined, 'Email', c?.email ?? '—'),
                    if (c?.description != null && c!.description!.isNotEmpty) ...[
                      Divider(height: 1, color: theme.outline),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.description_outlined, size: 18, color: _teal),
                                const SizedBox(width: 12),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c.description!,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.onSurface,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Application Breakdown ─────────────────────────────────────
              if (totalApps > 0) ...[
                const SizedBox(height: 24),
                _SectionHeader('Application Breakdown', Icons.bar_chart_rounded),
                const SizedBox(height: 12),
                Container(
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
                    children: [
                      _BarRow('Pending', pending, totalApps, _pendingColor),
                      const SizedBox(height: 10),
                      _BarRow('Accepted', accepted, totalApps, _acceptColor),
                      const SizedBox(height: 10),
                      _BarRow('Interview', interviews, totalApps, _interviewColor),
                      const SizedBox(height: 10),
                      _BarRow(
                        'Rejected',
                        apps.where((a) => a.status == 'rejected').length,
                        totalApps,
                        _rejectColor,
                      ),
                    ],
                  ),
                ),
              ],

              // ── Active Job Postings ───────────────────────────────────────
              if (jobs.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionHeader('Your Job Postings', Icons.work_outline_rounded),
                const SizedBox(height: 12),
                ...jobs.map((job) {
                  final jobApps = apps.where((a) => a.jobId == job.id).length;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.work_outline_rounded, color: _teal, size: 20),
                        ),
                        const SizedBox(width: 12),
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
                              const SizedBox(height: 2),
                              Text(
                                '${job.location ?? 'Remote'} · ${job.duration ?? '—'}',
                                style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$jobApps applicants',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _deleteJob(job),
                              child: const Icon(Icons.delete_outline_rounded, color: _rejectColor, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // ── Quick Actions ─────────────────────────────────────────────
              // ── Account Section ─────────────────────────────────────────────
const SizedBox(height: 24),
_SectionHeader('Account', Icons.manage_accounts_rounded),
const SizedBox(height: 12),

Container(
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
      _ActionRow(
        icon: Icons.edit_rounded,
        color: _teal,
        label: 'Edit Profile',
        subtitle: 'Update your company details',
        onTap: _editProfile,
      ),
    ],
  ),
),

              // ── Logout ────────────────────────────────────────────────────
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18, color: _rejectColor),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: _rejectColor, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _rejectColor, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Tab Helpers ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: _teal),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: theme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  const _MiniStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 32,
    color: Colors.white.withOpacity(0.25),
  );
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _BarRow(this.label, this.count, this.total, this.color);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.onSurfaceVariant)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: theme.outline.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, subtitle;
  final VoidCallback onTap;
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.onSurface)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE SHEET  (owns its own controllers so disposal is safe)
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final CompanyProfile company;
  const _EditProfileSheet({required this.company});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _industryCtrl;
  late final TextEditingController _locationCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: widget.company.name);
    _industryCtrl = TextEditingController(text: widget.company.industry ?? '');
    _locationCtrl = TextEditingController(text: widget.company.location ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Company Profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: theme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _EditField(ctrl: _nameCtrl,     label: 'Company Name', icon: Icons.business_rounded),
              const SizedBox(height: 12),
              _EditField(ctrl: _industryCtrl, label: 'Industry',     icon: Icons.category_outlined),
              const SizedBox(height: 12),
              _EditField(ctrl: _locationCtrl, label: 'Location',     icon: Icons.location_on_outlined),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await Supabase.instance.client
                              .from('Company_profile')
                              .update({
                                'name':     _nameCtrl.text.trim(),
                                'industry': _industryCtrl.text.trim(),
                                'location': _locationCtrl.text.trim(),
                              })
                              .eq('id', widget.company.id);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save: $e'),
                                backgroundColor: _rejectColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  const _EditField({required this.ctrl, required this.label, required this.icon, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: theme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.onSurfaceVariant, fontSize: 13),
        prefixIcon: Icon(icon, color: _teal, size: 18),
        filled: true,
        fillColor: theme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _teal, width: 1.8),
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
