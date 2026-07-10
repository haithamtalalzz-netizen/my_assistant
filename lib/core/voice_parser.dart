// محلل الأوامر الصوتية العربية — قواعد محلية بالكامل، من غير أي API.
// بيستقبل جملة زي «صرفت ١٥٠ بنزين وشربت ٣ مياه» ويطلع قائمة أفعال
// تتعرض للمستخدم للتأكيد قبل التنفيذ.
import 'ar.dart';

enum VoiceActionType {
  expense,
  income,
  water,
  sleep,
  medTaken,
  habitDone,
  appointment,
  meal,
  workoutDone,
  measurement,
  inboxNote,
  debt,
}

class VoiceAction {
  final VoiceActionType type;
  final double? amount;

  /// للقياسات ذات الرقمين (الضغط: الانبساطي).
  final double? amount2;
  final String? category;
  final String? note;
  final String? matchName;
  final DateTime? when;
  final String? title;

  const VoiceAction({
    required this.type,
    this.amount,
    this.amount2,
    this.category,
    this.note,
    this.matchName,
    this.when,
    this.title,
  });

  String describe() {
    switch (type) {
      case VoiceActionType.expense:
        final noteTxt = (note == null || note!.isEmpty) ? '' : ' (${note!})';
        return 'مصروف: ${egp(amount ?? 0)} — $category$noteTxt';
      case VoiceActionType.income:
        return 'دخل: ${egp(amount ?? 0)} — $category';
      case VoiceActionType.water:
        return 'مياه: +${arNum(amount!.toInt())}';
      case VoiceActionType.sleep:
        return 'نوم: ${arNum(amount! == amount!.roundToDouble() ? amount!.toInt() : amount!)} ساعات';
      case VoiceActionType.medTaken:
        return matchName == null || matchName!.isEmpty
            ? 'جرعة دوا: أول جرعة معلقة النهارده'
            : 'جرعة دوا: $matchName';
      case VoiceActionType.habitDone:
        return 'عادة اتعملت: $matchName';
      case VoiceActionType.appointment:
        return 'موعد: $title — ${arShortDate(when!)} ${arTime(when!)}';
      case VoiceActionType.meal:
        return 'وجبة ($matchName): $note';
      case VoiceActionType.workoutDone:
        return 'تمرين النهارده اتعمل ✓';
      case VoiceActionType.measurement:
        final v = arNum(amount! == amount!.roundToDouble()
            ? amount!.toInt()
            : amount!.toStringAsFixed(1));
        return amount2 != null
            ? 'قياس $matchName: $v/${arNum(amount2!.toInt())}'
            : 'قياس $matchName: $v';
      case VoiceActionType.inboxNote:
        return 'فكرة للوارد: $note';
      case VoiceActionType.debt:
        return category == 'لى'
            ? 'سلفت $matchName: ${egp(amount ?? 0)}'
            : 'خدت من $matchName: ${egp(amount ?? 0)}';
    }
  }
}

const Map<String, double> _numberWords = {
  'واحد': 1, 'واحدة': 1, 'واحده': 1,
  'اتنين': 2, 'إتنين': 2, 'اثنين': 2,
  'تلاتة': 3, 'تلاته': 3, 'ثلاثة': 3, 'ثلاثه': 3, 'تلات': 3, 'ثلاث': 3,
  'أربعة': 4, 'اربعة': 4, 'اربعه': 4, 'أربع': 4, 'اربع': 4,
  'خمسة': 5, 'خمسه': 5, 'خمس': 5,
  'ستة': 6, 'سته': 6, 'ست': 6,
  'سبعة': 7, 'سبعه': 7, 'سبع': 7,
  'تمانية': 8, 'تمانيه': 8, 'ثمانية': 8, 'تمن': 8, 'تماني': 8,
  'تسعة': 9, 'تسعه': 9, 'تسع': 9,
  'عشرة': 10, 'عشره': 10, 'عشر': 10,
};

const List<String> _waterWords = [
  'مياه', 'ميه', 'مية', 'موية', 'كوباية', 'كوبايه', 'كوبايات', 'كباية'
];
const List<String> _currencyWords = ['جنيه', 'جنية', 'جنيها', 'ج', 'م'];

const Map<String, List<String>> _expenseCategoryWords = {
  'مواصلات': ['بنزين', 'تاكسي', 'أوبر', 'اوبر', 'مواصلات', 'ميكروباص', 'سولار', 'باركينج', 'جراج'],
  'أكل': ['أكل', 'اكل', 'فطار', 'غدا', 'عشا', 'مطعم', 'قهوة', 'قهوه', 'حلويات'],
  'فواتير': ['فاتورة', 'فاتوره', 'كهربا', 'كهرباء', 'نت', 'انترنت', 'إنترنت', 'تليفون', 'موبايل', 'غاز'],
  'صحة': ['دوا', 'دواء', 'صيدلية', 'صيدليه', 'دكتور', 'تحاليل', 'كشف'],
  'تسوق': ['هدوم', 'لبس', 'سوبر', 'ماركت', 'تسوق', 'جزمة', 'جزمه'],
  'ترفيه': ['سينما', 'رحلة', 'رحله', 'خروجة', 'خروجه', 'نادي', 'نادى'],
};

double? _wordOrDigit(String token) {
  final numeric = double.tryParse(token);
  if (numeric != null) return numeric;
  return _numberWords[token];
}

/// أول رقم (رقمي أو كلمة) بعد موضع معين.
double? _numberAfter(List<String> tokens, int start, {int within = 4}) {
  for (var i = start + 1; i < tokens.length && i <= start + within; i++) {
    final v = _wordOrDigit(tokens[i]);
    if (v != null) return v;
  }
  return null;
}

int _indexWhere(List<String> tokens, bool Function(String) test, [int from = 0]) {
  for (var i = from; i < tokens.length; i++) {
    if (test(tokens[i])) return i;
  }
  return -1;
}

String _stripAl(String token) =>
    token.startsWith('ال') && token.length > 3 ? token.substring(2) : token;

/// «وشربت» و«شربت» الاتنين لازم يتعرفوا — واو العطف بتتلزق في الفعل.
bool _isVerbToken(String token, List<String> forms) {
  if (forms.contains(token)) return true;
  if (token.length > 1 && token.startsWith('و')) {
    return forms.contains(token.substring(1));
  }
  return false;
}

List<VoiceAction> parseUtterance(
  String raw, {
  DateTime? now,
  List<String> habitNames = const [],
  List<String> medNames = const [],
}) {
  final current = now ?? DateTime.now();
  final text = toEnglishDigits(raw.trim());
  if (text.isEmpty) return [];
  final tokens = text.split(RegExp(r'\s+'));
  final actions = <VoiceAction>[];

  final expense = _parseExpense(tokens);
  if (expense != null) actions.add(expense);

  final income = _parseIncome(tokens);
  if (income != null) actions.add(income);

  final water = _parseWater(tokens);
  if (water != null) actions.add(water);

  final sleep = _parseSleep(tokens);
  if (sleep != null) actions.add(sleep);

  final appointment = _parseAppointment(tokens, current);
  if (appointment != null) actions.add(appointment);

  final meal = _parseMeal(tokens, current);
  if (meal != null) actions.add(meal);

  if (tokens.any((t) =>
      _isVerbToken(t, const ['اتمرنت', 'إتمرنت', 'تمرنت']))) {
    actions.add(const VoiceAction(type: VoiceActionType.workoutDone));
  }

  final measurement = _parseMeasurement(tokens);
  if (measurement != null) actions.add(measurement);

  final debt = _parseDebt(tokens);
  if (debt != null) actions.add(debt);

  // «افتكرلي أجيب شاحن» — كل اللي بعد الفعل بيروح صندوق الوارد.
  final inboxIdx = _indexWhere(tokens,
      (t) => _isVerbToken(t, const ['افتكرلي', 'إفتكرلي', 'فكرني', 'فكرة']));
  if (inboxIdx >= 0 && inboxIdx + 1 < tokens.length && actions.isEmpty) {
    final text = tokens.sublist(inboxIdx + 1).join(' ');
    if (text.length >= 3) {
      actions.add(VoiceAction(type: VoiceActionType.inboxNote, note: text));
    }
  }

  // الأدوية والعادات بتتطابق بأسمائها الفعلية اللي جاية من قاعدة البيانات.
  final med = _parseMed(tokens, text, medNames);
  if (med != null) actions.add(med);

  for (final habit in habitNames) {
    if (habit.length >= 3 &&
        text.contains(habit) &&
        (text.contains('عملت') ||
            text.contains('خلصت') ||
            text.contains('قريت') ||
            text.contains('صليت'))) {
      actions.add(VoiceAction(type: VoiceActionType.habitDone, matchName: habit));
    }
  }

  return actions;
}

VoiceAction? _parseExpense(List<String> tokens) {
  final verbIdx = _indexWhere(tokens,
      (t) => _isVerbToken(t, const ['صرفت', 'دفعت', 'اشتريت', 'إشتريت']));
  if (verbIdx < 0) return null;
  // المبلغ لازم يكون أرقام — الإملاء الصوتي بيطلع الأرقام كأرقام أصلًا.
  double? amount;
  var amountIdx = -1;
  for (var i = verbIdx + 1; i < tokens.length; i++) {
    final v = double.tryParse(tokens[i]);
    if (v != null && v > 0) {
      amount = v;
      amountIdx = i;
      break;
    }
  }
  if (amount == null) return null;

  String category = 'أخرى';
  String note = '';
  outer:
  for (final entry in _expenseCategoryWords.entries) {
    for (final t in tokens) {
      final bare = _stripAl(t);
      if (entry.value.contains(bare)) {
        category = entry.key;
        note = bare;
        break outer;
      }
    }
  }
  if (note.isEmpty) {
    // أقرب كلمة وصف بعد المبلغ مش عملة ولا رقم.
    for (var i = amountIdx + 1; i < tokens.length; i++) {
      final t = tokens[i];
      if (_currencyWords.contains(t) || double.tryParse(t) != null) continue;
      if (t == 'على' || t == 'في' || t == 'فى') continue;
      note = t;
      break;
    }
  }
  return VoiceAction(
      type: VoiceActionType.expense,
      amount: amount,
      category: category,
      note: note);
}

/// «قبضت ٥٠٠٠ مرتب» / «قبضت مرتب ٨٠٠٠» / «دخل ٢٠٠ من شغل».
VoiceAction? _parseIncome(List<String> tokens) {
  final verbIdx = _indexWhere(tokens,
      (t) => _isVerbToken(t, const ['قبضت', 'اتقبضت', 'دخل', 'دخلي']));
  if (verbIdx < 0) return null;
  double? amount;
  for (var i = verbIdx + 1; i < tokens.length; i++) {
    final v = double.tryParse(tokens[i]);
    if (v != null && v > 0) {
      amount = v;
      break;
    }
  }
  if (amount == null) return null;
  // المصدر من كلمات مفتاحية.
  var source = 'أخرى';
  for (final t in tokens) {
    final bare = _stripAl(t);
    if (bare == 'مرتب' || bare == 'مرتبي' || bare == 'راتب') {
      source = 'مرتب';
      break;
    }
    if (bare == 'مكافأة' || bare == 'مكافئة' || bare == 'مكافاة') {
      source = 'مكافأة';
      break;
    }
    if (bare == 'فريلانس' || bare == 'شغل' || bare == 'حر') {
      source = 'عمل حر';
      break;
    }
    if (bare == 'بيع' || bare == 'بعت') {
      source = 'بيع';
      break;
    }
  }
  return VoiceAction(
      type: VoiceActionType.income, amount: amount, category: source);
}

VoiceAction? _parseWater(List<String> tokens) {
  final verbIdx =
      _indexWhere(tokens, (t) => _isVerbToken(t, const ['شربت']));
  if (verbIdx < 0) return null;
  final hasWaterWord =
      tokens.any((t) => _waterWords.contains(_stripAl(t))) ||
          tokens.any((t) => t == 'كوبايتين');
  if (!hasWaterWord) return null;
  double count = 1;
  if (tokens.any((t) => t == 'كوبايتين')) {
    count = 2;
  } else {
    count = _numberAfter(tokens, verbIdx) ?? 1;
  }
  if (count < 1 || count > 20) count = 1;
  return VoiceAction(type: VoiceActionType.water, amount: count);
}

VoiceAction? _parseSleep(List<String> tokens) {
  final verbIdx = _indexWhere(tokens, (t) => _isVerbToken(t, const ['نمت']));
  if (verbIdx < 0) return null;
  double? hours;
  if (tokens.length > verbIdx + 1 && tokens[verbIdx + 1] == 'ساعتين') {
    hours = 2;
  } else {
    hours = _numberAfter(tokens, verbIdx);
  }
  if (hours == null) return null;
  // «سبع ساعات ونص»
  final hasHalf = tokens.contains('ونص') ||
      (tokens.contains('نص') && tokens.indexOf('نص') > verbIdx + 1);
  if (hasHalf) hours += 0.5;
  if (hours <= 0 || hours > 24) return null;
  return VoiceAction(type: VoiceActionType.sleep, amount: hours);
}

VoiceAction? _parseMed(List<String> tokens, String text, List<String> medNames) {
  // أولوية للمطابقة باسم الدواء الفعلي.
  for (final med in medNames) {
    if (med.length >= 3 && text.contains(med) && text.contains('خدت')) {
      return VoiceAction(type: VoiceActionType.medTaken, matchName: med);
    }
  }
  final verbIdx = _indexWhere(
      tokens, (t) => _isVerbToken(t, const ['خدت', 'أخدت', 'اخدت']));
  if (verbIdx < 0) return null;
  final medWordIdx = _indexWhere(
      tokens,
      (t) => ['دوا', 'الدوا', 'دواء', 'الدواء', 'برشام', 'البرشام', 'حبوب']
          .contains(t),
      verbIdx);
  if (medWordIdx < 0) return null;
  return const VoiceAction(type: VoiceActionType.medTaken, matchName: '');
}

/// «ضغطي ١٢٠ على ٨٠» / «سكري ١١٠» / «وزني ٩٥» / «حرارتي ٣٨ ونص».
/// «سلفت أحمد ٢٠٠» → ليا عنده. «خدت من محمد ٥٠٠» → عليا له.
VoiceAction? _parseDebt(List<String> tokens) {
  // ليا عند حد: سلفت / دّيت.
  var idx = _indexWhere(
      tokens, (t) => _isVerbToken(t, const ['سلفت', 'سلّفت', 'ديت', 'دّيت']));
  String direction = 'لى';
  if (idx < 0) {
    // عليا لحد: خدت من / استلفت من.
    idx = _indexWhere(tokens,
        (t) => _isVerbToken(t, const ['استلفت', 'إستلفت']));
    if (idx >= 0) {
      direction = 'عليا';
    } else {
      // «خدت من فلان» — «خدت» لوحدها بتتعامل كدوا، فنشترط «من» بعدها قريب.
      final khadat = _indexWhere(
          tokens, (t) => _isVerbToken(t, const ['خدت', 'أخدت', 'اخدت']));
      if (khadat >= 0 &&
          khadat + 1 < tokens.length &&
          tokens[khadat + 1] == 'من') {
        idx = khadat;
        direction = 'عليا';
      } else {
        return null;
      }
    }
  }

  // المبلغ: أول رقم في الجملة (الإملاء بيطلع الأرقام أرقام).
  double? amount;
  var amountIdx = -1;
  for (var i = idx + 1; i < tokens.length; i++) {
    final v = double.tryParse(tokens[i]);
    if (v != null && v > 0) {
      amount = v;
      amountIdx = i;
      break;
    }
  }
  if (amount == null) return null;

  // الاسم: أقرب كلمة اسم (مش رقم/من/جنيه) بعد الفعل وقبل أو بعد المبلغ.
  const skip = ['من', 'جنيه', 'جنية', 'ج', 'مبلغ', 'وحده', 'قرش'];
  String person = '';
  for (var i = idx + 1; i < tokens.length; i++) {
    if (i == amountIdx) continue;
    final t = tokens[i];
    if (skip.contains(t) || double.tryParse(t) != null) continue;
    person = t;
    break;
  }
  if (person.isEmpty) person = 'حد';
  return VoiceAction(
    type: VoiceActionType.debt,
    matchName: person,
    amount: amount,
    category: direction,
  );
}

VoiceAction? _parseMeasurement(List<String> tokens) {
  const typeWords = {
    'ضغطي': 'ضغط', 'الضغط': 'ضغط',
    'سكري': 'سكر', 'السكر': 'سكر',
    'وزني': 'وزن', 'الوزن': 'وزن',
    'حرارتي': 'حرارة', 'الحرارة': 'حرارة',
  };
  var idx = -1;
  String? type;
  for (var i = 0; i < tokens.length; i++) {
    // الكلمة الأصلية الأول («وزني» بتبدأ بواو أصلية) وبعدين منزوعة واو العطف.
    final t = tokens[i];
    final bare = t.length > 1 && t.startsWith('و') ? t.substring(1) : t;
    final match = typeWords[t] ?? typeWords[bare];
    if (match != null) {
      idx = i;
      type = match;
      break;
    }
  }
  if (idx < 0) return null;
  // «الضغط/السكر...» من غير سياق قياس ممكن تكون كلام عادي — نطلب رقم قريب.
  final v1 = _numberAfter(tokens, idx, within: 3);
  if (v1 == null || v1 <= 0) return null;
  double? v2;
  if (type == 'ضغط') {
    // الرقم التاني بعد «على» أو مباشرة.
    final firstIdx = _indexWhere(
        tokens, (t) => _wordOrDigit(t) == v1, idx);
    v2 = _numberAfter(tokens, firstIdx < 0 ? idx + 1 : firstIdx, within: 3);
  }
  var value = v1;
  if (type == 'حرارة' && tokens.contains('ونص')) value += 0.5;
  final unit = switch (type) {
    'سكر' => 'مجم',
    'وزن' => 'كجم',
    'حرارة' => '°م',
    _ => '',
  };
  return VoiceAction(
    type: VoiceActionType.measurement,
    matchName: type,
    amount: value,
    amount2: v2,
    note: unit,
  );
}

VoiceAction? _parseMeal(List<String> tokens, DateTime now) {
  const verbSlots = {
    'فطرت': 'فطار',
    'اتغديت': 'غدا',
    'إتغديت': 'غدا',
    'تغديت': 'غدا',
    'اتعشيت': 'عشا',
    'إتعشيت': 'عشا',
    'تعشيت': 'عشا',
    'اتسحرت': 'سحور',
    'إتسحرت': 'سحور',
  };
  var verbIdx = -1;
  String? slot;
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    final bare =
        t.length > 1 && t.startsWith('و') ? t.substring(1) : t;
    if (verbSlots.containsKey(bare)) {
      verbIdx = i;
      slot = verbSlots[bare];
      break;
    }
    if (bare == 'أكلت' || bare == 'اكلت') {
      verbIdx = i;
      // «أكلت» من غير تحديد → نستنتج من وقت اليوم.
      slot = now.hour < 12
          ? 'فطار'
          : now.hour < 17
              ? 'غدا'
              : 'عشا';
      break;
    }
  }
  if (verbIdx < 0) return null;
  final descWords = <String>[];
  for (var i = verbIdx + 1; i < tokens.length && descWords.length < 5; i++) {
    final t = tokens[i];
    if (_wordOrDigit(t) != null) continue;
    if (t == 'النهارده' || t == 'دلوقتي') continue;
    descWords.add(t);
  }
  if (descWords.isEmpty) return null;
  return VoiceAction(
    type: VoiceActionType.meal,
    matchName: slot,
    note: descWords.join(' '),
  );
}

VoiceAction? _parseAppointment(List<String> tokens, DateTime now) {
  final kwIdx = _indexWhere(tokens, (t) => t == 'موعد' || t == 'ميعاد');
  if (kwIdx < 0) return null;

  int dayOffset;
  if (tokens.contains('النهارده') || tokens.contains('النهاردة')) {
    dayOffset = 0;
  } else if (tokens.contains('بكرة') || tokens.contains('بكره')) {
    dayOffset = tokens.contains('بعد') ? 2 : 1;
  } else {
    dayOffset = 1; // من غير تحديد → بكرة أسلم من النهارده
  }

  final hourKwIdx =
      _indexWhere(tokens, (t) => t == 'الساعة' || t == 'الساعه' || t == 'ساعة');
  if (hourKwIdx < 0) return null;
  final rawHour = _numberAfter(tokens, hourKwIdx, within: 2);
  if (rawHour == null || rawHour < 1 || rawHour > 12) return null;

  var hour = rawHour.toInt();
  final minutes = tokens.contains('ونص') ? 30 : 0;
  final morning = tokens.contains('الصبح') ||
      tokens.contains('صباحا') ||
      tokens.contains('صباحًا');
  final evening = tokens.contains('بليل') ||
      tokens.contains('مساء') ||
      tokens.contains('مساءً') ||
      tokens.contains('العشا');
  if (!morning && (evening || hour <= 7)) {
    if (hour < 12) hour += 12;
  }

  // العنوان: الكلمات بين «موعد» وكلمة الوقت/اليوم، مع تجاهل كلمات الربط.
  const skip = [
    'عند', 'مع', 'في', 'فى', 'بكرة', 'بكره', 'بعد', 'النهارده', 'النهاردة',
    'الساعة', 'الساعه', 'ساعة', 'الصبح', 'بليل', 'مساء', 'ونص', 'عندي', 'عندى'
  ];
  final titleWords = <String>[];
  for (var i = kwIdx + 1; i < tokens.length && titleWords.length < 4; i++) {
    final t = tokens[i];
    if (skip.contains(t) || _wordOrDigit(t) != null) continue;
    titleWords.add(t);
  }
  final title = titleWords.isEmpty ? 'موعد' : titleWords.join(' ');
  final isHealth = tokens.any(
      (t) => ['دكتور', 'الدكتور', 'كشف', 'عيادة', 'عيادده', 'تحاليل'].contains(t));

  final day = dateOnly(now).add(Duration(days: dayOffset));
  return VoiceAction(
    type: VoiceActionType.appointment,
    title: title,
    category: isHealth ? 'صحة' : 'شخصي',
    when: DateTime(day.year, day.month, day.day, hour, minutes),
  );
}
