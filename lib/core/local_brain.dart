// «عقل المدير» المجاني — بيجاوب أسئلة المستخدم من بياناته مباشرة على الجهاز،
// من غير أي إنترنت ولا مفتاح API. بيصنّف السؤال بقواعد كلمات مفتاحية (زي
// voice_parser) وبيرد بأرقام حقيقية من الـ repos. لو مافهمش السؤال بيرجّع
// handled=false فالشات يقرر يبعته لـ Gemini (لو المستخدم مفعّله) أو يعرض مساعدة.

import '../data/appointments_repo.dart';
import '../data/assets_repo.dart';
import '../data/bills_repo.dart';
import '../data/debts_repo.dart';
import '../data/docs_repo.dart';
import '../data/gameya_repo.dart';
import '../data/gym_repo.dart';
import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/home_maintenance_repo.dart';
import '../data/income_repo.dart';
import '../data/insights_repo.dart';
import '../data/meals_repo.dart';
import '../data/measurements_repo.dart';
import '../data/meds_repo.dart';
import '../data/money_repo.dart';
import '../data/occasions_repo.dart';
import '../data/pharmacy_repo.dart';
import '../data/plants_repo.dart';
import '../data/relatives_repo.dart';
import '../data/savings_repo.dart';
import '../data/settings_repo.dart';
import '../data/wallets_repo.dart';
import '../data/workout_repo.dart';
import 'ar.dart';
import 'insights.dart';
import 'l10n.dart';
import 'prayers.dart';
import 'weather.dart';

/// نتيجة سؤال: النص + هل اتعامل معاه محليًا ولا لأ.
typedef BrainReply = ({String text, bool handled});

class LocalBrain {
  /// يجاوب سؤال المستخدم من بياناته المحلية.
  static Future<BrainReply> answer(String raw) async {
    final t = _norm(raw);
    if (t.isEmpty) return (text: helpText(), handled: true);

    // ترحيب / مساعدة / قدرات.
    if (_has(t, [
      'ازيك', 'ازايك', 'اهلا', 'هاي', 'هلا', 'السلام', 'مرحبا', 'صباح', 'مساء',
      'help', 'مساعده', 'تعمل ايه', 'تقدر تعمل', 'ايه اللي تقدر', 'قدراتك',
      'بتعمل ايه', 'اسالك عن ايه'
    ])) {
      return (text: helpText(), handled: true);
    }

    // ملخص شامل ليومك (فلوس + مهام + صحة + تنبيهات).
    if (_has(t, [
      'ملخص', 'ملخصي', 'طمني', 'يومي كله', 'اليوم كله', 'عامل ايه انهارده',
      'اخر الاخبار', 'وريني كله', 'الوضع', 'اطمن'
    ])) {
      return (text: await _briefing(), handled: true);
    }

    // صافي الثروة (محافظ + أصول − ديون).
    if (_has(t, ['ثروتي', 'صافي ثروتي', 'ثروه', 'اصولي', 'صافي مالي', 'net worth'])) {
      return (text: await _netWorth(), handled: true);
    }

    // فلوس / رصيد / محافظ.
    if (_has(t, [
      'رصيد', 'رصيدي', 'محفظه', 'محفظتي', 'محافظي', 'محافظ', 'فلوسي',
      'فلوس معايا', 'معايا كام', 'كام معايا', 'معايا فلوس', 'عندي كام', 'كام عندي',
      'فلوس عندي', 'كاش'
    ])) {
      return (text: await _balance(), handled: true);
    }

    // مصاريف الشهر (بمقارنة بالشهر اللي فات).
    if (_has(t, [
      'صرفت', 'مصاريف', 'مصروف', 'مصروفاتي', 'مصاريفي', 'فلوس راحت', 'اتصرف',
      'صرفي', 'ميزانيتي', 'الميزانيه', 'اكتر ولا اقل', 'قارن', 'مقارنه',
      'الشهر اللي فات', 'الشهر الماضي'
    ])) {
      return (text: await _spending(), handled: true);
    }

    // دخل / صافي.
    if (_has(t, [
      'دخلي', 'دخل الشهر', 'قبضت', 'مرتبي', 'مرتب', 'الصافي', 'صافي الشهر',
      'وفرت', 'كسبت'
    ])) {
      return (text: await _income(), handled: true);
    }

    // ديون / سلف.
    if (_has(t, [
      'ديون', 'دين', 'عليا', 'عليّا', 'ليا', 'ليّا', 'سلف', 'سلفت', 'مديون',
      'مستحقات عليا', 'اللي عليا', 'اللي ليا'
    ])) {
      return (text: await _debts(), handled: true);
    }

    // ادخار / أهداف.
    if (_has(t, ['ادخار', 'اهداف', 'هدف الادخار', 'موفر', 'مدخر', 'هدفي'])) {
      return (text: await _savings(), handled: true);
    }

    // فواتير.
    if (_has(t, ['فواتير', 'فاتوره', 'مستحق', 'مستحقه', 'الكهربا', 'المياه فاتوره'])) {
      return (text: await _bills(), handled: true);
    }

    // جرعات النهاردة المتبقية.
    if (_has(t, ['خدت الدوا', 'جرعات النهارده', 'جرعه النهارده', 'الدوا انهارده', 'دوا الصبح', 'فاضل دوا', 'باقي الدوا'])) {
      return (text: await _medsToday(), handled: true);
    }

    // أدوية (بصيغة الملكية/الجمع — مش «عندي دوا»).
    if (_has(t, ['ادويتي', 'دوايا', 'الادويه', 'ادويه بتاخدها', 'العلاج بتاعي', 'جرعاتي', 'مواعيد الدوا'])) {
      return (text: await _meds(), handled: true);
    }

    // تمرين النهاردة / الجيم.
    if (_has(t, ['تمريني', 'تمرين النهارده', 'الجيم', 'برنامج التمرين', 'تماريني', 'الجيم النهارده'])) {
      return (text: await _gymToday(), handled: true);
    }

    // قايمة المشتريات.
    if (_has(t, ['مشتريات', 'لازم اشتري', 'قايمه الشراء', 'قائمه الشراء', 'اشتري ايه', 'قايمه المشتريات'])) {
      return (text: await _shopping(), handled: true);
    }

    // خطة باقي اليوم / المهام.
    if (_has(t, [
      'اعمل ايه', 'اعمل إيه', 'مهامي', 'يومي', 'برنامجي', 'خطتي', 'اللي عليا',
      'رتبلي', 'باقي اليوم', 'باقي النهارده', 'خطه', 'اعمل ايه النهارده'
    ])) {
      return (text: await _todayPlan(), handled: true);
    }

    // مواعيد.
    if (_has(t, ['مواعيد', 'مواعيدي', 'معاد', 'ميعاد', 'معادي', 'حاجه بكره', 'عندي بكره', 'اجندتي'])) {
      return (text: await _appointments(t), handled: true);
    }

    // عادات.
    if (_has(t, ['عاداتي', 'عادات', 'سلسله', 'سلسلتي', 'streak', 'التزامي'])) {
      return (text: await _habits(), handled: true);
    }

    // صحة النهاردة (مياه/نوم/خطوات).
    if (_has(t, [
      'نومي', 'نمت', 'نومت', 'المياه', 'شربت مياه', 'خطواتي', 'خطوات', 'صحتي',
      'حالتي النهارده'
    ])) {
      return (text: await _healthToday(), handled: true);
    }

    // قياسات (وزن/ضغط/سكر).
    if (_has(t, ['وزني', 'ضغطي', 'سكري', 'قياساتي', 'قياس', 'حرارتي'])) {
      return (text: await _measurements(), handled: true);
    }

    // مستندات.
    if (_has(t, ['مستنداتي', 'مستندات', 'بطاقتي', 'رخصتي', 'رخصه', 'جواز', 'وثايق', 'وثيقه'])) {
      return (text: await _docs(), handled: true);
    }

    // الصلاة — كل المواعيد لو طلبها، وإلا الجاية بس.
    if (_has(t, ['الصلوات', 'مواعيد الصلاه', 'كل الصلوات', 'اوقات الصلاه'])) {
      return (text: await _prayersAll(), handled: true);
    }
    if (_has(t, ['الصلاه', 'صلاه', 'اذان', 'الفرض', 'موعد الصلاه', 'الفجر', 'الضهر', 'العصر', 'المغرب', 'العشا'])) {
      return (text: await _prayer(), handled: true);
    }

    // الجمعية.
    if (_has(t, ['الجمعيه', 'جمعيه', 'جمعيتي', 'القسط'])) {
      return (text: await _gameya(), handled: true);
    }

    // مناسبات / أعياد ميلاد.
    if (_has(t, ['مناسبات', 'مناسبه', 'اعياد ميلاد', 'عيد ميلاد', 'مناسبات جايه', 'احتفال'])) {
      return (text: await _occasions(), handled: true);
    }

    // مين أتصل بيه (صلة رحم).
    if (_has(t, ['اتصل بمين', 'مين اتصل', 'صله رحم', 'قرايبي', 'اكلم مين', 'صلة الرحم'])) {
      return (text: await _relatives(), handled: true);
    }

    // صيانة البيت.
    if (_has(t, ['صيانه البيت', 'صيانه', 'الصيانه', 'محتاج صيانه'])) {
      return (text: await _maintenance(), handled: true);
    }

    // نباتات البيت.
    if (_has(t, ['نباتات', 'الزرع', 'ازرع', 'اسقي', 'نباتاتي'])) {
      return (text: await _plants(), handled: true);
    }

    // الطقس.
    if (_has(t, ['الجو', 'الطقس', 'درجه الحراره', 'الجو النهارده', 'الطقس النهارده', 'الجو عامل ايه'])) {
      return (text: await _weather(), handled: true);
    }

    // سعرات النهاردة / الأكل.
    if (_has(t, ['اكلت كام', 'سعرات', 'كام سعر', 'اكلي النهارده', 'كاليوري', 'سعراتي'])) {
      return (text: await _mealsToday(), handled: true);
    }

    // نصيحة / رؤى.
    if (_has(t, ['نصيحه', 'رايك', 'حللي', 'رؤى', 'رؤيه', 'اقتراح', 'انصحني', 'ملاحظاتك', 'ارقامي'])) {
      return (text: await _advice(), handled: true);
    }

    // «عندي/معايا <اسم دوا>» — بحث في صيدلية البيت (بعد استبعاد نية الفلوس).
    if (_has(t, ['عندي', 'عندى', 'معايا', 'عندك', 'عندنا', 'لقي', 'فاضل عندي'])) {
      final ph = await _pharmacy(t);
      if (ph != null) return (text: ph, handled: true);
    }

    // مش فاهم — نسيب الشات يقرر.
    return (text: '', handled: false);
  }

  // ---- المعالجات ----

  static Future<String> _balance() async {
    final list = await WalletsRepo().allWithBalances();
    if (list.isEmpty) {
      return tr(
          'لسه مسجلتش أي محفظة. افتح «المحفظة» وضيف كاش أو حساب بنك وأنا أقولك رصيدك في أي وقت.',
          "You haven't added any wallet yet. Open \"Wallet\" and add cash or a bank account and I'll track your balance.");
    }
    final total = list.fold<double>(0, (s, e) => s + e.balance);
    final b = StringBuffer();
    b.writeln(tr('إجمالي فلوسك: ${egp(total)}', 'Your total money: ${egp(total)}'));
    for (final e in list) {
      b.writeln('• ${e.wallet.name} (${walletTypeLabel(e.wallet.type)}): ${egp(e.balance)}');
    }
    return b.toString().trim();
  }

  static Future<String> _spending() async {
    final now = DateTime.now();
    final money = MoneyRepo();
    final total = await money.totalForMonth(now.year, now.month);
    final byCat = await money.byCategory(now.year, now.month);
    final budget = await SettingsRepo().monthlyBudget();
    // مقارنة بالشهر اللي فات (لحد نفس اليوم للعدل).
    final prev = DateTime(now.year, now.month - 1);
    final prevTotal = await money.totalForMonth(prev.year, prev.month);

    final b = StringBuffer();
    b.writeln(tr('مصاريف الشهر: ${egp(total)}', "This month's spending: ${egp(total)}"));
    if (prevTotal > 0) {
      final diff = total - prevTotal;
      final pct = (diff.abs() / prevTotal * 100).round();
      if (diff > 0) {
        b.writeln(tr('أكتر من الشهر اللي فات بـ ${egp(diff)} (+${arNum(pct)}%). صرفت وقتها ${egp(prevTotal)}.',
            'More than last month by ${egp(diff)} (+${arNum(pct)}%). You spent ${egp(prevTotal)} then.'));
      } else if (diff < 0) {
        b.writeln(tr('أقل من الشهر اللي فات بـ ${egp(-diff)} (−${arNum(pct)}%) — شغل نضيف 👍',
            'Less than last month by ${egp(-diff)} (−${arNum(pct)}%) — nice 👍'));
      } else {
        b.writeln(tr('زي الشهر اللي فات بالظبط.', 'Exactly the same as last month.'));
      }
    }
    if (budget > 0) {
      final left = budget - total;
      b.writeln(left >= 0
          ? tr('فاضل من ميزانيتك: ${egp(left)} من ${egp(budget)}',
              'Left in budget: ${egp(left)} of ${egp(budget)}')
          : tr('عدّيت ميزانيتك بـ ${egp(-left)} (الميزانية ${egp(budget)})',
              'Over budget by ${egp(-left)} (budget ${egp(budget)})'));
    }
    if (byCat.isNotEmpty) {
      final top = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      b.writeln(tr('أكتر بنود صرف:', 'Top categories:'));
      for (final e in top.take(3)) {
        b.writeln('• ${e.key}: ${egp(e.value)}');
      }
    }
    return b.toString().trim();
  }

  static Future<String> _netWorth() async {
    final cash = await WalletsRepo().totalBalance();
    final assets = await AssetsRepo().totalValue();
    final (owedToMe, iOwe) = await DebtsRepo().totals();
    final net = cash + assets + owedToMe - iOwe;
    final b = StringBuffer();
    b.writeln(tr('صافي ثروتك: ${egp(net)}', 'Your net worth: ${egp(net)}'));
    b.writeln(tr('• فلوس (محافظ): ${egp(cash)}', '• Cash (wallets): ${egp(cash)}'));
    if (assets > 0) b.writeln(tr('• أصول: ${egp(assets)}', '• Assets: ${egp(assets)}'));
    if (owedToMe > 0) b.writeln(tr('• ليك عند الناس: ${egp(owedToMe)}', '• Owed to you: ${egp(owedToMe)}'));
    if (iOwe > 0) b.writeln(tr('• عليك: ${egp(iOwe)}', '• You owe: ${egp(iOwe)}'));
    return b.toString().trim();
  }

  static Future<String> _gameya() async {
    final list = await GameyaRepo().all();
    if (list.isEmpty) {
      return tr('مفيش جمعيات مسجلة.', 'No gameyas (savings circles) logged.');
    }
    final b = StringBuffer();
    b.writeln(tr('جمعياتك:', 'Your savings circles:'));
    for (final g in list) {
      b.writeln(tr(
          '• ${g.name}: ${egp(g.amount)}/شهر — دورك الشهر ${arNum(g.myTurn)} من ${arNum(g.totalMonths)}',
          '• ${g.name}: ${egp(g.amount)}/mo — your turn is month ${arNum(g.myTurn)} of ${arNum(g.totalMonths)}'));
    }
    return b.toString().trim();
  }

  static Future<String> _occasions() async {
    final now = DateTime.now();
    final up = await OccasionsRepo().upcomingWithinWindow(now);
    if (up.isEmpty) {
      return tr('مفيش مناسبات قريبة في الأيام الجاية.', 'No occasions coming up soon.');
    }
    DateTime nextDate(int month, int day) {
      var d = DateTime(now.year, month, day);
      if (d.isBefore(DateTime(now.year, now.month, now.day))) {
        d = DateTime(now.year + 1, month, day);
      }
      return d;
    }

    final b = StringBuffer();
    b.writeln(tr('مناسبات قريبة:', 'Upcoming occasions:'));
    for (final o in up.take(8)) {
      final who = o.person.isNotEmpty ? ' (${o.person})' : '';
      b.writeln('• ${o.title}$who — ${arShortDate(nextDate(o.month, o.day))}');
    }
    return b.toString().trim();
  }

  static Future<String> _relatives() async {
    final due = await RelativesRepo().due(DateTime.now());
    if (due.isEmpty) {
      return tr('مفيش حد فات عليه معاد اتصال. صلة رحمك تمام 👌',
          'No one is overdue for a call. Your family ties are on track 👌');
    }
    final b = StringBuffer();
    b.writeln(tr('محتاج تطمن على:', 'Time to check on:'));
    for (final r in due.take(8)) {
      final phone = r.phone.isNotEmpty ? ' — ${r.phone}' : '';
      b.writeln('• ${r.name}$phone');
    }
    return b.toString().trim();
  }

  static Future<String> _maintenance() async {
    final due = await HomeMaintenanceRepo().due(DateTime.now());
    if (due.isEmpty) {
      return tr('مفيش صيانة مستحقة في البيت دلوقتي. 👌',
          'No home maintenance due right now. 👌');
    }
    final b = StringBuffer();
    b.writeln(tr('صيانة مستحقة:', 'Maintenance due:'));
    for (final m in due.take(8)) {
      b.writeln('• ${m.name}');
    }
    return b.toString().trim();
  }

  static Future<String> _plants() async {
    final due = await PlantsRepo().due(DateTime.now());
    if (due.isEmpty) {
      return tr('كل النباتات اترويت. 🪴', 'All plants are watered. 🪴');
    }
    final b = StringBuffer();
    b.writeln(tr('نباتات محتاجة مياه:', 'Plants needing water:'));
    for (final p in due.take(10)) {
      final loc = p.location.isNotEmpty ? ' (${p.location})' : '';
      b.writeln('• ${p.name}$loc');
    }
    return b.toString().trim();
  }

  static Future<String> _weather() async {
    final w = await WeatherService.today();
    if (w == null) {
      return tr('مقدرش أجيب الطقس دلوقتي — اتأكد إنك محدد محافظتك ومتصل بالنت.',
          "Can't get the weather now — make sure your governorate is set and you're online.");
    }
    return w.summaryLine();
  }

  static Future<String> _mealsToday() async {
    final meals = await MealsRepo().forDay(dayKey(DateTime.now()));
    if (meals.isEmpty) {
      return tr('مسجلتش أي أكل النهاردة لسه.', "You haven't logged any meals today yet.");
    }
    final withCal = [for (final m in meals) if (m.calories != null) m.calories!];
    final total = withCal.fold<double>(0, (s, c) => s + c);
    final b = StringBuffer();
    b.writeln(tr('أكلت النهاردة ${arNum(meals.length)} وجبة.',
        'You logged ${arNum(meals.length)} meals today.'));
    if (total > 0) {
      b.writeln(tr('إجمالي السعرات المسجلة: ${arNum(total.round())}',
          'Total logged calories: ${arNum(total.round())}'));
      final goal = await SettingsRepo().calorieGoal();
      if (goal > 0) {
        final left = goal - total;
        b.writeln(left >= 0
            ? tr('فاضل من هدفك: ${arNum(left.round())} سعر', 'Left of your goal: ${arNum(left.round())} kcal')
            : tr('عدّيت هدفك بـ ${arNum((-left).round())} سعر', 'Over your goal by ${arNum((-left).round())} kcal'));
      }
    }
    return b.toString().trim();
  }

  static Future<String> _income() async {
    final now = DateTime.now();
    final inc = await IncomeRepo().totalForMonth(now.year, now.month);
    final exp = await MoneyRepo().totalForMonth(now.year, now.month);
    if (inc == 0) {
      return tr('مسجلتش دخل للشهر ده. صرفت ${egp(exp)} لحد دلوقتي.',
          'No income logged this month. You spent ${egp(exp)} so far.');
    }
    final net = inc - exp;
    final mark = net >= 0 ? '👍' : '⚠️';
    return tr(
        'دخل الشهر: ${egp(inc)}\nمصروف: ${egp(exp)}\nالصافي: ${egp(net)} $mark',
        'Income: ${egp(inc)}\nSpent: ${egp(exp)}\nNet: ${egp(net)} $mark');
  }

  static Future<String> _debts() async {
    final (owedToMe, iOwe) = await DebtsRepo().totals();
    if (owedToMe == 0 && iOwe == 0) {
      return tr('مفيش ديون مفتوحة — لا ليك ولا عليك. 👌',
          "No open debts — you're all clear. 👌");
    }
    final b = StringBuffer();
    if (iOwe > 0) b.writeln(tr('عليك: ${egp(iOwe)}', 'You owe: ${egp(iOwe)}'));
    if (owedToMe > 0) {
      b.writeln(tr('ليك عند الناس: ${egp(owedToMe)}', 'Owed to you: ${egp(owedToMe)}'));
    }
    final net = owedToMe - iOwe;
    b.writeln(net >= 0
        ? tr('الصافي: ليك ${egp(net)}', 'Net: ${egp(net)} in your favor')
        : tr('الصافي: عليك ${egp(-net)}', 'Net: ${egp(-net)} against you'));
    return b.toString().trim();
  }

  static Future<String> _savings() async {
    final goals = await SavingsRepo().all();
    if (goals.isEmpty) {
      return tr('مفيش أهداف ادخار. حدد هدف من قسم الادخار وأنا أتابعه معاك.',
          'No savings goals yet. Set one in the Savings section and I\'ll track it.');
    }
    final b = StringBuffer();
    b.writeln(tr('أهداف الادخار:', 'Savings goals:'));
    for (final g in goals) {
      final pct = g.target > 0 ? (g.saved / g.target * 100).clamp(0, 100).round() : 0;
      b.writeln('• ${g.name}: ${egp(g.saved)} / ${egp(g.target)} (${arNum(pct)}%)');
    }
    return b.toString().trim();
  }

  static Future<String> _bills() async {
    final due = await BillsRepo().due(DateTime.now());
    if (due.isEmpty) {
      return tr('مفيش فواتير مستحقة دلوقتي. 👌', 'No bills due right now. 👌');
    }
    final b = StringBuffer();
    b.writeln(tr('فواتير مستحقة:', 'Bills due:'));
    var sum = 0.0;
    for (final x in due) {
      b.writeln('• ${x.name}: ${egp(x.amount)}');
      sum += x.amount;
    }
    b.writeln(tr('الإجمالي: ${egp(sum)}', 'Total: ${egp(sum)}'));
    return b.toString().trim();
  }

  static Future<String> _meds() async {
    final meds = await MedsRepo().all(activeOnly: true);
    if (meds.isEmpty) {
      return tr('مفيش أدوية حالية مسجلة.', 'No current medications logged.');
    }
    final b = StringBuffer();
    b.writeln(tr('أدويتك الحالية:', 'Your current meds:'));
    for (final m in meds) {
      final times = m.times.isEmpty ? '' : ' — ${m.times.join('، ')}';
      b.writeln('• ${m.name}$times');
    }
    return b.toString().trim();
  }

  static Future<String> _habits() async {
    final repo = HabitsRepo();
    final habits = await repo.active();
    if (habits.isEmpty) {
      return tr('مفيش عادات مسجلة. ضيف عادة من قسم العادات.',
          'No habits yet. Add one in the Habits section.');
    }
    final now = DateTime.now();
    final b = StringBuffer();
    b.writeln(tr('عاداتك وسلاسلها:', 'Your habits & streaks:'));
    for (final h in habits) {
      final streak = computeStreak(await repo.daysFor(h.id!), now);
      b.writeln(tr('• ${h.name}: سلسلة ${arNum(streak)} يوم',
          '• ${h.name}: ${arNum(streak)}-day streak'));
    }
    return b.toString().trim();
  }

  static Future<String> _appointments(String t) async {
    final now = DateTime.now();
    final all = await AppointmentsRepo().all();
    final wantTomorrow = _has(t, ['بكره', 'بكرة', 'غدا', 'tomorrow']);
    final tm = dateOnly(now).add(const Duration(days: 1));
    bool inRange(DateTime w) {
      if (wantTomorrow) {
        return w.year == tm.year && w.month == tm.month && w.day == tm.day;
      }
      return w.isAfter(now) && w.isBefore(now.add(const Duration(days: 7)));
    }

    final up = [for (final a in all) if (!a.done && inRange(a.when)) a]
      ..sort((a, b) => a.when.compareTo(b.when));
    if (up.isEmpty) {
      return wantTomorrow
          ? tr('مفيش مواعيد بكرة.', 'No appointments tomorrow.')
          : tr('مفيش مواعيد في الأيام الجاية.', 'No appointments coming up.');
    }
    final b = StringBuffer();
    b.writeln(wantTomorrow
        ? tr('مواعيد بكرة:', 'Tomorrow:')
        : tr('المواعيد الجاية:', 'Upcoming appointments:'));
    for (final a in up.take(8)) {
      b.writeln('• ${a.title} — ${arShortDate(a.when)} ${arTime(a.when)}');
    }
    return b.toString().trim();
  }

  static Future<String> _todayPlan() async {
    final now = DateTime.now();
    final b = StringBuffer();
    var any = false;

    final appts = await AppointmentsRepo().all();
    final todayAppts = [
      for (final a in appts)
        if (!a.done && a.when.isAfter(now) && dateOnly(a.when) == dateOnly(now)) a
    ]..sort((a, b) => a.when.compareTo(b.when));
    for (final a in todayAppts) {
      b.writeln('• ${arTime(a.when)} — ${a.title}');
      any = true;
    }

    final prayer = await _nextPrayerShort(now);
    if (prayer != null) {
      b.writeln('• $prayer');
      any = true;
    }

    final repo = HabitsRepo();
    final habits = await repo.active();
    final doneIds = await repo.doneOn(dayKey(now));
    final pending = [for (final h in habits) if (!doneIds.contains(h.id)) h.name];
    if (pending.isNotEmpty) {
      b.writeln(tr('• عادات لسه: ${pending.join('، ')}',
          '• Habits left: ${pending.join(', ')}'));
      any = true;
    }

    final due = await BillsRepo().due(now);
    if (due.isNotEmpty) {
      b.writeln(tr('• فواتير مستحقة: ${due.map((x) => x.name).join('، ')}',
          '• Bills due: ${due.map((x) => x.name).join(', ')}'));
      any = true;
    }

    if (!any) {
      return tr('يومك فاضي — مفيش مواعيد ولا عادات متأخرة. استغل الوقت في حاجة مفيدة 🙂',
          'Your day is clear — nothing pending. Use the time well 🙂');
    }
    return '${tr('خطة باقي يومك:', 'Rest of your day:')}\n${b.toString().trim()}';
  }

  static Future<String> _healthToday() async {
    final now = DateTime.now();
    final key = dayKey(now);
    final water = await HealthRepo().waterOn(key);
    final sleep = await HealthRepo().sleepOn(key);
    final steps = (await MeasurementsRepo().stepsSince(key))[key];
    final b = StringBuffer();
    b.writeln(tr('حالتك النهاردة:', 'Today:'));
    b.writeln(tr('• المياه: ${arNum(water)} كوب', '• Water: ${arNum(water)} cups'));
    if (sleep != null) {
      b.writeln(tr('• النوم امبارح: ${arNum(sleep.toStringAsFixed(1))} ساعة',
          '• Sleep: ${arNum(sleep.toStringAsFixed(1))} h'));
    }
    if (steps != null) {
      b.writeln(tr('• الخطوات: ${arNum(steps)}', '• Steps: ${arNum(steps)}'));
    }
    return b.toString().trim();
  }

  static Future<String> _measurements() async {
    final list = await MeasurementsRepo().recent(limit: 30);
    if (list.isEmpty) {
      return tr('مفيش قياسات مسجلة. سجّل وزنك أو ضغطك من قسم القياسات.',
          'No measurements yet. Log your weight or blood pressure.');
    }
    final seen = <String>{};
    final b = StringBuffer();
    b.writeln(tr('آخر قياساتك:', 'Latest measurements:'));
    for (final m in list) {
      if (seen.add(m.type)) {
        b.writeln('• ${m.type}: ${m.display()} (${m.day})');
      }
    }
    return b.toString().trim();
  }

  static Future<String> _docs() async {
    final soon = await DocsRepo().expiringSoon();
    if (soon.isEmpty) {
      final all = await DocsRepo().all();
      return all.isEmpty
          ? tr('مفيش مستندات محفوظة.', 'No documents saved.')
          : tr('عندك ${arNum(all.length)} مستند، ومفيش حاجة قربت تنتهي. تمام. 👌',
              'You have ${arNum(all.length)} documents, none expiring soon. 👌');
    }
    final b = StringBuffer();
    b.writeln(tr('مستندات قربت تنتهي:', 'Documents expiring soon:'));
    for (final d in soon.take(8)) {
      final exp = d.expiry != null
          ? ' — ${arShortDate(DateTime.parse(d.expiry!))}'
          : '';
      b.writeln('• ${d.title}$exp');
    }
    return b.toString().trim();
  }

  static Future<String> _prayer() async {
    final now = DateTime.now();
    final short = await _nextPrayerShort(now);
    return short ?? tr('مقدرش أحسب مواعيد الصلاة دلوقتي.', "Can't compute prayer times now.");
  }

  static Future<String?> _nextPrayerShort(DateTime now) async {
    final gov = governorateByName(await SettingsRepo().governorateName());
    final today = prayerTimesFor(now, gov);
    final idx = today.nextIndex(now);
    if (idx == null) {
      final tomo = prayerTimesFor(now.add(const Duration(days: 1)), gov);
      return tr('الصلاة الجاية: الفجر بكرة ${arTime(tomo.fajr)}',
          'Next prayer: Fajr tomorrow at ${arTime(tomo.fajr)}');
    }
    final at = today.times[idx];
    final mins = at.difference(now).inMinutes;
    final h = mins ~/ 60, m = mins % 60;
    final left = h > 0
        ? tr('بعد ${arNum(h)}س و${arNum(m)}د', 'in ${arNum(h)}h ${arNum(m)}m')
        : tr('بعد ${arNum(m)}د', 'in ${arNum(m)}m');
    return tr('الصلاة الجاية: ${prayerNameLabel(idx)} ${arTime(at)} ($left)',
        'Next prayer: ${prayerNameLabel(idx)} at ${arTime(at)} ($left)');
  }

  static Future<String> _advice() async {
    final data = await InsightsRepo().assemble(now: DateTime.now());
    final list = buildInsights(data);
    final b = StringBuffer();
    b.writeln(tr('من أرقامك:', 'From your numbers:'));
    for (final ins in list.take(3)) {
      b.writeln('• ${ins.text}');
    }
    return b.toString().trim();
  }

  static Future<String?> _pharmacy(String t) async {
    var q = ' $t ';
    const strip = [
      'هل', 'عندي', 'عندى', 'معايا', 'معي', 'في', 'فيه', 'عندنا', 'عندك', 'لقيت',
      'فاضل', 'باقي', 'كام', 'دوا', 'دواء', 'علاج', 'البيت', 'الصيدليه', 'صيدليه'
    ];
    for (final w in strip) {
      q = q.replaceAll(' $w ', ' ');
    }
    q = q.trim();
    if (q.isEmpty) return null;
    final items = await PharmacyRepo().search(q);
    if (items.isEmpty) {
      return tr('مش لاقي «$q» في صيدلية البيت. تحب تضيفه من قسم الصيدلية؟',
          "I can't find \"$q\" in your home pharmacy. Add it from the Pharmacy section?");
    }
    final b = StringBuffer();
    b.writeln(tr('آه، عندك:', 'Yes, you have:'));
    for (final it in items.take(6)) {
      final exp = it.expiry != null
          ? tr(' — صلاحية ${arShortDate(DateTime.parse(it.expiry!))}',
              ' — exp ${arShortDate(DateTime.parse(it.expiry!))}')
          : '';
      b.writeln('• ${it.name} ×${arNum(it.quantity)}$exp');
    }
    return b.toString().trim();
  }

  static Future<String> _briefing() async {
    final now = DateTime.now();
    final key = dayKey(now);
    final b = StringBuffer();
    b.writeln(tr('ملخص يومك:', 'Your day at a glance:'));

    final spend = await MoneyRepo().totalForMonth(now.year, now.month);
    final budget = await SettingsRepo().monthlyBudget();
    if (budget > 0) {
      final left = budget - spend;
      b.writeln(left >= 0
          ? tr('💰 صرفت ${egp(spend)} — فاضل ${egp(left)} من الميزانية',
              '💰 Spent ${egp(spend)} — ${egp(left)} left in budget')
          : tr('💰 صرفت ${egp(spend)} — عدّيت الميزانية بـ ${egp(-left)} ⚠️',
              '💰 Spent ${egp(spend)} — over budget by ${egp(-left)} ⚠️'));
    } else {
      b.writeln(tr('💰 صرفت الشهر ده ${egp(spend)}',
          '💰 Spent this month: ${egp(spend)}'));
    }

    final appts = await AppointmentsRepo().all();
    final todayAppts = [
      for (final a in appts)
        if (!a.done && a.when.isAfter(now) && dateOnly(a.when) == dateOnly(now)) a
    ];
    if (todayAppts.isNotEmpty) {
      b.writeln(tr('📅 مواعيد لسه النهاردة: ${arNum(todayAppts.length)}',
          '📅 Appointments left today: ${arNum(todayAppts.length)}'));
    }
    final prayer = await _nextPrayerShort(now);
    if (prayer != null) b.writeln('🕌 $prayer');

    final hrepo = HabitsRepo();
    final habits = await hrepo.active();
    final done = await hrepo.doneOn(key);
    final pending = [for (final h in habits) if (!done.contains(h.id)) h.name];
    if (habits.isNotEmpty) {
      b.writeln(pending.isEmpty
          ? tr('✅ خلّصت كل عاداتك النهاردة — تحفة!', '✅ All habits done today — great!')
          : tr('🔄 عادات لسه: ${pending.join('، ')}',
              '🔄 Habits left: ${pending.join(', ')}'));
    }

    final water = await HealthRepo().waterOn(key);
    b.writeln(tr('💧 شربت ${arNum(water)} كوب مياه', '💧 Water today: ${arNum(water)} cups'));

    final alerts = <String>[];
    final overdue = [
      for (final a in appts)
        if (!a.done && a.when.isBefore(dateOnly(now))) a.title
    ];
    if (overdue.isNotEmpty) {
      alerts.add(tr('مواعيد فايتة: ${overdue.take(3).join('، ')}',
          'Overdue: ${overdue.take(3).join(', ')}'));
    }
    final bills = await BillsRepo().due(now);
    if (bills.isNotEmpty) {
      alerts.add(tr('فواتير مستحقة: ${bills.map((x) => x.name).join('، ')}',
          'Bills due: ${bills.map((x) => x.name).join(', ')}'));
    }
    final (_, iOwe) = await DebtsRepo().totals();
    if (iOwe > 0) alerts.add(tr('عليك ديون ${egp(iOwe)}', 'You owe ${egp(iOwe)}'));
    final docs = await DocsRepo().expiringSoon();
    if (docs.isNotEmpty) {
      alerts.add(tr('مستندات قربت تنتهي: ${docs.map((d) => d.title).take(3).join('، ')}',
          'Docs expiring: ${docs.map((d) => d.title).take(3).join(', ')}'));
    }
    final relatives = await RelativesRepo().due(now);
    if (relatives.isNotEmpty) {
      alerts.add(tr('اطمن على: ${relatives.map((r) => r.name).take(3).join('، ')}',
          'Check on: ${relatives.map((r) => r.name).take(3).join(', ')}'));
    }
    if (alerts.isNotEmpty) {
      b.writeln(tr('⚠️ محتاج تاخد بالك:', '⚠️ Needs attention:'));
      for (final a in alerts) {
        b.writeln('• $a');
      }
    }
    return b.toString().trim();
  }

  static Future<String> _medsToday() async {
    final meds = await MedsRepo().all(activeOnly: true);
    if (meds.isEmpty) return tr('مفيش أدوية حالية.', 'No current meds.');
    final taken = await MedsRepo().takenOn(dayKey(DateTime.now()));
    final b = StringBuffer();
    var remaining = 0;
    for (final m in meds) {
      final left = [for (final s in m.times) if (!taken.contains('${m.id}|$s')) s];
      remaining += left.length;
      if (left.isNotEmpty) b.writeln('• ${m.name}: ${left.join('، ')}');
    }
    if (remaining == 0) {
      return tr('خلّصت كل جرعاتك النهاردة 👏', "You've taken all today's doses 👏");
    }
    return '${tr('جرعات لسه النهاردة:', 'Doses left today:')}\n${b.toString().trim()}';
  }

  static Future<String> _gymToday() async {
    final now = DateTime.now();
    final plan = await WorkoutRepo().plan();
    final title = plan[now.weekday];
    final done = await WorkoutRepo().doneOn(dayKey(now));
    final b = StringBuffer();
    if (title == null || title.isEmpty) {
      b.writeln(tr('مفيش تمرين متجدول النهاردة — يوم راحة 💪',
          'No workout scheduled today — rest day 💪'));
    } else if (done) {
      b.writeln(tr('تمرين النهاردة «$title» — خلّصته ✅',
          'Today\'s workout "$title" — done ✅'));
    } else {
      b.writeln(tr('تمرين النهاردة: $title', "Today's workout: $title"));
    }
    final program = await GymRepo().currentProgram();
    if (program.isNotEmpty) {
      b.writeln(tr('برنامجك: ${gymProgramLabel(program)}',
          'Your program: ${gymProgramLabel(program)}'));
    }
    final prs = await GymRepo().personalRecords();
    if (prs.isNotEmpty) {
      b.writeln(tr('أعلى أوزانك:', 'Your PRs:'));
      for (final p in prs.take(4)) {
        final w = p.weight % 1 == 0 ? p.weight.toInt() : p.weight;
        b.writeln('• ${p.exercise}: ${arNum(w)} ${tr('كجم', 'kg')}');
      }
    }
    return b.toString().trim();
  }

  static Future<String> _shopping() async {
    final items = await MealsRepo().shoppingItems();
    final toBuy = [for (final i in items) if (!i.checked) i.name];
    if (toBuy.isEmpty) {
      return tr('قايمة المشتريات فاضية. 🛒', 'Your shopping list is empty. 🛒');
    }
    final b = StringBuffer();
    b.writeln(tr('لازم تشتري (${arNum(toBuy.length)}):', 'To buy (${arNum(toBuy.length)}):'));
    for (final n in toBuy.take(20)) {
      b.writeln('• $n');
    }
    return b.toString().trim();
  }

  static Future<String> _prayersAll() async {
    final now = DateTime.now();
    final gov = governorateByName(await SettingsRepo().governorateName());
    final day = prayerTimesFor(now, gov);
    final next = day.nextIndex(now);
    final b = StringBuffer();
    b.writeln(tr('مواعيد الصلاة النهاردة:', "Today's prayer times:"));
    for (var i = 0; i < day.times.length; i++) {
      final marker = i == next ? tr('  ← الجاية', '  ← next') : '';
      b.writeln('• ${prayerNameLabel(i)}: ${arTime(day.times[i])}$marker');
    }
    return b.toString().trim();
  }

  /// رسالة المساعدة/القدرات — تُستخدم كردّ ترحيب وكـ fallback.
  static String helpText() => tr(
      'أنا مديرك — بجاوبك من بياناتك مباشرة على الجهاز (من غير إنترنت). '
          'جرّب تسألني:\n'
          '• «طمني على يومي» (ملخص شامل)\n'
          '• «معايا كام فلوس؟»\n'
          '• «صرفت كام الشهر ده؟»\n'
          '• «عليا ديون؟»\n'
          '• «مواعيدي إيه؟» أو «عندي حاجة بكرة؟»\n'
          '• «أدويتي إيه؟» / «عندي بانادول؟»\n'
          '• «أعمل إيه باقي النهاردة؟»\n'
          '• «صافي ثروتي؟» / «الجمعية» / «مناسبات جاية؟»\n'
          '• «إزاي نومي؟» / «قياساتي» / «الجو النهاردة؟»\n'
          '• «اديني نصيحة من أرقامي»',
      "I'm your manager — I answer straight from your data, on-device (no internet). "
          'Try asking:\n'
          '• "Brief me on my day" (full summary)\n'
          '• "How much money do I have?"\n'
          '• "How much did I spend this month?"\n'
          '• "Do I owe any debts?"\n'
          '• "What are my appointments?" or "Anything tomorrow?"\n'
          '• "What are my meds?" / "Do I have Panadol?"\n'
          '• "What should I do the rest of today?"\n'
          '• "My net worth?" / "My gameya" / "Any occasions coming up?"\n'
          '• "How\'s my sleep?" / "My measurements" / "Today\'s weather?"\n'
          '• "Give me advice from my numbers"');

  // ---- أدوات مساعدة ----

  /// يوحّد النص للمطابقة: يشيل التشكيل والعلامات ويوحّد الألف/الياء/الهاء.
  static String _norm(String s) {
    var t = s.toLowerCase().trim();
    t = t.replaceAll(RegExp('[ً-ْـ]'), ''); // تشكيل + تطويل
    t = t
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
    t = t.replaceAll(RegExp(r'[؟?.,!،:؛]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  static bool _has(String t, List<String> keywords) {
    for (final k in keywords) {
      if (t.contains(_normKeyword(k))) return true;
    }
    return false;
  }

  static String _normKeyword(String k) => k
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه');
}
