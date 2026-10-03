// «عملت إيه · وقت قد إيه · حرقت كام» — ورقة تسجيل التمرينة.
//
// الأزرار الجاهزة بتغطّى اللى بتكرّره، ودى بتغطّى اللى مش متكرّر: تمرينة
// باسمها، ومدّتها، والسعرات اللى حرقتها لو تعرفها.
//
// السعرات هنا **محروقة** — مش اللى أكلته. الاتنين رقم بالسعرات واسمه
// واحد، فالخانة بتقول «حرقت» صراحةً عشان محدش يسجّل أكله هنا.
import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/day_log.dart';

/// بتفتح الورقة وبترجّع رقم الصف المتسجّل (عشان «تراجع»)، أو null لو لغى.
Future<int?> showExerciseSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom),
      child: const _ExerciseForm(),
    ),
  );
}

/// الفورم لوحده — عشان أدوات اللقطات والمسح تبنيه من غير ما تفتح ورقة
/// سفلية (الورقة السفلية مابتترسمش فى لقطة ثابتة).
Widget exerciseFormBody() => const _ExerciseForm();

/// اقتراحات سريعة لخانة «عملت إيه» — بتملى الخانة، مش بتسجّل.
const List<String> _kinds = [
  'مشى',
  'جيم',
  'جرى',
  'عجل',
  'سباحة',
  'كورة',
  'تمارين بيت',
  'إطالة',
];

class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm();

  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  final _what = TextEditingController();
  final _minutes = TextEditingController();
  final _calories = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _what.dispose();
    _minutes.dispose();
    _calories.dispose();
    super.dispose();
  }

  /// الحفظ بيحتاج **الاسم والمدة** بس — السعرات اختيارية لإن أغلب الناس
  /// مابتعرفهاش، ولو كانت إجبارية الناس هتخمّن رقم وتبوّظ المجموع.
  bool get _valid =>
      _what.text.trim().isNotEmpty && (int.tryParse(_minutes.text.trim()) ?? 0) > 0;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final id = await DayLog.logExercise(
      ExercisePreset(_what.text.trim(), int.parse(_minutes.text.trim())),
      calories: int.tryParse(_calories.text.trim()) ?? 0,
    );
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 14),
            Text(tr('سجّل تمرينة', 'Log a workout'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: _what,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr('عملت إيه؟', 'What did you do?'),
                hintText: tr('مشى · جيم · كورة…', 'Walk · gym · football…'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in _kinds)
                  ActionChip(
                    label: Text(k, style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => setState(() {
                      _what.text = k;
                      _what.selection =
                          TextSelection.collapsed(offset: k.length);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: tr('وقت قد إيه؟', 'How long?'),
                    // الوحدة فى السطر المساعد مش فى `suffixText`: الـsuffix
                    // مابيبانش والخانة فاضية — يعنى بالظبط وقت ما محتاج
                    // تعرف هتكتب إيه. والسطر ده بيخلّى الخانتين بنفس
                    // الطول كمان.
                    helperText: tr('بالدقيقة', 'minutes'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _calories,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: tr('حرقت كام؟', 'Calories burned?'),
                    helperText: tr('سعرة · اختيارى', 'kcal · optional'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            // أكتر مدة بتتسجّل — دوسة بتملى الخانة بدل الكتابة.
            Wrap(
              spacing: 6,
              children: [
                for (final m in const [15, 30, 45, 60])
                  ActionChip(
                    label: Text(tr('${arNum(m)} د', '${arNum(m)}m'),
                        style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => setState(() {
                      _minutes.text = '$m';
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _valid && !_saving ? _save : null,
                child: Text(tr('حفظ', 'Save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
