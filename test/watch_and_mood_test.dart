// تنبيه بيقول الحاجة · مزاج من الإشعار · زرار الرجوع.
//
// الخيط اللى بيجمعهم: شاشة الساعة بتوريك **سطر**. فالعنوان لازم يقول
// الحاجة نفسها، والفعل لازم يتعمل من غير ما التطبيق يتفتح.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_assistant/core/ar.dart';
import 'package:my_assistant/core/db.dart';
import 'package:my_assistant/core/mood_reminder.dart';
import 'package:my_assistant/core/notifications.dart';
import 'package:my_assistant/data/mood_repo.dart';
import 'package:my_assistant/data/settings_repo.dart';
import 'package:my_assistant/screens/habits/habits_screen.dart';
import 'package:my_assistant/screens/shell.dart';
import 'package:my_assistant/screens/today_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io';

void main() {
  sqfliteFfiInit();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfiNoIsolate.openDatabase(inMemoryDatabasePath);
    await AppDb.createSchema(db, 1);
    AppDb.useForTests(db);
  });

  tearDown(() async {
    AppDb.reset();
    await db.close();
  });

  group('عنوان الإشعار بيقول الحاجة', () {
    test('titleLine بتقصّ عند كلمة كاملة', () {
      expect(Notifications.titleLine('ادفع النور'), 'ادفع النور');
      final long = Notifications.titleLine(
          'ادفع فاتورة النور قبل يوم الخميس وإلا هيقطعوا الكهربا عن الشقة');
      expect(long.endsWith('…'), isTrue);
      expect(long.length, lessThanOrEqualTo(43));
      // ما بيقسمش كلمة نُصّين.
      expect(long.replaceAll('…', '').trim().split(' ').last, isNot('الخم'));
    });

    test('السطر الواحد: الأسطر بتبقى مسافات', () {
      expect(Notifications.titleLine('سطر\nتانى'), 'سطر تانى');
    });

    test('مفيش إشعار عنوانه كلمة عامة', () async {
      // الحارس الحقيقى: «تذكير» و«مهمة مستحقة» و«صلة رحم» عناوين
      // مابتقولش إيه ولا مين — على الساعة دى كل اللى هتشوفه.
      const banned = [
        "'تذكير'",
        "'تذكير يومى'",
        "tr('تذكير', 'Reminder')",
        "tr('مهمة مستحقة', 'Task due')",
        "tr('صلة رحم', 'Keep in touch')",
        "tr('قرب موعد تطعيم', 'Vaccine due soon')",
        "tr('اسقي النبات 🪴', 'Water your plant 🪴')",
        "tr('كورس الدوا خلص', 'Medication course ended')",
      ];
      final offenders = <String>[];
      for (final f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = f.readAsStringSync();
        for (final b in banned) {
          if (src.contains('title: $b')) offenders.add('${f.path}: $b');
        }
      }
      expect(offenders, isEmpty,
          reason: 'عنوان عام على شاشة ساعة = إشعار مالوش معنى');
    });
  });

  group('المزاج من الإشعار', () {
    test('دوسة وش بتسجّل الدرجة', () async {
      expect(await MoodReminder.applyAction(MoodReminder.actionId(5)), isTrue);
      final today = await MoodRepo().forDay(dayKey(DateTime.now()));
      expect(today!.score, 5);
    });

    test('دوسة تانية بتعدّل نفس اليوم مش بتضيف صف', () async {
      await MoodReminder.applyAction(MoodReminder.actionId(1));
      await MoodReminder.applyAction(MoodReminder.actionId(3));
      final rows = await MoodRepo().recent();
      expect(rows.length, 1);
      expect(rows.single.score, 3);
    });

    test('الملاحظة المكتوبة مابتتمسحش بدوسة وش', () async {
      // كتب ملاحظة الصبح، ودوس وش بالليل — الملاحظة تفضل.
      await MoodRepo().setToday(2, note: 'يوم تقيل');
      await MoodReminder.applyAction(MoodReminder.actionId(5));
      final today = await MoodRepo().forDay(dayKey(DateTime.now()));
      expect(today!.score, 5);
      expect(today.note, 'يوم تقيل');
    });

    test('زرار مش بتاع المزاج مابيعملش حاجة', () async {
      expect(await MoodReminder.applyAction('note_done'), isFalse);
      expect(await MoodReminder.applyAction('mood_9'), isFalse);
      expect(await MoodReminder.applyAction('mood_x'), isFalse);
      expect(await MoodRepo().recent(), isEmpty);
    });

    test('تلات وشوش بس — أندرويد مابيعرضش أكتر', () {
      expect(MoodReminder.faces.length, 3);
      expect(MoodReminder.actions.length, 3);
      // الطرفين والنُص: ١ · ٣ · ٥.
      expect([for (final (s, _) in MoodReminder.faces) s], [1, 3, 5]);
    });

    test('مقفول افتراضيًا — تنبيه جديد مايفتحش نفسه', () async {
      expect(await MoodReminder.isEnabled(), isFalse);
      await SettingsRepo().set(MoodReminder.enabledKey, '1');
      expect(await MoodReminder.isEnabled(), isTrue);
    });

    test('الميعاد الافتراضى ٢١:٠٠ والمحفوظ بيتقرا', () async {
      expect(await MoodReminder.timeOf(), (21, 0));
      await SettingsRepo().set(MoodReminder.timeKey, '08:30');
      expect(await MoodReminder.timeOf(), (8, 30));
      // أرقام عربية برضه (المستخدم ممكن يكتبها كده).
      await SettingsRepo().set(MoodReminder.timeKey, '٠٧:١٥');
      expect(await MoodReminder.timeOf(), (7, 15));
    });
  });

  group('زرار الرجوع', () {
    /// بيقلّد دوسة زرار الرجوع بتاع النظام.
    Future<void> pressBack(WidgetTester tester) async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    testWidgets('من تبويب تانى بيرجّع للرئيسية مش بيقفل', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('ar')],
        home: Shell(),
      ));
      await tester.pumpAndSettle();

      // بندخل تبويب «العادات» (٣) من نفس النداء اللى السايدبار بيستخدمه.
      tester.widget<TodayScreen>(find.byType(TodayScreen)).onGoToTab!(3);
      await tester.pumpAndSettle();
      expect(find.byType(HabitsScreen), findsOneWidget);

      await pressBack(tester);

      // الرجوع رجّعنا للرئيسية — مارماش التطبيق بره.
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(find.byType(HabitsScreen), findsNothing);
      // ومافيش سؤال خروج: احنا مارجعناش من الرئيسية.
      expect(find.text('تقفل Vida؟'), findsNothing);
    });

    testWidgets('من الرئيسية بيسأل الأول', (tester) async {
      // بنمسك نداء إغلاق التطبيق عشان ما يقفلش الاختبار نفسه.
      var popped = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.pop') popped++;
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('ar')],
        home: Shell(),
      ));
      await tester.pumpAndSettle();

      await pressBack(tester);
      // السؤال ظهر، والتطبيق **لسه مافتقفلش**.
      expect(find.text('تقفل Vida؟'), findsOneWidget);
      expect(popped, 0);

      await tester.tap(find.text('أفضل فيه'));
      await tester.pumpAndSettle();
      expect(popped, 0, reason: '«أفضل فيه» يعنى ما تقفلش');
    });
  });
}
