import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../data/health_repo.dart';
import '../data/measurements_repo.dart';
import '../models/models.dart';

/// ورقة تسجيل قياس (وزن · ضغط · سكر · حرارة).
///
/// اتنقلت هنا عشان «لوحة الصحة» و«صحتى» يستخدموها **من نسخة واحدة**:
/// لو اتكتبت مرتين هتفرق مرة، وساعتها نفس الزرار فى شاشتين يعمل حاجتين.
///
/// بترجّع true لو اتسجّل قياس فعلاً.
Future<bool> openMeasurementSheet(BuildContext context, String type) async {
  final v1 = TextEditingController();
  final v2 = TextEditingController();
  try {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 4,
              bottom: 20 +
                  MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).viewPadding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.monitor_heart_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Text(tr('تسجيل $type', 'Log $type'),
                    style: Theme.of(ctx).textTheme.titleMedium),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: v1,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: type == 'ضغط'
                            ? tr('الانقباضي', 'Systolic')
                            : tr('القيمة', 'Value')),
                  ),
                ),
                if (type == 'ضغط') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: v2,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: tr('الانبساطي', 'Diastolic')),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(tr('حفظ', 'Save'))),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return false;
    final a = parseNumber(v1.text);
    if (a == null) return false;
    await MeasurementsRepo().add(Measurement(
      day: dayKey(DateTime.now()),
      type: type,
      value: a,
      value2: type == 'ضغط' ? parseNumber(v2.text) : null,
    ));
    return true;
  } finally {
    // 🔴 الـcontrollers بتتمسح فى finally: لو الورقة اتقفلت بضغطة رجوع
    // أو حصل خطأ جوّه الحفظ كانت هتفضل شايلة ذاكرة من غير ما حد يعرف.
    v1.dispose();
    v2.dispose();
  }
}

/// ورقة تسجيل ساعات النوم — رقم واحد بس، فمالهاش لازمة تبقى شاشة.
Future<bool> openSleepSheet(BuildContext context) async {
  final c = TextEditingController();
  try {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 4,
            bottom: 20 +
                MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).viewPadding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Icon(Icons.bedtime_outlined,
                color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            Text(tr('نمت كام ساعة؟', 'Hours slept?'),
                style: Theme.of(ctx).textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                InputDecoration(labelText: tr('عدد الساعات', 'Hours')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ),
        ]),
      ),
    );
    if (ok != true) return false;
    final h = parseNumber(c.text);
    if (h == null || h <= 0) return false;
    await HealthRepo().setSleep(dayKey(DateTime.now()), h);
    return true;
  } finally {
    c.dispose();
  }
}
