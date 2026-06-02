// ─────────────────────────────────────────────────────────────────────────────
// internships_page.dart
// Student-facing browse page for company-posted job/internship opportunities.
// Students can read details and apply. Applied count on ProfileScreen updates
// dynamically because ProfileScreen re-fetches when this page is popped.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/external_internship_service.dart';

// ─── COLORS (match User_profile.dart palette) ────────────────────────────────
const _blue      = Color(0xFF3B82F6);
const _white     = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
// INTERNSHIPS PAGE
// ─────────────────────────────────────────────────────────────────────────────
class InternshipsPage extends StatefulWidget {
  final int    userId;
  final String userName;
  final String userEmail;

  const InternshipsPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<InternshipsPage> createState() => _InternshipsPageState();
}

class _InternshipsPageState extends State<InternshipsPage> with TickerProviderStateMixin {
  final _db = Supabase.instance.client;
  late TabController _tabController;
  final _externalService = ExternalInternshipService();

  // University Internships
  bool _isLoading = true;
  List<Map<String, dynamic>> _allJobs      = [];
  List<Map<String, dynamic>> _filtered     = [];
  Set<int>                   _appliedIds   = {};
  
  // External Opportunities
  bool _loadingExternal = false;
  List<ExternalInternship> _externalJobs = [];
  List<ExternalInternship> _filteredExternal = [];
  
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _loadExternalJobs();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all job postings joined with company name
      final jobs = await _db
          .from('Job_postings')
          .select('*, Company_profile(name, industry, location)')
          .order('created_at', ascending: false);

      // Fetch which jobs this student has already applied to
      final applied = await _db
          .from('Job_applications')
          .select('job_id')
          .eq('student_id', widget.userId);

      if (mounted) {
        setState(() {
          _allJobs    = List<Map<String, dynamic>>.from(jobs as List);
          _filtered   = List.from(_allJobs);
          _appliedIds = {
            for (final a in (applied as List)) (a['job_id'] as int),
          };
          _isLoading  = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading jobs: $e')));
      }
    }
  }

  Future<void> _loadExternalJobs() async {
    setState(() => _loadingExternal = true);
    try {
      final jobs = await _externalService.searchInternships();
      if (mounted) {
        setState(() {
          _externalJobs = jobs;
          _filteredExternal = List.from(_externalJobs);
          _loadingExternal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingExternal = false);
        String errorMsg = 'Error loading external opportunities';
        if (e.toString().contains('API key')) {
          errorMsg = 'API key not configured';
        } else if (e.toString().contains('rate limit')) {
          errorMsg = 'Rate limit exceeded. Try again later.';
        } else if (e.toString().contains('timeout')) {
          errorMsg = 'Request timed out. Check your connection.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      // Filter university internships
      _filtered = q.isEmpty
          ? List.from(_allJobs)
          : _allJobs.where((j) {
              final title   = (j['title'] ?? '').toString().toLowerCase();
              final company = (j['Company_profile']?['name'] ?? '').toString().toLowerCase();
              final loc     = (j['location'] ?? '').toString().toLowerCase();
              return title.contains(q) || company.contains(q) || loc.contains(q);
            }).toList();

      // Filter external internships
      _filteredExternal = q.isEmpty
          ? List.from(_externalJobs)
          : _externalJobs.where((j) {
              final title   = j.title.toLowerCase();
              final company = j.company.toLowerCase();
              final loc     = j.location.toLowerCase();
              return title.contains(q) || company.contains(q) || loc.contains(q);
            }).toList();
    });
  }

  // ─── APPLY ───────────────────────────────────────────────────────────────

  Future<void> _applyToJob(Map<String, dynamic> job) async {
    final jobId = job['id'] as int;
    try {
      await _db.from('Job_applications').insert({
        'job_id':        jobId,
        'student_id':    widget.userId,
        'student_name':  widget.userName,
        'student_email': widget.userEmail,
        'status':        'pending',
      });
      setState(() => _appliedIds.add(jobId));
      if (mounted) {
        Navigator.pop(context); // close detail sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Applied to ${job['title']}!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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

  Future<void> _applyExternallyToJob(ExternalInternship job) async {
    try {
      if (job.applyUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apply URL not available')),
          );
        }
        return;
      }
      
      final uri = Uri.parse(job.applyUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          Navigator.pop(context); // close detail sheet
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open application link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadData(),
      _loadExternalJobs(),
    ]);
  }

  // ─── DETAIL SHEET ────────────────────────────────────────────────────────

  void _showDetail(Map<String, dynamic> job) {
    final theme      = Theme.of(context).colorScheme;
    final jobId      = job['id'] as int;
    final isApplied  = _appliedIds.contains(jobId);
    final company    = job['Company_profile']?['name'] ?? '—';
    final industry   = job['Company_profile']?['industry'] ?? '';
    final title      = job['title'] ?? '';
    final desc       = job['description'] ?? '';
    final req        = job['requirements'] ?? '';
    final loc        = job['location'] ?? '';
    final duration   = job['duration'] ?? '';
    final spots      = job['spots_available'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: theme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Company avatar + title ──
                      Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF60A5FA), _blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                company.isNotEmpty
                                    ? company[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                    color: _white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(company,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: theme.onSurface)),
                                if (industry.isNotEmpty)
                                  Text(industry,
                                      style: TextStyle(
                                          fontSize: 13, color: theme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Title ──
                      Text(title,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: theme.onSurface,
                              letterSpacing: -0.4)),

                      const SizedBox(height: 12),

                      // ── Tags ──
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _Tag(icon: Icons.location_on_outlined, label: loc),
                          _Tag(icon: Icons.schedule_outlined,    label: duration),
                          _Tag(icon: Icons.group_outlined,
                              label: '$spots spot${spots == 1 ? '' : 's'}'),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Description ──
                      _DetailSection(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        content: desc,
                      ),

                      const SizedBox(height: 16),

                      // ── Requirements ──
                      _DetailSection(
                        icon: Icons.checklist_rounded,
                        title: 'Requirements',
                        content: req,
                      ),

                      const SizedBox(height: 28),

                      // ── Apply button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: isApplied
                            ? Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFF10B981), width: 1.4),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF10B981), size: 20),
                                    SizedBox(width: 8),
                                    Text('Already Applied',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF10B981))),
                                  ],
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _applyToJob(job),
                                icon: const Icon(Icons.send_rounded,
                                    size: 18, color: _white),
                                label: const Text('Apply Now',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: _white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _blue,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
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
      ),
    );
  }

  void _showExternalDetail(ExternalInternship job) {
    final theme = Theme.of(context).colorScheme;
    final company = job.company;
    final title = job.title;
    final desc = job.description;
    final loc = job.location;
    final empType = job.employmentType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.45,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: theme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Company avatar + title ──
                      Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF60A5FA), _blue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                company.isNotEmpty
                                    ? company[0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(
                                    color: _white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(company,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: theme.onSurface)),
                                Text('External Opportunity',
                                    style: TextStyle(
                                        fontSize: 13, color: theme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Title ──
                      Text(title,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: theme.onSurface,
                              letterSpacing: -0.4)),

                      const SizedBox(height: 12),

                      // ── Tags ──
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _Tag(icon: Icons.location_on_outlined, label: loc),
                          _Tag(icon: Icons.work_outline_rounded, label: empType),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Description ──
                      _DetailSection(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        content: desc,
                      ),

                      const SizedBox(height: 28),

                      // ── Apply button ──
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () => _applyExternallyToJob(job),
                          icon: const Icon(Icons.open_in_new_rounded,
                              size: 18, color: _white),
                          label: const Text('Apply Externally',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

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
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                            Text('Internships',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: theme.onSurface,
                                    letterSpacing: -0.3)),
                            Text('Browse & apply to opportunities',
                                style: TextStyle(
                                    fontSize: 12, color: theme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      // Refresh
                      GestureDetector(
                        onTap: _refreshAll,
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
                          child: Icon(Icons.refresh_rounded,
                              color: theme.onSurfaceVariant, size: 20),
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
                        hintText: 'Search by title, company, location...',
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

                // ── TabBar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: _white,
                      unselectedLabelColor: theme.onSurfaceVariant,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.all(4),
                      dividerHeight: 0,
                      tabs: const [
                        Tab(text: 'University'),
                        Tab(text: 'External'),
                      ],
                    ),
                  ),
                ),

                // ── Tab content ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // University Internships Tab
                      Column(
                        children: [
                          // ── Count label ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Text(
                              _isLoading
                                  ? 'Loading...'
                                  : '${_filtered.length} opportunit${_filtered.length == 1 ? 'y' : 'ies'} found',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.onSurfaceVariant),
                            ),
                          ),
                          // ── List ──
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(color: _blue))
                                : _filtered.isEmpty
                                    ? _EmptyState(
                                        query: _searchCtrl.text.trim())
                                    : RefreshIndicator(
                                        color: _blue,
                                        onRefresh: _refreshAll,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 4, 20, 32),
                                          itemCount: _filtered.length,
                                          itemBuilder: (_, i) => _JobCard(
                                            job:       _filtered[i],
                                            isApplied: _appliedIds
                                                .contains(_filtered[i]['id'] as int),
                                            onTap:     () => _showDetail(_filtered[i]),
                                          ),
                                        ),
                                      ),
                          ),
                        ],
                      ),

                      // External Opportunities Tab
                      Column(
                        children: [
                          // ── Count label ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                            child: Text(
                              _loadingExternal
                                  ? 'Loading...'
                                  : '${_filteredExternal.length} opportunit${_filteredExternal.length == 1 ? 'y' : 'ies'} found',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.onSurfaceVariant),
                            ),
                          ),
                          // ── List ──
                          Expanded(
                            child: _loadingExternal
                                ? const Center(
                                    child: CircularProgressIndicator(color: _blue))
                                : _filteredExternal.isEmpty
                                    ? _EmptyState(
                                        query: _searchCtrl.text.trim(),
                                        isExternal: true)
                                    : RefreshIndicator(
                                        color: _blue,
                                        onRefresh: _refreshAll,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 4, 20, 32),
                                          itemCount: _filteredExternal.length,
                                          itemBuilder: (_, i) => _ExternalJobCard(
                                            job: _filteredExternal[i],
                                            onTap: () => _showExternalDetail(_filteredExternal[i]),
                                          ),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB CARD
// ─────────────────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isApplied;
  final VoidCallback onTap;
  const _JobCard(
      {required this.job,
      required this.isApplied,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context).colorScheme;
    final company  = job['Company_profile']?['name'] ?? '—';
    final title    = job['title'] ?? '';
    final loc      = job['location'] ?? '';
    final duration = job['duration'] ?? '';
    final initial  = company.isNotEmpty ? company[0].toUpperCase() : 'C';

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
                color: _blue.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), _blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        color: _white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ),

            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(company,
                      style: TextStyle(
                          fontSize: 13, color: theme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _MiniTag(Icons.location_on_outlined, loc),
                      const SizedBox(width: 6),
                      _MiniTag(Icons.schedule_outlined, duration),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Applied badge ──
            if (isApplied)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF10B981), width: 1.0),
                ),
                child: const Text('Applied',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981))),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: theme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXTERNAL JOB CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ExternalJobCard extends StatelessWidget {
  final ExternalInternship job;
  final VoidCallback onTap;
  const _ExternalJobCard({
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final company = job.company;
    final title = job.title;
    final loc = job.location;
    final empType = job.employmentType;
    final initial = company.isNotEmpty ? company[0].toUpperCase() : 'E';

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
                color: _blue.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), _blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        color: _white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ),

            const SizedBox(width: 14),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(company,
                      style: TextStyle(
                          fontSize: 13, color: theme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _MiniTag(Icons.location_on_outlined, loc),
                      const SizedBox(width: 6),
                      _MiniTag(Icons.work_outline_rounded, empType),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ── Chevron ──
            Icon(Icons.chevron_right_rounded,
                color: theme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MiniTag(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: theme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _blue.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _blue),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: _blue,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   content;
  const _DetailSection(
      {required this.icon,
      required this.title,
      required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: _blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 15, color: _blue),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.onSurface)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.outline),
          ),
          child: Text(
            content.isNotEmpty ? content : '—',
            style: TextStyle(
                fontSize: 13.5, color: theme.onSurfaceVariant, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final bool isExternal;
  const _EmptyState({required this.query, this.isExternal = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: _blue.withOpacity(0.10),
                borderRadius: BorderRadius.circular(22)),
            child: const Icon(Icons.work_off_outlined,
                color: _blue, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            query.isEmpty
                ? (isExternal
                    ? 'No external internships found.'
                    : 'No internships posted yet.')
                : 'No results for "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                color: theme.onSurfaceVariant,
                height: 1.6,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  const _Blob({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}