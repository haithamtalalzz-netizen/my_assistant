import '../data/bills_repo.dart';
import '../data/lab_results_repo.dart';
import '../data/occasions_repo.dart';
import '../data/vaccinations_repo.dart';
import 'ar.dart';
import 'l10n.dart';
import 'log.dart';

/// اقتراحات سياقية من بيانات المستخدم نفسه — بتتحقن فى الموجز الصباحى
/// وبريفينج «اسأل مديرك». طبقة core من غير ودجت عشان تتختبر.
/// بترجع لحد [max] جُمل، الأهم الأول (فواتير مستحقة → تطعيمات → مناسبات
/// → تحاليل خارج النطاق). كل قسم بيفشل بيتعدّى بدل ما يكسر الموجز.
Future<List<String>> contextualTips({DateTime? at, int max = 3}) async {
  final now = at ?? DateTime.now();
  final tips = <String>[];

  // فواتير مستحقة النهارده أو متأخرة.
  try {
    final due = await BillsRepo().due(now);
    for (final b in due.take(2)) {
      tips.add(tr('🧾 فاتورة «${b.name}» مستحقة — ${egp(b.amount)}.',
          '🧾 Bill "${b.name}" is due — ${egp(b.amount)}.'));
    }
  } on Exception catch (e, st) {
    logError('فشل اقتراح الفواتير المستحقة', e, st);
  }

  // تطعيمات جرعتها الجاية خلال أسبوع.
  try {
    final vax = await VaccinationsRepo().dueSoon(days: 7);
    for (final v in vax.take(1)) {
      final who = v.person.isEmpty ? '' : ' (${v.person})';
      final d = DateTime.tryParse(v.nextDue);
      final when = d == null ? v.nextDue : arShortDate(d);
      tips.add(tr('💉 تطعيم «${v.name}»$who جرعته الجاية $when.',
          '💉 Vaccination "${v.name}"$who next dose $when.'));
    }
  } on Exception catch (e, st) {
    logError('فشل اقتراح التطعيمات', e, st);
  }

  // مناسبات قرّبت (جوه نافذة التذكير بتاعتها).
  try {
    final occ = await OccasionsRepo().upcomingWithinWindow(now);
    for (final o in occ.take(1)) {
      final days = o.nextOccurrence(now).difference(dateOnly(now)).inDays;
      final when = days <= 0
          ? tr('النهارده', 'today')
          : days == 1
              ? tr('بكرة', 'tomorrow')
              : tr('بعد ${arNum(days)} أيام', 'in ${arNum(days)} days');
      tips.add(tr('🎉 «${o.title}» $when — جهّز نفسك.',
          '🎉 "${o.title}" $when — get ready.'));
    }
  } on Exception catch (e, st) {
    logError('فشل اقتراح المناسبات', e, st);
  }

  // تحاليل آخر نتيجتها خارج النطاق.
  try {
    final n = await LabResultsRepo().outOfRangeCount();
    if (n > 0) {
      tips.add(tr(
          '🧪 عندك ${arNum(n)} نتيجة تحاليل خارج النطاق — راجعها مع دكتورك.',
          '🧪 ${arNum(n)} lab results out of range — review with your doctor.'));
    }
  } on Exception catch (e, st) {
    logError('فشل اقتراح التحاليل', e, st);
  }

  return tips.take(max).toList();
}
