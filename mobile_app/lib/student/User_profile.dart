import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'StudentHome.dart';
import 'survey.dart';
import 'internships_page.dart';
import '../app_session.dart';
import 'UserRole.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ─── COLORS ────────────────────────────
const _blue  = Color(0xFF3B82F6);
const _white = Colors.white;

// ─── DATE HELPER ────────────────────────
String _formatFullDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final parts = raw.split('-');
    final year  = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day   = parts.length >= 3 ? int.parse(parts[2]) : null;
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    if (day != null) {
      return '${day.toString().padLeft(2, '0')} ${months[month - 1]} $year';
    }
    return '${months[month - 1]} $year';
  } catch (_) {
    return raw;
  }
}

String _buildCertificateImageValue({
  required Uint8List bytes,
  required String? mimeType,
}) {
  final safeMimeType = (mimeType == null || mimeType.isEmpty)
      ? 'image/jpeg'
      : mimeType;
  return 'data:$safeMimeType;base64,${base64Encode(bytes)}';
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

DateTime _addMonths(DateTime d, int months) {
  int y = d.year;
  int m = d.month + months;
  while (m > 12) { m -= 12; y++; }
  while (m < 1)  { m += 12; y--; }
  final maxDay = DateUtils.getDaysInMonth(y, m);
  return DateTime(y, m, d.day.clamp(1, maxDay));
}

// ─── DATE PICKER ────────────────────────
Future<String?> pickFullDate(
  BuildContext context, {
  String? initial,
  DateTime? minDate,
  DateTime? maxDate,
}) async {
  final today     = DateTime.now();
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final effectiveMax = maxDate ?? yesterday;

  DateTime sel = effectiveMax;

  if (initial != null && initial.isNotEmpty) {
    try {
      final p = initial.split('-');
      sel = DateTime(int.parse(p[0]), int.parse(p[1]),
          p.length >= 3 ? int.parse(p[2]) : 1);
    } catch (_) {}
  }

  if (minDate != null && sel.isBefore(minDate)) sel = minDate;
  if (sel.isAfter(effectiveMax)) sel = effectiveMax;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) {
        final theme = Theme.of(ctx).colorScheme;
        final daysInMonth = DateUtils.getDaysInMonth(sel.year, sel.month);

        bool monthDisabled(int year, int month) {
          final lastOfMonth  = DateTime(year, month, DateUtils.getDaysInMonth(year, month));
          final firstOfMonth = DateTime(year, month, 1);
          if (minDate != null && lastOfMonth.isBefore(minDate)) return true;
          if (firstOfMonth.isAfter(effectiveMax)) return true;
          return false;
        }

        bool dayDisabled(int day) {
          final d = DateTime(sel.year, sel.month, day);
          if (minDate != null && d.isBefore(minDate)) return true;
          if (d.isAfter(effectiveMax)) return true;
          return false;
        }

        return AlertDialog(
          backgroundColor: theme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, color: _blue),
                        onPressed: () => ss(() {
                          final prev = DateTime(sel.year - 1, sel.month,
                              sel.day.clamp(1, DateUtils.getDaysInMonth(sel.year - 1, sel.month)));
                          if (minDate == null || !DateTime(prev.year, 12, 31).isBefore(minDate)) sel = prev;
                        }),
                      ),
                      Text('${sel.year}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.onSurface)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, color: _blue),
                        onPressed: () => ss(() {
                          final next = DateTime(sel.year + 1, sel.month,
                              sel.day.clamp(1, DateUtils.getDaysInMonth(sel.year + 1, sel.month)));
                          if (!DateTime(next.year, 1, 1).isAfter(effectiveMax)) sel = next;
                        }),
                      ),
                    ],
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, childAspectRatio: 1.6,
                      crossAxisSpacing: 6, mainAxisSpacing: 6,
                    ),
                    itemCount: 12,
                    itemBuilder: (_, i) {
                      const mNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                      final isSelected = sel.month == i + 1;
                      final disabled   = monthDisabled(sel.year, i + 1);
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: disabled ? null : () => ss(() {
                          final newDay = sel.day.clamp(1, DateUtils.getDaysInMonth(sel.year, i + 1));
                          sel = DateTime(sel.year, i + 1, newDay);
                        }),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? _blue : disabled ? theme.outline : _blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(mNames[i],
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: isSelected ? _white : disabled ? theme.onSurfaceVariant.withOpacity(0.4) : _blue)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft,
                      child: Text('Day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface))),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, childAspectRatio: 1.1,
                      crossAxisSpacing: 4, mainAxisSpacing: 4,
                    ),
                    itemCount: daysInMonth,
                    itemBuilder: (_, i) {
                      final day      = i + 1;
                      final isSel    = sel.day == day;
                      final disabled = dayDisabled(day);
                      return InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: disabled ? null : () => ss(() => sel = DateTime(sel.year, sel.month, day)),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSel ? _blue : disabled ? Colors.transparent : _blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$day',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isSel ? _white : disabled ? theme.onSurfaceVariant.withOpacity(0.3) : _blue)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, null),
                          child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final r = '${sel.year}-${sel.month.toString().padLeft(2, '0')}-${sel.day.toString().padLeft(2, '0')}';
                          Navigator.pop(ctx, r);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: _white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
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
  String _cvUrl = ''; 
  bool _isLoading        = true;
  bool _skillsDeleteMode = false;
  int  _navIndex         = 2;
  int _surveyCount       = 0;
  int _appliedJobsCount  = 0;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = await _db.from('User_profile').select().eq('id', widget.id).single();
      final infoList = await _db.from('Profile_info').select().eq('user_id', widget.id);
      final certs = await _db.from('Certificates').select().eq('user_id', widget.id).order('id', ascending: false);
      final internships = await _db.from('Internships').select().eq('user_id', widget.id).order('id', ascending: false);
      final surveyes = await _db.from('Survey').select('').eq('user_id', widget.id);
      final appliedJobs = await _db.from('Job_applications').select('id').eq('student_id', widget.id);
      if (!mounted) return;
      setState(() {
        _user        = user;
        _info        = infoList.isNotEmpty ? infoList.first : null;
        _certs       = List<Map<String, dynamic>>.from(certs);
        _internships = List<Map<String, dynamic>>.from(internships);
        _cvUrl       = infoList.isNotEmpty ? (infoList.first['cv_url'] ?? '') : '';
        _surveyCount       = surveyes.length;
        _appliedJobsCount  = (appliedJobs as List).length;
        _isLoading   = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleBottomNavTap(int index) async {
    if (index == 0) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(userId: widget.id)),
      );
      return;
    }

    if (index == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InternshipsPage(
            userId:      widget.id,
            userName:    _user?['name']  ?? '',
            userEmail:   _user?['email'] ?? '',
          ),
        ),
      );
      await _fetchAll();
      setState(() => _navIndex = 2);
      return;
    }

    if (_navIndex == index && index != 2) return;

    setState(() => _navIndex = index);

    if (index == 2) {
      await _fetchAll();
    }
  }

  // ── Settings ─────────────────────────────────────────────────

  void _openSettings() {
    final theme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: theme.surfaceContainerHighest,
      builder: (ctx) => _SettingsSheet(
        userId: widget.id,
        currentName:  _user?['name']  ?? '',
        currentPhone: _user?['phone'] ?? '',
        db: _db,
        onSaved: () { Navigator.pop(ctx); _fetchAll(); },
        onLogout: () async {
          Navigator.pop(ctx);
          await AppSession.clear();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UserRole()),
            (route) => false,
          );
        },
      ),
    );
  }

  String _getInitials(String name) =>
      name.trim().split(' ').where((e) => e.isNotEmpty).take(2).map((e) => e[0].toUpperCase()).join();

  // ── Confirm dialogs ─────────────────────────────────────────

  Future<bool> _confirmSave() async {
    final theme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
      context: context, // screen-level context — always valid
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface)),
        content: Text('Are you sure you want to save?', style: TextStyle(color: theme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('No', style: TextStyle(color: theme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: _white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _confirmDelete(String name) async {
    final theme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
      context: context, // screen-level context — always valid
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface)),
        content: Text('Are you sure you want to delete "$name"?', style: TextStyle(color: theme.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  // ── About ────────────────────────────────────────────────────

  void _editAbout() {
    final ctrl = TextEditingController(text: _info?['about'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: theme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit About', style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface)),
          content: TextField(
              controller: ctrl, 
              maxLines: 5, 
              style: TextStyle(color: theme.onSurface),
              decoration: _inputDec(ctx, 'Tell us about yourself...')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (!await _confirmSave()) return;
                try {
                  if (_info == null) {
                    await _db.from('Profile_info').insert({'user_id': widget.id, 'about': ctrl.text.trim(), 'skills': ''});
                  } else {
                    await _db.from('Profile_info').update({'about': ctrl.text.trim()}).eq('user_id', widget.id);
                  }
                  _fetchAll();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ── Skills ───────────────────────────────────────────────────

  void _showSkillsMenu(BuildContext anchorCtx) async {
    final theme = Theme.of(anchorCtx).colorScheme;
    final skills  = _parseSkills(_info?['skills']);
    final box     = anchorCtx.findRenderObject() as RenderBox;
    final overlay = Navigator.of(anchorCtx).overlay!.context.findRenderObject() as RenderBox;
    final pos     = RelativeRect.fromRect(
      Rect.fromPoints(box.localToGlobal(Offset.zero, ancestor: overlay),
          box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay)),
      Offset.zero & overlay.size,
    );

    final choice = await showMenu<String>(
      context: anchorCtx,
      position: pos,
      color: theme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(value: 'add',
            child: Row(children: [
              const Icon(Icons.add_circle_outline_rounded, size: 18, color: _blue),
              const SizedBox(width: 10),
              Text('Add Skill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.onSurface)),
            ])),
        if (skills.isNotEmpty)
          PopupMenuItem(value: 'delete',
              child: Row(children: const [
                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                SizedBox(width: 10),
                Text('Delete Skill', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
              ])),
      ],
    );

    if (choice == 'add')    _addSkillDialog();
    if (choice == 'delete') setState(() => _skillsDeleteMode = true);
  }

  void _addSkillDialog() {
    final existing = _parseSkills(_info?['skills']);
    if (existing.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 10 skills reached.'), backgroundColor: Colors.orange));
      return;
    }
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: theme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Skill (${existing.length}/10)', style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface)),
          content: TextField(
            controller: ctrl, 
            style: TextStyle(color: theme.onSurface),
            decoration: _inputDec(ctx, 'e.g. Flutter, Python...'), 
            autofocus: true
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant))),
            ElevatedButton(
              onPressed: () async {
                final s = ctrl.text.trim();
                if (s.isEmpty) return;
                Navigator.pop(ctx);
                if (!await _confirmSave()) return;
                try {
                  final updated = [...existing, s].join(',');
                  if (_info == null) {
                    await _db.from('Profile_info').insert({'user_id': widget.id, 'about': '', 'skills': updated});
                  } else {
                    await _db.from('Profile_info').update({'skills': updated}).eq('user_id', widget.id);
                  }
                  _fetchAll();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSkill(String skill) async {
    final existing = _parseSkills(_info?['skills'])..remove(skill);
    try {
      await _db.from('Profile_info').update({'skills': existing.join(',')}).eq('user_id', widget.id);
      await _fetchAll();
      if (existing.isEmpty) setState(() => _skillsDeleteMode = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Internships ──────────────────────────────────────────────

  void _editInternship([Map<String, dynamic>? existing]) {
    final deptCtrl = TextEditingController(text: existing?['department'] ?? '');
    final compCtrl = TextEditingController(text: existing?['company'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    String startVal = existing?['start_date'] ?? '';
    String endVal   = existing?['end_date']   ?? '';
    String? errorMsg;

    final today     = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          final theme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: theme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(existing == null ? 'Add Internship' : 'Edit Internship',
                style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogLabel(ctx, 'Department'), const SizedBox(height: 6),
                  TextField(controller: deptCtrl, style: TextStyle(color: theme.onSurface), decoration: _inputDec(ctx, 'e.g. Software Engineering')),
                  const SizedBox(height: 12),
                  _dialogLabel(ctx, 'Company'), const SizedBox(height: 6),
                  TextField(controller: compCtrl, style: TextStyle(color: theme.onSurface), decoration: _inputDec(ctx, 'e.g. Google')),
                  const SizedBox(height: 12),
                  _dialogLabel(ctx, 'Description'), const SizedBox(height: 6),
                  TextField(controller: descCtrl, maxLines: 3, style: TextStyle(color: theme.onSurface), decoration: _inputDec(ctx, 'What did you do there?')),
                  const SizedBox(height: 12),
                  _dialogLabel(ctx, 'Start Date'), const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await pickFullDate(context, initial: startVal, maxDate: yesterday);
                      if (picked != null) ss(() => startVal = picked);
                    },
                    child: _datePicker(ctx, startVal, 'Pick start date'),
                  ),
                  const SizedBox(height: 12),
                  _dialogLabel(ctx, 'End Date'), const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      DateTime? minEnd;
                      if (startVal.isNotEmpty) {
                        minEnd = _addMonths(DateTime.parse(startVal), 1);
                      }
                      final picked = await pickFullDate(context, initial: endVal,
                          minDate: minEnd, maxDate: yesterday);
                      if (picked != null) ss(() => endVal = picked);
                    },
                    child: _datePicker(ctx, endVal, 'Pick end date'),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMsg!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant))),
              ElevatedButton(
                onPressed: () async {
                  if (deptCtrl.text.trim().isEmpty || compCtrl.text.trim().isEmpty) {
                    ss(() => errorMsg = 'Please fill in department and company.'); return;
                  }
                  if (startVal.isEmpty || endVal.isEmpty) {
                    ss(() => errorMsg = 'Please pick both dates.'); return;
                  }
                  final start  = DateTime.parse(startVal);
                  final end    = DateTime.parse(endVal);
                  final minEnd = _addMonths(start, 1);
                  if (start.isAfter(yesterday)) {
                    ss(() => errorMsg = 'Start date must be at most yesterday.'); return;
                  }
                  if (end.isAfter(yesterday)) {
                    ss(() => errorMsg = 'End date must be at most yesterday.'); return;
                  }
                  if (!end.isAfter(start)) {
                    ss(() => errorMsg = 'End date must be after start date.'); return;
                  }
                  if (end.isBefore(minEnd)) {
                    ss(() => errorMsg = 'Duration must be at least 1 month.'); return;
                  }
                  Navigator.pop(ctx);
                  if (!await _confirmSave()) return;
                  try {
                    final payload = {
                      'user_id': widget.id, 'department': deptCtrl.text.trim(),
                      'company': compCtrl.text.trim(), 'description': descCtrl.text.trim(),
                      'start_date': startVal, 'end_date': endVal,
                    };
                    if (existing == null) {
                      await _db.from('Internships').insert(payload);
                    } else {
                      await _db.from('Internships').update(payload).eq('id', existing['id']);
                    }
                    _fetchAll();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: _white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteInternship(Map<String, dynamic> item) async {
    if (!await _confirmDelete(item['company'] ?? 'this internship')) return;
    try {
      await _db.from('Internships').delete().eq('id', item['id']);
      _fetchAll();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Certificates ─────────────────────────────────────────────

  void _addCertificate() => _editCertificate();

  void _editCertificate([Map<String, dynamic>? existing]) {
    final titleCtrl = TextEditingController(text: (existing?['title'] ?? '').toString());
    final descCtrl  = TextEditingController(text: (existing?['description'] ?? '').toString());
    String dateVal  = (existing?['date'] ?? '').toString();
    XFile?    pickedImage;
    Uint8List? pickedImageBytes;
    final existingImageValue = (existing?['image_url'] ?? '').toString();
    final existingImageBytes = _decodeCertificateImageValue(existingImageValue);

    final today     = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) {
          final theme = Theme.of(ctx).colorScheme;
          bool isUploading = false;

          return AlertDialog(
            backgroundColor: theme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              existing == null ? 'Add Certificate' : 'Edit Certificate',
              style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogLabel(ctx, 'Title'), const SizedBox(height: 6),
                  TextField(controller: titleCtrl, style: TextStyle(color: theme.onSurface), decoration: _inputDec(ctx, 'e.g. Flutter Bootcamp')),
                  const SizedBox(height: 12),
                  _dialogLabel(ctx, 'Description'), const SizedBox(height: 6),
                  TextField(controller: descCtrl, maxLines: 3, style: TextStyle(color: theme.onSurface), decoration: _inputDec(ctx, 'Short description...')),
                  const SizedBox(height: 12),
                  _dialogLabel(ctx, 'Date'), const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await pickFullDate(context, initial: dateVal, maxDate: yesterday);
                      if (picked != null) ss(() => dateVal = picked);
                    },
                    child: _datePicker(ctx, dateVal, 'Pick date'),
                  ),
                  const SizedBox(height: 16),
                  _dialogLabel(ctx, 'Certificate Image'), const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked == null) return;
                      final bytes = await picked.readAsBytes();
                      ss(() {
                        pickedImage      = picked;
                        pickedImageBytes = bytes;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: 96,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _blue.withOpacity(0.3)),
                      ),
                      child: pickedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(pickedImageBytes!, fit: BoxFit.cover),
                            )
                          : existingImageValue.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: existingImageBytes != null
                                      ? Image.memory(existingImageBytes, fit: BoxFit.cover)
                                      : Image.network(
                                          existingImageValue,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, _, _) => const Center(
                                            child: Icon(Icons.broken_image_outlined, color: _blue),
                                          ),
                                        ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file_rounded, color: _blue, size: 28),
                                    SizedBox(height: 6),
                                    Text('Tap to pick image',
                                        style: TextStyle(color: _blue, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ]),
                    ),
                  ),
                  if (isUploading) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator(color: _blue)),
                    const SizedBox(height: 6),
                    Center(child: Text('Saving...', style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant))),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant)),
              ),
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () async {
                        // ── Validation ──────────────────────────────────
                        final title       = titleCtrl.text.trim();
                        final description = descCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a certificate title.')),
                          );
                          return;
                        }
                        if (dateVal.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please pick a certificate date.')),
                          );
                          return;
                        }
                        final confirmed = await _confirmSave();
                        if (!confirmed) return; // user tapped No — keep dialog open

                        // ── Show uploading state, then close dialog ───────
                        ss(() => isUploading = true);
                        await Future.delayed(Duration.zero); // let the spinner render

                        // Close the edit dialog now that user confirmed
                        if (ctx.mounted) Navigator.pop(ctx);

                        // ── DB call ──────────────────────────────────────
                        try {
                          String? imageUrl;
                          if (pickedImage != null && pickedImageBytes != null) {
                            imageUrl = _buildCertificateImageValue(
                              bytes: pickedImageBytes!,
                              mimeType: pickedImage!.mimeType,
                            );
                          }

                          final payload = {
                            'user_id'    : widget.id,
                            'title'      : title,
                            'description': description,
                            'date'       : dateVal,
                            'image_url'  : imageUrl ?? existingImageValue,
                          };

                          if (existing == null) {
                            // INSERT new certificate
                            await _db.from('Certificates').insert(payload);
                          } else {
                            // UPDATE existing certificate — use the record's id
                            await _db
                                .from('Certificates')
                                .update(payload)
                                .eq('id', existing['id']);
                          }

                          if (mounted) _fetchAll(); // refresh the list from DB
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('Error saving: $e')));
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCertificate(Map<String, dynamic> item) async {
    // _confirmDelete uses screen-level `context` — always valid
    final confirmed = await _confirmDelete(item['title'] ?? 'this certificate');
    if (!confirmed) return;
    if (!mounted) return;
    try {
      await _db.from('Certificates').delete().eq('id', item['id']);
      if (mounted) _fetchAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  void _showCertificateImage(Map<String, dynamic> item) {
    final imageUrl   = (item['image_url'] ?? '').toString();
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
                          errorBuilder: (context, _, _) => Container(
                            height: 220,
                            color: _blue.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: _blue, size: 36),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // ── CV Upload ───────────────────────────────────────────────

  Future<void> _uploadCv() async {
    final theme = Theme.of(context).colorScheme;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
        withData: true, 
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.surfaceContainerHighest,
          content: Row(children: [
            const CircularProgressIndicator(color: _blue),
            const SizedBox(width: 16),
            Text('Uploading CV...', style: TextStyle(color: theme.onSurface)),
          ]),
        ),
      );

      final fileName = 'cv_${widget.id}_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';

      if (kIsWeb) {
        // 1. Web Upload (uses bytes)
        await _db.storage.from('CVs').uploadBinary(
          fileName, 
          file.bytes!,
        );
      } else {
        // 2. Mobile Upload (uses path)
        if (file.path == null) throw Exception('File path is null');
        await _db.storage.from('CVs').upload(
          fileName, 
          File(file.path!),
        );
      }
      
      final cvUrl = _db.storage.from('CVs').getPublicUrl(fileName);

      // Save to Database
      if (_info == null) {
        await _db.from('Profile_info').insert({
          'user_id': widget.id, 
          'cv_url': cvUrl,
          'about': '',     
          'skills': ''
        });
      } else {
        await _db.from('Profile_info').update({'cv_url': cvUrl}).eq('user_id', widget.id);
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      await _fetchAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV uploaded successfully!'), backgroundColor: Colors.green),
      );

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCv() async {
    if (!await _confirmDelete('your CV')) return;
    try {
      await _db.from('Profile_info').update({'cv_url': ''}).eq('user_id', widget.id);
      await _fetchAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _viewCv() async {
    if (_cvUrl.isEmpty) return;

    final rawUrl = _cvUrl.trim();
    if (rawUrl.isEmpty) return;

    Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://$rawUrl');
    }

    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV link is invalid.')),
        );
      }
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open CV.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open CV.')),
        );
      }
    }
  }

  // ── Shared helpers ───────────────────────────────────────────

  Widget _datePicker(BuildContext context, String value, String placeholder) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      child: Row(children: [
        const Icon(Icons.calendar_month_outlined, size: 16, color: _blue),
        const SizedBox(width: 8),
        Text(value.isEmpty ? placeholder : _formatFullDate(value),
            style: TextStyle(fontSize: 13, color: value.isEmpty ? theme.onSurfaceVariant.withOpacity(0.6) : theme.onSurface)),
      ]),
    );
  }

  InputDecoration _inputDec(BuildContext context, String hint) {
    final theme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
      filled: true, fillColor: theme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.5)),
    );
  }

  Widget _dialogLabel(BuildContext context, String text) {
    final theme = Theme.of(context).colorScheme;
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface));
  }

  List<String> _parseSkills(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    
    if (_isLoading) {
      return Scaffold(backgroundColor: theme.surface,
          body: const Center(child: CircularProgressIndicator(color: _blue)));
    }
    if (_user == null) {
      return Scaffold(backgroundColor: theme.surface,
          body: const Center(child: Text('No user found.')));
    }

    final name        = _user!['name']         ?? '';
    final email       = _user!['email']        ?? '';
    final phone       = _user!['phone']        ?? '';
    final accountType = _user!['account_type'] ?? '';
    final initials    = _getInitials(name);
    final about       = _info?['about'] ?? '';
    final skills      = _parseSkills(_info?['skills']);

    final sw         = MediaQuery.of(context).size.width;
    final sh         = MediaQuery.of(context).size.height;
    final hPad       = sw * 0.05;
    final avatarSize = (sw * 0.18).clamp(60.0, 90.0);
    final heroFont   = (sw * 0.045).clamp(14.0, 20.0);
    final subFont    = (sw * 0.030).clamp(10.0, 13.0);

    Widget body;
    if (_navIndex == 3) {
      body = SurveyScreen(userId: widget.id, internships: _internships);
    } else {
      body = _buildProfileBody(
        name: name, email: email, phone: phone,
        accountType: accountType, initials: initials,
        about: about, skills: skills,
        sw: sw, sh: sh, hPad: hPad,
        avatarSize: avatarSize, heroFont: heroFont, subFont: subFont,
      );
    }

    return Scaffold(
      backgroundColor: theme.surface,
      body: body,
      bottomNavigationBar: _BottomBar(
        currentIndex: _navIndex,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildProfileBody({
    required String name, required String email, required String phone,
    required String accountType, required String initials,
    required String about, required List<String> skills,
    required double sw, required double sh, required double hPad,
    required double avatarSize, required double heroFont, required double subFont,
  }) {
    final theme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(top: -sh * 0.07, left: -sw * 0.18,
            child: _Blob(size: sw * 0.85, color: _blue.withOpacity(0.09))),
        Positioned(bottom: -sh * 0.06, right: -sw * 0.14,
            child: _Blob(size: sw * 0.65, color: _blue.withOpacity(0.07))),
        SafeArea(
          child: CustomScrollView(
            slivers: [

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Profile',
                          style: TextStyle(fontSize: (sw * 0.055).clamp(18.0, 24.0),
                              fontWeight: FontWeight.w800, color: theme.onSurface, letterSpacing: -0.3)),
                      _RippleIconBtn(icon: Icons.settings_outlined, onTap: _openSettings),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                  child: Container(
                    padding: EdgeInsets.all(sw * 0.04),
                    decoration: BoxDecoration(
                      color: theme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: theme.primary.withOpacity(0.05),
                          blurRadius: 30, spreadRadius: 1, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(children: [
                          Container(
                            width: avatarSize, height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                  colors: [const Color(0xFF60A5FA), theme.primary],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                              boxShadow: [BoxShadow(color: theme.primary.withOpacity(0.3),
                                  blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: Center(child: Text(initials,
                                style: TextStyle(color: Colors.white,
                                    fontSize: avatarSize * 0.32, fontWeight: FontWeight.w800))),
                          ),
                          Positioned(bottom: 2, right: 2,
                              child: Container(
                                width: avatarSize * 0.2, height: avatarSize * 0.2,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E), shape: BoxShape.circle,
                                    border: Border.all(color: theme.surfaceContainerHighest, width: 2)),
                              )),
                        ]),
                        SizedBox(width: sw * 0.04),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(name,
                                  style: TextStyle(fontSize: heroFont, fontWeight: FontWeight.w800, color: theme.onSurface),
                                  overflow: TextOverflow.ellipsis)),
                              if (accountType.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.verified_rounded, size: 11, color: _blue),
                                    const SizedBox(width: 3),
                                    Text(accountType, style: TextStyle(fontSize: subFont, color: const Color.fromARGB(255, 135, 165, 234), fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                            ]),
                            SizedBox(height: sw * 0.02),
                            Row(children: [
                              Icon(Icons.email_outlined, size: 13, color: theme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(child: Text(email, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: subFont, color: theme.onSurfaceVariant))),
                            ]),
                            SizedBox(height: sw * 0.015),
                            Row(children: [
                              Icon(Icons.phone_outlined, size: 13, color: theme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(phone, style: TextStyle(fontSize: subFont, color: theme.onSurfaceVariant)),
                            ]),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                  child: Row(children: [
                    _StatCard(value: '${_internships.length + _appliedJobsCount}', label: 'Internships\nApplied'),
                    const SizedBox(width: 10),
                    _StatCard(value: '${_certs.length}', label: 'Certificates\nUploaded'),
                    const SizedBox(width: 10),
                    _StatCard(value: '$_surveyCount', label: 'Surveys\nCompleted'),
                  ]),
                ),
              ),

              SliverToBoxAdapter(child: _SectionTitle('About', buttonLabel: 'Edit', onAction: _editAbout)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _WhiteCard(child: Text(
                    about.isNotEmpty ? about : 'No about info yet. Tap Edit to add.',
                    style: TextStyle(fontSize: 13, height: 1.6,
                        color: about.isNotEmpty ? theme.onSurfaceVariant : theme.onSurfaceVariant.withOpacity(0.6)),
                  )),
                ),
              ),

              SliverToBoxAdapter(
                child: _SectionTitle(
                  'Skills (${skills.length}/10)',
                  buttonLabel: '···',
                  onAction: () {},
                  onActionWithContext: _skillsDeleteMode ? null : (ctx) => _showSkillsMenu(ctx),
                  onTapWhileDeleteMode: _skillsDeleteMode ? () => setState(() => _skillsDeleteMode = false) : null,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _WhiteCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (_skillsDeleteMode)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Colors.red),
                            const SizedBox(width: 6),
                            const Text('Tap ✕ to remove a skill',
                                style: TextStyle(fontSize: 12, color: Colors.red)),
                            const Spacer(),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => setState(() => _skillsDeleteMode = false),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text('Done', style: TextStyle(fontSize: 12, color: _blue, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ),
                      skills.isNotEmpty
                          ? Wrap(
                              spacing: 8, runSpacing: 8,
                              children: skills.map((s) => _SkillChip(
                                label: s, deleteMode: _skillsDeleteMode,
                                onDelete: () async { if (await _confirmDelete(s)) _deleteSkill(s); },
                              )).toList(),
                            )
                          : Text('No skills yet. Tap ··· to add some. (Max 10)',
                              style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant.withOpacity(0.6))),
                    ]),
                  ),
                ),
              ),

              // Internships
              SliverToBoxAdapter(child: _SectionTitle('Internships', buttonLabel: 'Add', onAction: () => _editInternship())),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _WhiteCard(
                    child: _internships.isEmpty
                        ? Text('No internships yet. Tap Add to add.',
                            style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant.withOpacity(0.6)))
                        : Column(
                            children: _internships.map((i) => _InternshipItem(
                              data: i,
                              onEdit: () => _editInternship(i),
                              onDelete: () => _deleteInternship(i),
                            )).toList(),
                          ),
                  ),
                ),
              ),
              // CV Upload Section
              SliverToBoxAdapter(child: _SectionTitle('CV / Resume', buttonLabel: _cvUrl.isEmpty ? 'Upload' : 'Update', onAction: _uploadCv)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: _WhiteCard(
                    child: _cvUrl.isEmpty
                        ? Column(children: [
                            Icon(Icons.description_outlined, size: 40, color: theme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text('No CV uploaded yet',
                                style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant.withOpacity(0.6))),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _uploadCv,
                              icon: const Icon(Icons.upload_file_rounded, size: 18),
                              label: const Text('Upload CV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: _white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ])
                        : Column(children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _blue.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.picture_as_pdf_rounded, color: _blue, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('CV / Resume',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.onSurface)),
                                    const SizedBox(height: 2),
                                    Text('PDF, DOC, or DOCX',
                                        style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant)),
                                  ]),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: _deleteCv,
                                  tooltip: 'Delete CV',
                                ),
                              ]),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Row(children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _viewCv,
                                    icon: const Icon(Icons.visibility_rounded, size: 18),
                                    label: const Text('View CV'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _blue,
                                      side: const BorderSide(color: _blue),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _uploadCv,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Replace'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _blue,
                                      side: const BorderSide(color: _blue),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                  ),
                ),
              ),
               // Certificates
              SliverToBoxAdapter(child: _SectionTitle('Certificates', buttonLabel: 'Add', onAction: _addCertificate)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 32),
                  child: _WhiteCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (_certs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('No certificates yet.',
                              style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant.withOpacity(0.6))),
                        ),
                      ..._certs.map((c) => _CertCard(
                            data: c,
                            onEdit: () => _editCertificate(c),
                            onDelete: () => _deleteCertificate(c),
                            onOpenImage: () => _showCertificateImage(c),
                          )),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _addCertificate,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _blue.withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _blue.withOpacity(0.3)),
                            ),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.upload_file_rounded, size: 16, color: _blue),
                              SizedBox(width: 8),
                              Text('Upload New Certificate',
                                  style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SKILL CHIP ──────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  final bool deleteMode;
  final VoidCallback onDelete;
  const _SkillChip({required this.label, required this.deleteMode, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(left: 12, right: deleteMode ? 6 : 12, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: deleteMode ? Colors.red.withOpacity(0.45) : _blue.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: deleteMode ? Colors.red : _blue)),
        if (deleteMode) ...[
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onDelete,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded, size: 10, color: Colors.red),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─── INTERNSHIP ITEM ─────────────────────
class _InternshipItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _InternshipItem({required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final dateStr = '${_formatFullDate(data['start_date'])} – ${_formatFullDate(data['end_date'])}';
    final desc    = (data['description'] ?? '').toString().trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.work_outline_rounded, color: _blue, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data['company'] ?? '',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.onSurface)),
          const SizedBox(height: 2),
          Text(data['department'] ?? '', style: TextStyle(fontSize: 13, color: theme.onSurfaceVariant)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _blue.withOpacity(0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today_rounded, size: 10, color: _blue),
              const SizedBox(width: 4),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant, height: 1.45)),
          ],
        ])),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _RippleActionBtn(icon: Icons.edit_outlined, color: _blue, onTap: onEdit),
          const SizedBox(height: 4),
          _RippleActionBtn(icon: Icons.delete_outline_rounded, color: Colors.red, onTap: onDelete),
        ]),
      ]),
    );
  }
}

// ─── CERTIFICATE CARD ────────────────────
class _CertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpenImage;
  const _CertCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final imageUrl   = (data['image_url'] as String?) ?? '';
    final imageBytes = _decodeCertificateImageValue(imageUrl);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (imageUrl.isNotEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onOpenImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageBytes != null
                  ? Image.memory(imageBytes, width: 92, height: 92, fit: BoxFit.cover,
                      errorBuilder: (ctx, _, _) => Container(width: 92, height: 92, color: _blue.withOpacity(0.1),
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: _blue))))
                  : Image.network(imageUrl, width: 92, height: 92, fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, prog) => prog == null ? child :
                          Container(width: 92, height: 92, color: _blue.withOpacity(0.1),
                              child: const Center(child: SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(color: _blue, strokeWidth: 2.4)))),
                      errorBuilder: (ctx, _, _) => Container(width: 92, height: 92, color: _blue.withOpacity(0.1),
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: _blue)))),
            ),
          )
        else
          Container(width: 92, height: 92,
              decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.image_outlined, color: _blue)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(data['title'] ?? '',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.onSurface))),
              if ((data['date'] ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(_formatFullDate(data['date']),
                      style: const TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600)),
                ),
            ]),
            if ((data['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(data['description'], style: TextStyle(fontSize: 12, color: theme.onSurfaceVariant, height: 1.4)),
            ],
            if (imageUrl.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Tap image to view full certificate',
                  style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Column(mainAxisSize: MainAxisSize.min, children: [
          _RippleActionBtn(icon: Icons.edit_outlined, color: _blue, onTap: onEdit),
          const SizedBox(height: 4),
          _RippleActionBtn(icon: Icons.delete_outline_rounded, color: Colors.red, onTap: onDelete),
        ]),
      ]),
    );
  }
}

// ─── SETTINGS SHEET ──────────────────────
class _SettingsSheet extends StatefulWidget {
  final int    userId;
  final String currentName;
  final String currentPhone;
  final SupabaseClient db;
  final VoidCallback onSaved;
  final VoidCallback onLogout;

  const _SettingsSheet({
    required this.userId,
    required this.currentName,
    required this.currentPhone,
    required this.db,
    required this.onSaved,
    required this.onLogout,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _newPassCtrl;
  late final TextEditingController _confirmPassCtrl;
  bool _isSaving = false;
  bool _hideNewPass = true;
  bool _hideConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl        = TextEditingController(text: widget.currentName);
    _phoneCtrl       = TextEditingController(text: widget.currentPhone);
    _newPassCtrl     = TextEditingController();
    _confirmPassCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name  = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    // Validate password only if user typed something
    if (newPass.isNotEmpty) {
      if (newPass.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New password must be at least 6 characters.')),
        );
        return;
      }
      if (newPass != confirmPass) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> updates = {'name': name, 'phone': phone};
      if (newPass.isNotEmpty) updates['password'] = newPass;

      await widget.db
          .from('User_profile')
          .update(updates)
          .eq('id', widget.userId);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _dec(BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.onSurfaceVariant.withOpacity(0.6), fontSize: 13),
      filled: true, fillColor: theme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      prefixIcon: Icon(icon, color: theme.onSurfaceVariant, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.outline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: theme.outline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.onSurface)),
          const SizedBox(height: 20),
          Text('Full Name',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(fontSize: 14, color: theme.onSurface),
            decoration: _dec(context, 'Your full name', Icons.person_outline_rounded),
          ),
          const SizedBox(height: 14),
          Text('Phone Number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface)),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 14, color: theme.onSurface),
            decoration: _dec(context, '+20 123 456 7890', Icons.phone_outlined),
          ),
          const SizedBox(height: 18),
          // ── Password Section ──────────────────────────────────────────────
          Row(children: [
            Container(
              width: 3, height: 18,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(2)),
            ),
            Text('Change Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: theme.onSurface)),
            const SizedBox(width: 6),
            Text('(leave blank to keep current)',
                style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 10),
          Text('New Password',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface)),
          const SizedBox(height: 6),
          TextField(
            controller: _newPassCtrl,
            obscureText: _hideNewPass,
            style: TextStyle(fontSize: 14, color: theme.onSurface),
            decoration: _dec(context, '••••••••', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _hideNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: theme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _hideNewPass = !_hideNewPass),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Confirm New Password',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.onSurface)),
          const SizedBox(height: 6),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: _hideConfirmPass,
            style: TextStyle(fontSize: 14, color: theme.onSurface),
            decoration: _dec(context, '••••••••', Icons.lock_outline_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _hideConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18, color: theme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _hideConfirmPass = !_hideConfirmPass),
              ),
            ),
          ),
          // ─────────────────────────────────────────────────────────────────
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: _white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: theme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700, color: theme.onSurface)),
                    content: Text('Are you sure you want to log out?', style: TextStyle(color: theme.onSurfaceVariant)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: TextStyle(color: theme.onSurfaceVariant))),
                      ElevatedButton(
                        onPressed: () { Navigator.pop(ctx); widget.onLogout(); },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
              label: const Text('Log Out',
                  style: TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STAT CARD ───────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _blue)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: theme.onSurfaceVariant, height: 1.3)),
        ]),
      ),
    );
  }
}

// ─── SECTION TITLE ───────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onAction;
  final void Function(BuildContext)? onActionWithContext;
  final VoidCallback? onTapWhileDeleteMode;

  const _SectionTitle(this.title, {
    required this.buttonLabel,
    required this.onAction,
    this.onActionWithContext,
    this.onTapWhileDeleteMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context).colorScheme;
    final sw     = MediaQuery.of(context).size.width;
    final is3dot = buttonLabel == '···';
    return Padding(
      padding: EdgeInsets.fromLTRB(sw * 0.05, 22, sw * 0.05, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.onSurface)),
          Builder(builder: (ctx) {
            return Material(
              color: _blue, borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  if (onTapWhileDeleteMode != null) {
                    onTapWhileDeleteMode!();
                  } else if (onActionWithContext != null)  onActionWithContext!(ctx);
                  else                                   onAction();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: is3dot ? 10 : 14, vertical: 6),
                  child: Text(buttonLabel, style: TextStyle(
                      fontSize: is3dot ? 16 : 12, color: _white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: is3dot ? 1.5 : 0)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── WHITE CARD ──────────────────────────
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

// ─── RIPPLE ICON BUTTON ──────────────────
class _RippleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RippleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Material(
      color: theme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12),
      elevation: 2, shadowColor: _blue.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12), onTap: onTap,
        child: SizedBox(width: 38, height: 38, child: Icon(icon, color: theme.onSurface, size: 20)),
      ),
    );
  }
}

// ─── RIPPLE ACTION BUTTON ────────────────
class _RippleActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RippleActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
    child: InkWell(
      borderRadius: BorderRadius.circular(8), onTap: onTap,
      child: SizedBox(width: 32, height: 32, child: Icon(icon, size: 16, color: color)),
    ),
  );
}

// ─── BOTTOM NAV ──────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceContainerHighest,
        boxShadow: [BoxShadow(color: _blue.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,          label: 'Home',        active: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.work_outline_rounded,  label: 'Internships', active: currentIndex == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.person_rounded,        label: 'Profile',     active: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.assignment_outlined,   label: 'Surveys',     active: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BLOB ────────────────────────────────
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

// ─── NAV ITEM ────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavItem({required this.icon, required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () {},
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: active ? _blue.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: active ? _blue : theme.onSurfaceVariant, size: 22),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10,
            color: active ? _blue : theme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ]),
    );
  }
}