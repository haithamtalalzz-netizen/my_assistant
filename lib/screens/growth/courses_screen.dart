import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/courses_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// التعلّم — كورسات/دورات بتتبّع تقدّم بالوحدات.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

String _statusLabel(String s) => switch (s) {
      'done' => tr('مكتمل', 'Done'),
      'paused' => tr('متوقّف', 'Paused'),
      _ => tr('جارٍ', 'Active'),
    };

class _CoursesScreenState extends State<CoursesScreen> {
  final _repo = CoursesRepo();
  bool _loading = true;
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final courses = await _repo.all();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('التعلّم', 'Learning'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _courses.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.school_outlined,
                          text: tr('ضيف كورس بتتعلّمه بزرار +',
                              'Add a course with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [for (final c in _courses) _card(c)],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _form(),
        tooltip: tr('كورس جديد', 'New course'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _card(Course c) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.status == 'done' ? scheme.outline : null)),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') await _form(c);
                    if (v == 'delete') {
                      await _repo.delete(c.id!);
                      await _load();
                    }
                    if (v == 'active' || v == 'paused' || v == 'done') {
                      await _repo.setStatus(c.id!, v);
                      await _load();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'active', child: Text(tr('جارٍ', 'Active'))),
                    PopupMenuItem(value: 'paused', child: Text(tr('متوقّف', 'Paused'))),
                    PopupMenuItem(value: 'done', child: Text(tr('مكتمل', 'Done'))),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
                    PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
                  ],
                ),
              ],
            ),
            if (c.provider.isNotEmpty)
              Text(c.provider,
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: c.progress, minHeight: 7),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                    c.totalUnits == 0
                        ? _statusLabel(c.status)
                        : tr('${arNum(c.doneUnits)}/${arNum(c.totalUnits)} · ${_statusLabel(c.status)}',
                            '${arNum(c.doneUnits)}/${arNum(c.totalUnits)} · ${_statusLabel(c.status)}'),
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
                const Spacer(),
                if (c.totalUnits > 0) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    onPressed: () async {
                      await _repo.bumpProgress(c, -1);
                      await _load();
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle, size: 22),
                    onPressed: () async {
                      await _repo.bumpProgress(c, 1);
                      await _load();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _form([Course? course]) async {
    final title = TextEditingController(text: course?.title ?? '');
    final provider = TextEditingController(text: course?.provider ?? '');
    final total = TextEditingController(
        text: course == null || course.totalUnits == 0 ? '' : '${course.totalUnits}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(course == null ? tr('كورس جديد', 'New course') : tr('تعديل', 'Edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: title,
                autofocus: course == null,
                decoration: InputDecoration(labelText: tr('اسم الكورس', 'Course title'))),
            const SizedBox(height: 8),
            TextField(
                controller: provider,
                decoration: InputDecoration(
                    labelText: tr('الجهة (يوديمي، يوتيوب…)', 'Provider'))),
            const SizedBox(height: 8),
            TextField(
                controller: total,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: tr('عدد الدروس/الوحدات', 'Total units'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );

    if (saved == true && title.text.trim().isNotEmpty) {
      await _repo.save(Course(
        id: course?.id,
        title: title.text.trim(),
        provider: provider.text.trim(),
        totalUnits: int.tryParse(toEnglishDigits(total.text.trim())) ?? 0,
        doneUnits: course?.doneUnits ?? 0,
        status: course?.status ?? 'active',
        notes: course?.notes ?? '',
        createdAt: course?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    title.dispose();
    provider.dispose();
    total.dispose();
  }
}
