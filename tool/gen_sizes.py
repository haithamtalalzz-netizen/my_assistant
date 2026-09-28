"""يولّد «مسح المقاسات»: كل شاشة × ٦ مقاسات (موبايل صغير → تابلت كبير).

تجاوز الحدود (overflow) بيتبلّغ كاستثناء رسم، فالأداة بتمسكه بمكانه فى الكود —
ودى الحاجة اللى مابتظهرش فى سجلّ ولا فى اختبار وظيفى: الشاشة «شغّالة»
والكلام مقصوص.
"""
import io
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
SEP = os.sep

# الشاشتين دول بيحمّلوا أصل ضخم بمؤشّر لانهائى — بيسمّموا اللى بعدهم
# بيحمّلوا أصل ضخم بمؤشّر لانهائى بيسمّم اللى بعدهم (جُرِّب: ٥٢ فشل).
# متغطّيين لوحدهم فى tool/mushaf_sizes_test.dart.
SKIP = {'MushafScreen', 'MushafPageScreen'}

entries = []
for root, _, files in os.walk('lib/screens'):
    for f in files:
        if not f.endswith('.dart'):
            continue
        p = os.path.join(root, f).replace(SEP, '/')
        s = io.open(p, encoding='utf-8').read()
        for m in re.finditer(
                r'^class ([A-Z][A-Za-z0-9_]*) extends (Stateless|Stateful)Widget',
                s, re.M):
            cls = m.group(1)
            cm = re.search(r'\n\s*const %s\(([^)]*)\)' % re.escape(cls), s)
            if not cm:
                cm = re.search(r'\n\s*%s\(([^)]*)\)' % re.escape(cls), s)
            args = cm.group(1) if cm else ''
            if 'required' in args or cls in SKIP:
                continue
            const = bool(cm and ('const %s(' % cls) in cm.group(0))
            entries.append((cls, p, const))

entries.sort()
seen = {}
uniq = []
for cls, p, const in entries:
    pref = 'w%d' % len(uniq) if cls in seen else None
    seen[cls] = p
    uniq.append((cls, p, const, pref))

imports = {}
for cls, p, const, pref in uniq:
    imports.setdefault(p, pref)

imp_lines = []
for p in sorted(imports):
    pref = imports[p]
    lib = 'package:my_assistant/%s' % p[len('lib/'):]
    imp_lines.append("import '%s'%s;" % (lib, (' as %s' % pref) if pref else ''))

test_lines = []
for cls, p, const, pref in uniq:
    name = cls if not pref else '%s (%s)' % (cls, p.split('/')[-2])
    ctor = '%s%s%s()' % ('const ' if const else '',
                         ('%s.' % pref) if pref else '', cls)
    test_lines.append(
        "  testWidgets('%s', (t) => sweep(t, () => %s));" % (name, ctor))

TEMPLATE = r'''// **مولَّد** — كل شاشة × ٦ مقاسات (موبايل صغير → تابلت كبير).
// الغرض: **مفيش حاجة مقصوصة** على أى مقاس. تجاوز الحدود بيتبلّغ كاستثناء
// رسم فبيتمسك هنا بمكانه فى الكود؛ الاختبار الوظيفى مابيشوفهوش.
//   flutter test tool/sizes_test.dart
// التوليد: tool/gen_sizes.py
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/seed_demo.dart';
import 'package:my_assistant/core/theme.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'shot_harness.dart';
__IMPORTS__

/// مقاسات حقيقية: أصغر أندرويد شائع → تابلت كبير بالعرض.
const _sizes = <String, Size>{
  'موبايل صغير 320': Size(320, 640),
  'موبايل عادى 360': Size(360, 800),
  'موبايل كبير 414': Size(414, 896),
  'فولد مفتوح 673': Size(673, 841),
  'تابلت 800': Size(800, 1280),
  'تابلت كبير 1024': Size(1024, 1366),
};

bool _ignorable(Object ex) {
  final s = ex.toString();
  return s.contains('MissingPluginException') ||
      s.contains('Looking up a deactivated') ||
      s.contains('HttpException') ||
      s.contains('Invalid image data');
}

/// بيطلّع من تقرير الخطأ: نوع القصّ + **مكانه فى الكود**.
String _brief(FlutterErrorDetails d) {
  final s = d.toString();
  final of =
      RegExp(r'overflowed by ([\d.]+) pixels on the (\w+)').firstMatch(s);
  final loc =
      RegExp(r'file:///[^\s]*/lib/([^\s:]+\.dart):(\d+)').firstMatch(s);
  final where = loc == null ? '?' : 'lib/${loc.group(1)}:${loc.group(2)}';
  if (of != null) return 'قصّ ${of.group(1)}px ${of.group(2)} @ $where';
  return '${d.exception.toString().split("\n").first} @ $where';
}

/// بيدوّر على **نصّ اتخنق لحد ما بقى غير مرئى** — عرضه ≈ صفر وهو محتاج
/// عرض. ده بيحصل لمّا شريط العنوان يبقى فيه أزرار كتير فالعنوان مايلاقيش
/// مكان خالص (اتأكّدت بالصورة: «الجيم» كان مختفى تمامًا على ٣٢٠ ورا ٦ أيقونات).
///
/// ⚠️ جرّبت قبل كده أبلّغ عن أى نصّ `didExceedMaxLines` — طلع **كاذب**:
/// بيبلّغ عن «التنبيهات» و«عدد» وهُمّ ظاهرين تمام (الصور أثبتت). السبب إن
/// `InputDecorator` و`AppBar` بيقيسوا النصّ فى صناديق ضيّقة أثناء التخطيط.
/// القاعدة الوحيدة اللى صمدت قدام الصور هى «العرض ≈ صفر».
List<String> _truncatedShort(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize) continue;
    final needed = ro.getMaxIntrinsicWidth(double.infinity);
    if (needed < 4 || ro.size.width >= 4) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    out.add('نصّ مخفى (عرضه صفر): «$txt»');
  }
  return out.toList();
}

/// بيدوّر على **نصّ متقصوص من فوق/تحت** — صندوقه أقصر من اللى محتاجه.
/// نوع تالت من القصّ، و**مابيظهرش من غير خطّ التطبيق** (بيئة الاختبار
/// بتقيس العربى بخطّ مقاساته مختلفة).
List<String> _vClipped(WidgetTester tester) {
  final out = <String>{};
  for (final ro in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!ro.hasSize || ro.size.width < 1) continue;
    // 🔴 القاعدة الوحيدة اللى مافيهاش لبس: **الصندوق أقصر من سطر واحد**،
    // يعنى النصّ مستحيل يبان كامل مهما كان.
    //
    // جرّبت الأوسع منها مرّتين وكانت بتكذب: `getMaxIntrinsicHeight`
    // بترجّع ارتفاع أقصى عدد سطور مسموح، و`TextPainter` بعرض الصندوق
    // بيحسب اللفّ — والاتنين بلّغوا عن كروت اللوحة وعناوين الشاشات وهى
    // ظاهرة تمام (الصور أثبتت). ده كان بيطلّع ١٣ بلاغ أغلبها كاذب.
    final line = TextPainter(
      text: ro.text,
      textDirection: ro.textDirection,
      maxLines: 1,
      textScaler: ro.textScaler,
    )..layout();
    if (ro.size.height >= line.height - 0.5) continue;
    final txt = ro.text.toPlainText().trim().replaceAll('\n', ' ');
    if (txt.isEmpty) continue;
    out.add('نصّ متقصوص طولاً (${ro.size.height.round()} من '
        '${line.height.round()}): «$txt»');
  }
  return out.toList();
}

void main() {
  sqfliteFfiInit();
  // ضغطة على «النسخة الاحتياطية» بتفتح القاعدة **بمسارها** مش عبر
  // `AppDb`، فبيئة الاختبار لازم يبقى فيها مصنع ومجلّد — نقص فى البيئة
  // مش عطب فى التطبيق.
  databaseFactory = databaseFactoryFfiNoIsolate;
  Directory('.dart_tool/sqflite_common_ffi/databases')
      .createSync(recursive: true);
  late Database db;

  setUpAll(() async {
    // من غير خطّ التطبيق، قياس العربى بيكذب (شوف `_vClipped`).
    await loadShotFonts();
    await initializeDateFormatting('ar');
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false));
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
    await seedDemoData();
  });

  tearDownAll(() async {
    AppDb.reset();
    await db.close();
  });

  /// بيرسم الشاشة على كل المقاسات ويجمع كل قصّ بمكانه.
  Future<void> sweep(WidgetTester tester, Widget Function() build) async {
    final found = <String, List<String>>{};
    for (final e in _sizes.entries) {
      final errs = <String>[];
      final prev = FlutterError.onError;
      // بنلقط الأخطاء بنفسنا عشان نشوف **كلها** مش أول واحد بس.
      FlutterError.onError = (d) {
        if (!_ignorable(d.exception)) errs.add(_brief(d));
      };
      tester.takeException();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      try {
        await tester.pumpWidget(MaterialApp(
          theme: buildTheme(),
          locale: const Locale('ar'),
          home: Directionality(
              textDirection: TextDirection.rtl, child: build()),
        ));
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        errs.addAll(_truncatedShort(tester));
        errs.addAll(_vClipped(tester));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 150));
      } finally {
        FlutterError.onError = prev;
        tester.takeException();
      }
      for (final m in errs.toSet()) {
        found.putIfAbsent(m, () => <String>[]).add(e.key);
      }
    }
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    if (found.isNotEmpty) {
      fail(found.entries
          .map((x) => '${x.key}   [${x.value.join(" · ")}]')
          .join('\n'));
    }
  }

__TESTS__
}
'''

out = (TEMPLATE
       .replace('__IMPORTS__', '\n'.join(imp_lines))
       .replace('__TESTS__', '\n'.join(test_lines)))
io.open('tool/sizes_test.dart', 'w', encoding='utf-8', newline='\n').write(out)
print('عدد الشاشات:', len(uniq), '× 6 مقاسات')
