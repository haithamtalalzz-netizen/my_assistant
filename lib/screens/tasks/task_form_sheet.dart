import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/tasks_repo.dart';
import '../../models/models.dart';

/// أسماء الأولوية — نسخة واحدة يستعملها الفورم وشاشة المهام.
String taskPriorityLabel(int p) => switch (p) {
      0 => tr('منخفضة', 'Low'),
      2 => tr('عالية', 'High'),
      _ => tr('عادية', 'Normal'),
    };

String taskRepeatLabel(String rule) => switch (rule) {
      'daily' => tr('يومى', 'Daily'),
      'weekly' => tr('أسبوعى', 'Weekly'),
      'monthly' => tr('شهرى', 'Monthly'),
      _ => tr('بدون', 'None'),
    };

/// **فورم المهمة** — كان محبوس جوّه `TasksScreen` كدالة خاصة، فزرار
/// «＋ مهمة» فى «خط اليوم» ماكانش يقدر يوصّله إلا إنه يوديك لشاشة
/// المهام وتدوس ＋ تانى.
///
/// اتنقل هنا عشان الاتنين يستعملوا **نسخة واحدة**: لو اتكتب مرتين
/// هيفرق مرة، وساعتها نفس الزرار فى شاشتين يعمل حاجتين.
///
/// بيرجّع true لو المهمة اتحفظت.
Future<bool> openTaskForm(
  BuildContext context, {
  Task? task,
  int? defaultProjectId,
  DateTime? defaultDue,
  List<Project> projects = const [],
}) async {
  final repo = TasksRepo();
  final title = TextEditingController(text: task?.title ?? '');
  final notes = TextEditingController(text: task?.notes ?? '');
  var priority = task?.priority ?? 1;
  var projectId = task?.projectId ?? defaultProjectId;
  var repeatRule = task?.repeatRule ?? '';
  DateTime? due = task?.due ?? defaultDue;

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(task == null
              ? tr('مهمة جديدة', 'New task')
              : tr('تعديل مهمة', 'Edit task')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: title,
                autofocus: task == null,
                decoration: InputDecoration(labelText: tr('العنوان', 'Title')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: InputDecoration(
                    labelText: tr('ملاحظات (اختيارى)', 'Notes (optional)')),
              ),
              const SizedBox(height: 14),
              Text(tr('الأولوية', 'Priority'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                for (var p = 0; p <= 2; p++)
                  ChoiceChip(
                    label: Text(taskPriorityLabel(p)),
                    selected: priority == p,
                    onSelected: (_) => setD(() => priority = p),
                  ),
              ]),
              if (projects.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(tr('المشروع', 'Project'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Wrap(spacing: 6, children: [
                  ChoiceChip(
                    label: Text(tr('بدون', 'None')),
                    selected: projectId == null,
                    onSelected: (_) => setD(() => projectId = null),
                  ),
                  for (final p in projects)
                    ChoiceChip(
                      label: Text(p.name),
                      selected: projectId == p.id,
                      onSelected: (_) => setD(() => projectId = p.id),
                    ),
                ]),
              ],
              const SizedBox(height: 14),
              Text(tr('التكرار', 'Repeat'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(spacing: 6, children: [
                for (final r in const ['', 'daily', 'weekly', 'monthly'])
                  ChoiceChip(
                    label: Text(taskRepeatLabel(r)),
                    selected: repeatRule == r,
                    onSelected: (_) => setD(() => repeatRule = r),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Text(
                      due == null
                          ? tr('من غير ميعاد', 'No due date')
                          : arDateTime(due!),
                      style: const TextStyle(fontSize: 12.5)),
                ),
                if (due != null)
                  IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setD(() => due = null)),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(tr('موعد', 'Due')),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: due ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d == null) return;
                    if (!ctx.mounted) return;
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(due ?? DateTime.now()),
                    );
                    setD(() => due = DateTime(
                        d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0));
                  },
                ),
              ]),
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
      ),
    );

    if (saved != true || title.text.trim().isEmpty) return false;
    await repo.save(Task(
      id: task?.id,
      projectId: projectId,
      title: title.text.trim(),
      notes: notes.text.trim(),
      dueAt: due?.toIso8601String(),
      priority: priority,
      done: task?.done ?? false,
      doneAt: task?.doneAt,
      repeatRule: repeatRule,
      createdAt: task?.createdAt ?? DateTime.now().toIso8601String(),
    ));
    return true;
  } finally {
    // 🔴 فى `finally`: لو الحوار اتقفل بضغطة رجوع أو حصل خطأ جوّه
    // الحفظ، الـcontrollers كانت هتفضل شايلة ذاكرة.
    title.dispose();
    notes.dispose();
  }
}
