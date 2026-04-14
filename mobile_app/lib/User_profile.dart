import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'home.dart';

// ─── COLORS ────────────────────────────
const _blue      = Color(0xFF3B82F6);
const _blueLight = Color(0xFFEFF6FF);
const _bluePale  = Color(0xFFF0F7FF);
const _textDark  = Color(0xFF1E293B);
const _textGrey  = Color(0xFF64748B);
const _border    = Color(0xFFE2E8F0);
const _white     = Colors.white;

// ─── HELPERS ────────────────────────────
String _formatFullDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final parts = raw.split('-');
    final year  = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day   = parts.length >= 3 ? int.parse(parts[2]) : null;
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    if (day != null) {
      return '${day.toString().padLeft(2,'0')} ${months[month - 1]} $year';
    }
    return '${months[month - 1]} $year';
  } catch (_) {
    return raw;
  }
}

// ─── FULL DATE PICKER (day + month + year) ──
// Only allows selection up to and including yesterday.
Future<String?> pickFullDate(
    BuildContext context, {String? initial}) async {
  final today     = DateTime.now();
  final yesterday = DateTime(today.year, today.month, today.day - 1);

  DateTime sel = yesterday;

  if (initial != null && initial.isNotEmpty) {
    try {
      final parts = initial.split('-');
      sel = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length >= 3 ? int.parse(parts[2]) : 1,
      );
    } catch (_) {}
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, ss) {
        final daysInMonth =
            DateUtils.getDaysInMonth(sel.year, sel.month);

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── year row ──
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: _blue),
                        onPressed: () => ss(() {
                          sel = DateTime(
                            sel.year - 1,
                            sel.month,
                            sel.day.clamp(
                                1,
                                DateUtils.getDaysInMonth(
                                    sel.year - 1, sel.month)),
                          );
                        }),
                      ),
                      Text('${sel.year}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _textDark)),
                      IconButton(
                        icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: _blue),
                        onPressed: () {
                          final nextYear = sel.year + 1;
                          final tentative = DateTime(
                              nextYear,
                              sel.month,
                              sel.day.clamp(
                                  1,
                                  DateUtils.getDaysInMonth(
                                      nextYear, sel.month)));
                          if (!tentative.isAfter(yesterday)) {
                            ss(() => sel = tentative);
                          }
                        },
                      ),
                    ],
                  ),

                  // ── month grid ──
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      const months = [
                        'Jan','Feb','Mar','Apr','May','Jun',
                        'Jul','Aug','Sep','Oct','Nov','Dec'
                      ];
                      final firstOfMonth =
                          DateTime(sel.year, i + 1, 1);
                      final isSelected = sel.month == i + 1;
                      final isFuture = firstOfMonth.isAfter(
                          DateTime(yesterday.year,
                              yesterday.month, 1));
                      return GestureDetector(
                        onTap: isFuture
                            ? null
                            : () => ss(() {
                                  final newDay = sel.day.clamp(
                                      1,
                                      DateUtils.getDaysInMonth(
                                          sel.year, i + 1));
                                  sel = DateTime(
                                      sel.year, i + 1, newDay);
                                }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _blue
                                : isFuture
                                    ? _border
                                    : _blueLight,
                            borderRadius:
                                BorderRadius.circular(8),
                          ),
                          child: Text(months[i],
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? _white
                                      : isFuture
                                          ? _textGrey
                                              .withOpacity(0.4)
                                          : _blue)),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── day label ──
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Day',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textDark)),
                  ),
                  const SizedBox(height: 8),

                  // ── day grid ──
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (_, i) {
                      final day     = i + 1;
                      final thisDay = DateTime(
                          sel.year, sel.month, day);
                      final isSelected = sel.day == day;
                      final isFuture =
                          thisDay.isAfter(yesterday);
                      return GestureDetector(
                        onTap: isFuture
                            ? null
                            : () => ss(() => sel = DateTime(
                                sel.year, sel.month, day)),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _blue
                                : isFuture
                                    ? Colors.transparent
                                    : _blueLight,
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: Text('$day',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w600,
                                  color: isSelected
                                      ? _white
                                      : isFuture
                                          ? _textGrey
                                              .withOpacity(0.3)
                                          : _blue)),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, null),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: _textGrey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final result =
                              '${sel.year}-${sel.month.toString().padLeft(2, '0')}-${sel.day.toString().padLeft(2, '0')}';
                          Navigator.pop(ctx, result);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

// ─── PROFILE SCREEN ────────────────────
class ProfileScreen extends StatefulWidget {
  final int id;
  const ProfileScreen({super.key, required this.id});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = Supabase.instance.client;

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _info;
  List<Map<String, dynamic>> _certs       = [];
  List<Map<String, dynamic>> _internships = [];
  bool _isLoading = true;

  // controls whether the ✕ icons appear on skills
  bool _skillsDeleteMode = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final user = await _db
          .from('User_profile')
          .select()
          .eq('id', widget.id)
          .single();

      final infoList = await _db
          .from('Profile_info')
          .select()
          .eq('user_id', widget.id);

      final certs = await _db
          .from('Certificates')
          .select()
          .eq('user_id', widget.id)
          .order('id', ascending: false);

      final internships = await _db
          .from('Internships')
          .select()
          .eq('user_id', widget.id)
          .order('id', ascending: false);

      setState(() {
        _user        = user;
        _info        = infoList.isNotEmpty ? infoList.first : null;
        _certs       = List<Map<String, dynamic>>.from(certs);
        _internships =
            List<Map<String, dynamic>>.from(internships);
        _isLoading   = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getInitials(String name) {
    return name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();
  }

  // ── confirm save ──
  Future<bool> _confirmSave() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Save Changes',
                style:
                    TextStyle(fontWeight: FontWeight.w700)),
            content:
                const Text('Are you sure you want to save?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, false),
                child: const Text('No',
                    style: TextStyle(color: _textGrey)),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8)),
                ),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── confirm delete ──
  Future<bool> _confirmDelete(String itemName) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete',
                style:
                    TextStyle(fontWeight: FontWeight.w700)),
            content: Text(
                'Are you sure you want to delete "$itemName"?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: _textGrey)),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8)),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ── edit About ──
  void _editAbout() {
    final ctrl =
        TextEditingController(text: _info?['about'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit About',
            style:
                TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration:
              _inputDec('Tell us about yourself...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _confirmSave();
              if (!ok) return;
              try {
                if (_info == null) {
                  await _db.from('Profile_info').insert({
                    'user_id': widget.id,
                    'about':   ctrl.text.trim(),
                    'skills':  '',
                  });
                } else {
                  await _db
                      .from('Profile_info')
                      .update({'about': ctrl.text.trim()})
                      .eq('user_id', widget.id);
                }
                _fetchAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── skills 3-dot popup menu ──
  void _showSkillsMenu(BuildContext anchorCtx) async {
    final skills = _parseSkills(_info?['skills']);
    final RenderBox button =
        anchorCtx.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(anchorCtx)
        .overlay!
        .context
        .findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero,
            ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: anchorCtx,
      position: position,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'add',
          child: Row(children: const [
            Icon(Icons.add_circle_outline_rounded,
                size: 18, color: _blue),
            SizedBox(width: 10),
            Text('Add Skill',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark)),
          ]),
        ),
        if (skills.isNotEmpty)
          PopupMenuItem(
            value: 'delete',
            child: Row(children: const [
              Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Skill',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red)),
            ]),
          ),
      ],
    );

    if (choice == 'add') {
      _addSkillDialog();
    } else if (choice == 'delete') {
      setState(() => _skillsDeleteMode = true);
    }
  }

  // ── add skill dialog ──
  void _addSkillDialog() {
    final existingRaw = _info?['skills'] ?? '';
    final existing = existingRaw
        .toString()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (existing.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Maximum 10 skills reached. Delete one to add more.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Add Skill (${existing.length}/10)',
            style: const TextStyle(
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          decoration:
              _inputDec('e.g. Flutter, Python...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: _textGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSkill = ctrl.text.trim();
              if (newSkill.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await _confirmSave();
              if (!ok) return;
              try {
                final updated =
                    [...existing, newSkill].join(',');
                if (_info == null) {
                  await _db.from('Profile_info').insert({
                    'user_id': widget.id,
                    'about':   '',
                    'skills':  updated,
                  });
                } else {
                  await _db
                      .from('Profile_info')
                      .update({'skills': updated})
                      .eq('user_id', widget.id);
                }
                _fetchAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── delete one skill ──
  Future<void> _deleteSkill(String skill) async {
    final existingRaw = _info?['skills'] ?? '';
    final existing = existingRaw
        .toString()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    existing.remove(skill);
    final updated = existing.join(',');
    try {
      await _db
          .from('Profile_info')
          .update({'skills': updated})
          .eq('user_id', widget.id);
      await _fetchAll();
      if (existing.isEmpty) {
        setState(() => _skillsDeleteMode = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── add / edit Internship ──
  void _editInternship([Map<String, dynamic>? existing]) {
    final deptCtrl = TextEditingController(
        text: existing?['department'] ?? '');
    final compCtrl = TextEditingController(
        text: existing?['company'] ?? '');
    final descCtrl = TextEditingController(
        text: existing?['description'] ?? '');
    String startVal = existing?['start_date'] ?? '';
    String endVal   = existing?['end_date'] ?? '';
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
              existing == null
                  ? 'Add Internship'
                  : 'Edit Internship',
              style: const TextStyle(
                  fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _dialogLabel('Department'),
                const SizedBox(height: 6),
                TextField(
                    controller: deptCtrl,
                    decoration: _inputDec(
                        'e.g. Software Engineering')),
                const SizedBox(height: 12),
                _dialogLabel('Company'),
                const SizedBox(height: 6),
                TextField(
                    controller: compCtrl,
                    decoration:
                        _inputDec('e.g. Google')),
                const SizedBox(height: 12),
                _dialogLabel('Description'),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: _inputDec(
                      'What did you do there?'),
                ),
                const SizedBox(height: 12),

                // ── Start date ──
                _dialogLabel('Start Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await pickFullDate(
                        context,
                        initial: startVal);
                    if (picked != null)
                      ss(() => startVal = picked);
                  },
                  child: _datePicker(
                      startVal, 'Pick start date'),
                ),
                const SizedBox(height: 12),

                // ── End date ──
                _dialogLabel('End Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await pickFullDate(
                        context,
                        initial: endVal);
                    if (picked != null)
                      ss(() => endVal = picked);
                  },
                  child: _datePicker(
                      endVal, 'Pick end date'),
                ),

                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!,
                      style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: _textGrey)),
            ),
            ElevatedButton(
              onPressed: () async {
                // ── field validation ──
                if (deptCtrl.text.trim().isEmpty ||
                    compCtrl.text.trim().isEmpty) {
                  ss(() => errorMsg =
                      'Please fill in department and company.');
                  return;
                }
                if (startVal.isEmpty ||
                    endVal.isEmpty) {
                  ss(() => errorMsg =
                      'Please pick both dates.');
                  return;
                }

                final start = DateTime.parse(startVal);
                final end   = DateTime.parse(endVal);
                final today = DateTime.now();
                final yesterday = DateTime(
                    today.year,
                    today.month,
                    today.day - 1);

                // start ≤ yesterday
                if (start.isAfter(yesterday)) {
                  ss(() => errorMsg =
                      'Start date must be at most yesterday (${_formatFullDate('${yesterday.year}-${yesterday.month.toString().padLeft(2,'0')}-${yesterday.day.toString().padLeft(2,'0')}')}).');
                  return;
                }

                // end ≤ yesterday
                if (end.isAfter(yesterday)) {
                  ss(() => errorMsg =
                      'End date must be at most yesterday.');
                  return;
                }

                // end > start
                if (!end.isAfter(start)) {
                  ss(() => errorMsg =
                      'End date must be after start date.');
                  return;
                }

                // end ≥ start + 1 month (same day, one month later)
                // e.g. start = 13 Mar 2026  →  minEnd = 13 Apr 2026
                final minEnd = DateTime(
                    start.year,
                    start.month + 1,
                    start.day);
                if (end.isBefore(minEnd)) {
                  ss(() => errorMsg =
                      'Duration must be at least 1 month (end ≥ ${_formatFullDate('${minEnd.year}-${minEnd.month.toString().padLeft(2,'0')}-${minEnd.day.toString().padLeft(2,'0')}')}).');
                  return;
                }

                Navigator.pop(ctx);
                final ok = await _confirmSave();
                if (!ok) return;

                try {
                  final payload = {
                    'user_id':     widget.id,
                    'department':  deptCtrl.text.trim(),
                    'company':     compCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'start_date':  startVal,
                    'end_date':    endVal,
                  };
                  if (existing == null) {
                    await _db
                        .from('Internships')
                        .insert(payload);
                  } else {
                    await _db
                        .from('Internships')
                        .update(payload)
                        .eq('id', existing['id']);
                  }
                  _fetchAll();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(
                            content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── delete internship ──
  Future<void> _deleteInternship(
      Map<String, dynamic> item) async {
    final ok = await _confirmDelete(
        item['company'] ?? 'this internship');
    if (!ok) return;
    try {
      await _db
          .from('Internships')
          .delete()
          .eq('id', item['id']);
      _fetchAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── add certificate ──
  void _addCertificate() {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    String dateVal  = '';
    File? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Certificate',
              style: TextStyle(
                  fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _dialogLabel('Title'),
                const SizedBox(height: 6),
                TextField(
                    controller: titleCtrl,
                    decoration: _inputDec(
                        'e.g. Flutter Bootcamp')),
                const SizedBox(height: 12),
                _dialogLabel('Description'),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration:
                      _inputDec('Short description...'),
                ),
                const SizedBox(height: 12),

                _dialogLabel('Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final picked = await pickFullDate(
                        context,
                        initial: dateVal);
                    if (picked != null)
                      ss(() => dateVal = picked);
                  },
                  child: _datePicker(dateVal, 'Pick date'),
                ),
                const SizedBox(height: 16),

                _dialogLabel('Certificate Image'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked =
                        await picker.pickImage(
                            source:
                                ImageSource.gallery,
                            imageQuality: 80);
                    if (picked != null) {
                      ss(() => pickedImage =
                          File(picked.path));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: pickedImage != null
                        ? 150
                        : 80,
                    decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              _blue.withOpacity(0.3),
                          width: 1),
                    ),
                    child: pickedImage != null
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                                    12),
                            child: Image.file(
                                pickedImage!,
                                fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                  Icons
                                      .upload_file_rounded,
                                  color: _blue,
                                  size: 28),
                              SizedBox(height: 6),
                              Text(
                                  'Tap to pick image',
                                  style: TextStyle(
                                      color: _blue,
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight
                                              .w600)),
                            ],
                          ),
                  ),
                ),

                if (isUploading) ...[
                  const SizedBox(height: 12),
                  const Center(
                      child:
                          CircularProgressIndicator(
                              color: _blue)),
                  const SizedBox(height: 6),
                  const Center(
                      child: Text('Uploading...',
                          style: TextStyle(
                              fontSize: 12,
                              color: _textGrey))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: _textGrey)),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final ok = await _confirmSave();
                      if (!ok) return;
                      ss(() => isUploading = true);
                      try {
                        String? imageUrl;
                        if (pickedImage != null) {
                          final fileName =
                              'cert_${widget.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          await _db.storage
                              .from('Certificates')
                              .upload(fileName,
                                  pickedImage!);
                          imageUrl = _db.storage
                              .from('Certificates')
                              .getPublicUrl(fileName);
                        }
                        await _db
                            .from('Certificates')
                            .insert({
                          'user_id':
                              widget.id,
                          'title':
                              titleCtrl.text.trim(),
                          'description':
                              descCtrl.text.trim(),
                          'date':    dateVal,
                          'image_url': imageUrl,
                        });
                        _fetchAll();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(
                                      'Error: $e')));
                        }
                      } finally {
                        ss(() =>
                            isUploading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: _white,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── shared date-picker display widget ──
  Widget _datePicker(String value, String placeholder) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined,
              size: 16, color: _blue),
          const SizedBox(width: 8),
          Text(
            value.isEmpty
                ? placeholder
                : _formatFullDate(value),
            style: TextStyle(
                fontSize: 13,
                color: value.isEmpty
                    ? const Color(0xFFADB5BD)
                    : _textDark),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFFADB5BD), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: _blue, width: 1.5),
        ),
      );

  Widget _dialogLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textDark));

  List<String> _parseSkills(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bluePale,
        body: Center(
            child: CircularProgressIndicator(
                color: _blue)),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: _bluePale,
        body: Center(child: Text('No user found.')),
      );
    }

    final name        = _user!['name'] ?? '';
    final email       = _user!['email'] ?? '';
    final phone       = _user!['phone'] ?? '';
    final accountType = _user!['account_type'] ?? '';
    final initials    = _getInitials(name);
    final about       = _info?['about'] ?? '';
    final skills      = _parseSkills(_info?['skills']);

    final size         = MediaQuery.of(context).size;
    final sw           = size.width;
    final sh           = size.height;
    final hPad         = sw * 0.05;
    final avatarSize   = (sw * 0.18).clamp(60.0, 90.0);
    final heroFontSize =
        (sw * 0.045).clamp(14.0, 20.0);
    final subFontSize  = (sw * 0.03).clamp(10.0, 13.0);

    return Scaffold(
      backgroundColor: _bluePale,
      body: Stack(
        children: [
          Positioned(
            top: -sh * 0.07,
            left: -sw * 0.18,
            child: _Blob(
                size: sw * 0.85,
                color: _blue.withOpacity(0.09)),
          ),
          Positioned(
            bottom: -sh * 0.06,
            right: -sw * 0.14,
            child: _Blob(
                size: sw * 0.65,
                color: _blue.withOpacity(0.07)),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [

                // ── App Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        hPad, 16, hPad, 0),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Text('My Profile',
                            style: TextStyle(
                                fontSize: (sw * 0.055)
                                    .clamp(18.0, 24.0),
                                fontWeight:
                                    FontWeight.w800,
                                color: _textDark,
                                letterSpacing: -0.3)),
                        _IconBtn(
                            icon: Icons
                                .settings_outlined,
                            onTap: () {}),
                      ],
                    ),
                  ),
                ),

                // ── Hero Card ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        hPad, 16, hPad, 0),
                    child: Container(
                      padding:
                          EdgeInsets.all(sw * 0.04),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius:
                            BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _blue
                                .withOpacity(0.10),
                            blurRadius: 30,
                            spreadRadius: 1,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Stack(children: [
                            Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                gradient:
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF60A5FA),
                                    _blue
                                  ],
                                  begin: Alignment
                                      .topLeft,
                                  end: Alignment
                                      .bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _blue
                                        .withOpacity(
                                            0.3),
                                    blurRadius: 16,
                                    offset:
                                        const Offset(
                                            0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                    initials,
                                    style: TextStyle(
                                        color: _white,
                                        fontSize:
                                            avatarSize *
                                                0.32,
                                        fontWeight:
                                            FontWeight
                                                .w800)),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width:
                                    avatarSize * 0.2,
                                height:
                                    avatarSize * 0.2,
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                      0xFF22C55E),
                                  shape:
                                      BoxShape.circle,
                                  border: Border.all(
                                      color: _white,
                                      width: 2),
                                ),
                              ),
                            ),
                          ]),
                          SizedBox(width: sw * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(
                                        name,
                                        style: TextStyle(
                                            fontSize:
                                                heroFontSize,
                                            fontWeight:
                                                FontWeight
                                                    .w800,
                                            color:
                                                _textDark),
                                        overflow:
                                            TextOverflow
                                                .ellipsis),
                                  ),
                                  if (accountType
                                      .isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal:
                                              7,
                                          vertical: 3),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            _blueLight,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    20),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize
                                                .min,
                                        children: [
                                          const Icon(
                                              Icons
                                                  .verified_rounded,
                                              size:
                                                  11,
                                              color:
                                                  _blue),
                                          const SizedBox(
                                              width:
                                                  3),
                                          Text(
                                              accountType,
                                              style: TextStyle(
                                                  fontSize:
                                                      subFontSize,
                                                  color:
                                                      _blue,
                                                  fontWeight:
                                                      FontWeight.w700)),
                                        ],
                                      ),
                                    ),
                                ]),
                                SizedBox(
                                    height:
                                        sw * 0.02),
                                Row(children: [
                                  const Icon(
                                      Icons
                                          .email_outlined,
                                      size: 13,
                                      color:
                                          _textGrey),
                                  const SizedBox(
                                      width: 4),
                                  Expanded(
                                      child: Text(
                                          email,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style: TextStyle(
                                              fontSize:
                                                  subFontSize,
                                              color:
                                                  _textGrey))),
                                ]),
                                SizedBox(
                                    height:
                                        sw * 0.015),
                                Row(children: [
                                  const Icon(
                                      Icons
                                          .phone_outlined,
                                      size: 13,
                                      color:
                                          _textGrey),
                                  const SizedBox(
                                      width: 4),
                                  Text(phone,
                                      style: TextStyle(
                                          fontSize:
                                              subFontSize,
                                          color:
                                              _textGrey)),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Stats ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        hPad, 14, hPad, 0),
                    child: Row(
                      children: [
                        _StatCard(
                            value:
                                '${_internships.length}',
                            label:
                                'Internships\nApplied'),
                        const SizedBox(width: 10),
                        _StatCard(
                            value:
                                '${_certs.length}',
                            label:
                                'Certificates\nUploaded'),
                        const SizedBox(width: 10),
                        const _StatCard(
                            value: '0',
                            label:
                                'Surveys\nCompleted'),
                      ],
                    ),
                  ),
                ),

                // ── About ──
                SliverToBoxAdapter(
                    child: _SectionTitle('About',
                        buttonLabel: 'Edit',
                        onAction: _editAbout)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: hPad),
                    child: _WhiteCard(
                      child: Text(
                        about.isNotEmpty
                            ? about
                            : 'No about info yet. Tap Edit to add.',
                        style: TextStyle(
                            fontSize: 13,
                            color: about.isNotEmpty
                                ? _textGrey
                                : _textGrey
                                    .withOpacity(0.6),
                            height: 1.6),
                      ),
                    ),
                  ),
                ),

                // ── Skills ──
                SliverToBoxAdapter(
                  child: _SectionTitle(
                    'Skills (${skills.length}/10)',
                    buttonLabel: '···',
                    onAction: () {},
                    // pass the anchor context so the menu
                    // appears right below the button
                    onActionWithContext: _skillsDeleteMode
                        ? null
                        : (ctx) => _showSkillsMenu(ctx),
                    onTapWhileDeleteMode:
                        _skillsDeleteMode
                            ? () => setState(() =>
                                _skillsDeleteMode = false)
                            : null,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: hPad),
                    child: _WhiteCard(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (_skillsDeleteMode)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                      bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons
                                          .info_outline_rounded,
                                      size: 14,
                                      color: Colors.red),
                                  const SizedBox(
                                      width: 6),
                                  const Text(
                                      'Tap ✕ to remove a skill',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.red)),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _skillsDeleteMode =
                                            false),
                                    child: const Text(
                                        'Done',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _blue,
                                            fontWeight:
                                                FontWeight
                                                    .w700)),
                                  ),
                                ],
                              ),
                            ),
                          skills.isNotEmpty
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills
                                      .map((s) =>
                                          _SkillChip(
                                            label: s,
                                            deleteMode:
                                                _skillsDeleteMode,
                                            onDelete:
                                                () async {
                                              final del =
                                                  await _confirmDelete(
                                                      s);
                                              if (del)
                                                _deleteSkill(
                                                    s);
                                            },
                                          ))
                                      .toList(),
                                )
                              : Text(
                                  'No skills yet. Tap ··· to add some. (Max 10)',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: _textGrey
                                          .withOpacity(
                                              0.6))),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Internships ──
                SliverToBoxAdapter(
                    child: _SectionTitle(
                        'Internships',
                        buttonLabel: 'Add',
                        onAction: () =>
                            _editInternship())),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: hPad),
                    child: _WhiteCard(
                      child: _internships.isEmpty
                          ? Text(
                              'No internships yet. Tap Add to add.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _textGrey
                                      .withOpacity(
                                          0.6)))
                          : Column(
                              children: _internships
                                  .map((i) =>
                                      _InternshipItem(
                                        data: i,
                                        onEdit: () =>
                                            _editInternship(
                                                i),
                                        onDelete: () =>
                                            _deleteInternship(
                                                i),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ),
                ),

                // ── Certificates ──
                SliverToBoxAdapter(
                    child: _SectionTitle(
                        'Certificates',
                        buttonLabel: 'Add',
                        onAction: _addCertificate)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        hPad, 0, hPad, 32),
                    child: _WhiteCard(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (_certs.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                      bottom: 12),
                              child: Text(
                                'No certificates yet.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _textGrey
                                        .withOpacity(
                                            0.6)),
                              ),
                            ),
                          ..._certs.map(
                              (c) =>
                                  _CertCard(data: c)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _addCertificate,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                      vertical: 12),
                              decoration:
                                  BoxDecoration(
                                color: _blueLight,
                                borderRadius:
                                    BorderRadius
                                        .circular(12),
                                border: Border.all(
                                    color: _blue
                                        .withOpacity(
                                            0.3),
                                    width: 1),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                      Icons
                                          .upload_file_rounded,
                                      size: 16,
                                      color: _blue),
                                  SizedBox(width: 8),
                                  Text(
                                      'Upload New Certificate',
                                      style: TextStyle(
                                          fontSize:
                                              13,
                                          color:
                                              _blue,
                                          fontWeight:
                                              FontWeight
                                                  .w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(),
    );
  }
}

// ─── SKILL CHIP ─────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  final bool deleteMode;
  final VoidCallback onDelete;
  const _SkillChip({
    required this.label,
    required this.deleteMode,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
          left: 12,
          right: deleteMode ? 6 : 12,
          top: 5,
          bottom: 5),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: deleteMode
                ? Colors.red.withOpacity(0.45)
                : _blue.withOpacity(0.25),
            width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: deleteMode
                      ? Colors.red
                      : _blue,
                  fontWeight: FontWeight.w600)),
          if (deleteMode) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color:
                      Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                    Icons.close_rounded,
                    size: 10,
                    color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── INTERNSHIP ITEM ────────────────────
class _InternshipItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _InternshipItem({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final startStr =
        _formatFullDate(data['start_date']);
    final endStr =
        _formatFullDate(data['end_date']);
    final dateStr  = '$startStr – $endStr';
    final desc =
        (data['description'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _blueLight,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
                Icons.work_outline_rounded,
                color: _blue,
                size: 20),
          ),
          const SizedBox(width: 12),

          // text block
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(data['company'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark)),
                const SizedBox(height: 2),
                Text(data['department'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        color: _textGrey)),
                const SizedBox(height: 5),
                // date badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3),
                  decoration: BoxDecoration(
                    color: _blueLight,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            _blue.withOpacity(0.2),
                        width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                          Icons
                              .calendar_today_rounded,
                          size: 10,
                          color: _blue),
                      const SizedBox(width: 4),
                      Text(dateStr,
                          style: const TextStyle(
                              fontSize: 11,
                              color: _blue,
                              fontWeight:
                                  FontWeight.w600)),
                    ],
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _textGrey,
                          height: 1.45)),
                ],
              ],
            ),
          ),

          // edit + delete buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIconBtn(
                  icon: Icons.edit_outlined,
                  color: _blue,
                  onTap: onEdit),
              const SizedBox(height: 4),
              _ActionIconBtn(
                  icon: Icons
                      .delete_outline_rounded,
                  color: Colors.red,
                  onTap: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ACTION ICON BUTTON ─────────────────
class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIconBtn(
      {required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ─── CERTIFICATE CARD ───────────────────
class _CertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CertCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        data['image_url'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (imageUrl != null &&
              imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                loadingBuilder:
                    (ctx, child, progress) {
                  if (progress == null)
                    return child;
                  return Container(
                    height: 160,
                    color: _blueLight,
                    child: const Center(
                        child:
                            CircularProgressIndicator(
                                color: _blue)),
                  );
                },
                errorBuilder: (ctx, err, _) =>
                    Container(
                  height: 100,
                  color: _blueLight,
                  child: const Center(
                      child: Icon(
                          Icons
                              .broken_image_outlined,
                          color: _blue)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    data['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w700,
                        color: _textDark)),
              ),
              if ((data['date'] ?? '')
                  .isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3),
                  decoration: BoxDecoration(
                    color: _blueLight,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                      _formatFullDate(
                          data['date']),
                      style: const TextStyle(
                          fontSize: 11,
                          color: _blue,
                          fontWeight:
                              FontWeight.w600)),
                ),
            ],
          ),
          if ((data['description'] ?? '')
              .isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(data['description'],
                style: const TextStyle(
                    fontSize: 13,
                    color: _textGrey)),
          ],
          const SizedBox(height: 10),
          const Divider(color: _border),
        ],
      ),
    );
  }
}

// ─── STAT CARD ──────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard(
      {required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _blue)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    color: _textGrey,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ─── SECTION TITLE ──────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onAction;
  final void Function(BuildContext ctx)?
      onActionWithContext;
  final VoidCallback? onTapWhileDeleteMode;

  const _SectionTitle(
    this.title, {
    required this.buttonLabel,
    required this.onAction,
    this.onActionWithContext,
    this.onTapWhileDeleteMode,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final is3dot = buttonLabel == '···';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          sw * 0.05, 22, sw * 0.05, 10),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark)),
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () {
                if (onTapWhileDeleteMode != null) {
                  onTapWhileDeleteMode!();
                } else if (onActionWithContext !=
                    null) {
                  onActionWithContext!(ctx);
                } else {
                  onAction();
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: is3dot ? 10 : 14,
                    vertical: 6),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(buttonLabel,
                    style: TextStyle(
                        fontSize:
                            is3dot ? 16 : 12,
                        color: _white,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing:
                            is3dot ? 1.5 : 0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WHITE CARD ─────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── BOTTOM NAV BAR ─────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const LandingPage()),
                  );
                },
              ),
              const _NavItem(
                  icon: Icons
                      .work_outline_rounded,
                  label: 'Internships',
                  active: false),
              const _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: true),
              const _NavItem(
                  icon: Icons.assignment_outlined,
                  label: 'Surveys',
                  active: false),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SMALL WIDGETS ──────────────────────
class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob(
      {required this.size, required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon,
            color: _textDark, size: 20),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? _blueLight
                  : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(icon,
                color: active
                    ? _blue
                    : _textGrey,
                size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: active
                      ? _blue
                      : _textGrey,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w400)),
        ],
      ),
    );
  }
}