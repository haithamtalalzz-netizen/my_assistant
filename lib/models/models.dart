/// الموديلات كلها هنا — كائنات بسيطة بتترجم من/إلى صفوف SQLite.
library;

class Appointment {
  final int? id;
  final String title;
  final String category;
  final DateTime when;
  final String notes;
  final int remindBeforeMin;
  final bool done;

  /// كام مرة اتأجل (اتعدل ميعاده لوقت أبعد) — لكاشف التسويف.
  final int postponeCount;

  /// مدة المشوار بالدقايق — لتنبيه «اتحرك دلوقتي» (0 = مفيش).
  final int travelMin;

  /// نوع التكرار: none/daily/weekly/monthly — الموعد بيتنقل تلقائيًا للمرة الجاية
  /// أول ما يتعمل «تم».
  final String repeat;

  const Appointment({
    this.id,
    required this.title,
    required this.category,
    required this.when,
    this.notes = '',
    this.remindBeforeMin = 60,
    this.done = false,
    this.postponeCount = 0,
    this.travelMin = 0,
    this.repeat = 'none',
  });

  factory Appointment.fromMap(Map<String, Object?> m) => Appointment(
        id: m['id'] as int?,
        title: m['title'] as String,
        category: m['category'] as String,
        when: DateTime.parse(m['when_at'] as String),
        notes: m['notes'] as String? ?? '',
        remindBeforeMin: m['remind_before_min'] as int? ?? 60,
        done: (m['done'] as int? ?? 0) == 1,
        postponeCount: m['postpone_count'] as int? ?? 0,
        travelMin: m['travel_min'] as int? ?? 0,
        repeat: m['repeat'] as String? ?? 'none',
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'category': category,
        'when_at': when.toIso8601String(),
        'notes': notes,
        'remind_before_min': remindBeforeMin,
        'done': done ? 1 : 0,
        'postpone_count': postponeCount,
        'travel_min': travelMin,
        'repeat': repeat,
      };

  bool get isRecurring => repeat != 'none';

  /// الميعاد الجاي بعد [from] حسب نوع التكرار (بيلف لحد ما يعدّي الوقت الحالي).
  DateTime nextOccurrence([DateTime? from]) {
    var d = from ?? when;
    final now = DateTime.now();
    DateTime step(DateTime x) => switch (repeat) {
          'daily' => x.add(const Duration(days: 1)),
          'weekly' => x.add(const Duration(days: 7)),
          'monthly' =>
            DateTime(x.year, x.month + 1, x.day, x.hour, x.minute),
          _ => x.add(const Duration(days: 1)),
        };
    // نلف لحد ما نعدّي دلوقتي عشان لو الموعد فاته كذا مرة.
    d = step(d);
    var guard = 0;
    while (!d.isAfter(now) && guard < 400) {
      d = step(d);
      guard++;
    }
    return d;
  }
}

class Relative {
  final int? id;
  final String name;
  final String phone;
  final int intervalDays;

  /// YYYY-MM-DD آخر اتصال أو null.
  final String? lastContacted;

  const Relative({
    this.id,
    required this.name,
    this.phone = '',
    this.intervalDays = 14,
    this.lastContacted,
  });

  factory Relative.fromMap(Map<String, Object?> m) => Relative(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String? ?? '',
        intervalDays: (m['interval_days'] as num?)?.toInt() ?? 14,
        lastContacted: m['last_contacted'] as String?,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'phone': phone,
        'interval_days': intervalDays,
        'last_contacted': lastContacted,
      };

  DateTime nextDue() {
    final last = lastContacted == null ? null : DateTime.tryParse(lastContacted!);
    if (last == null) return DateTime.now();
    return last.add(Duration(days: intervalDays));
  }

  bool isDue(DateTime now) =>
      !nextDue().isAfter(DateTime(now.year, now.month, now.day));
}

class Challenge {
  final int? id;
  final String name;

  /// YYYY-MM-DD يوم البداية.
  final String startDate;
  final int days;

  const Challenge({
    this.id,
    required this.name,
    required this.startDate,
    this.days = 30,
  });

  factory Challenge.fromMap(Map<String, Object?> m) => Challenge(
        id: m['id'] as int?,
        name: m['name'] as String,
        startDate: m['start_date'] as String,
        days: (m['days'] as num?)?.toInt() ?? 30,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'start_date': startDate,
        'days': days,
      };

  int dayNumber(DateTime now) {
    final start = DateTime.tryParse(startDate);
    if (start == null) return 1;
    return DateTime(now.year, now.month, now.day)
            .difference(DateTime(start.year, start.month, start.day))
            .inDays +
        1;
  }
}

class TimeCapsule {
  final int? id;
  final String message;

  /// YYYY-MM-DD تاريخ الفتح.
  final String openDate;
  final String createdAt;
  final bool opened;

  const TimeCapsule({
    this.id,
    required this.message,
    required this.openDate,
    required this.createdAt,
    this.opened = false,
  });

  factory TimeCapsule.fromMap(Map<String, Object?> m) => TimeCapsule(
        id: m['id'] as int?,
        message: m['message'] as String,
        openDate: m['open_date'] as String,
        createdAt: m['created_at'] as String? ?? '',
        opened: (m['opened'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'message': message,
        'open_date': openDate,
        'created_at': createdAt,
        'opened': opened ? 1 : 0,
      };

  bool isReady(DateTime now) {
    final open = DateTime.tryParse(openDate);
    if (open == null) return false;
    return !open.isAfter(DateTime(now.year, now.month, now.day));
  }
}

class WeeklyReview {
  /// مفتاح الأسبوع = dayKey ليوم الجمعة بتاع الأسبوع ده.
  final String weekKey;
  final String wentWell;
  final String blockedMe;
  final String nextFocus;
  final String createdAt;

  const WeeklyReview({
    required this.weekKey,
    this.wentWell = '',
    this.blockedMe = '',
    this.nextFocus = '',
    required this.createdAt,
  });

  factory WeeklyReview.fromMap(Map<String, Object?> m) => WeeklyReview(
        weekKey: m['week_key'] as String,
        wentWell: m['went_well'] as String? ?? '',
        blockedMe: m['blocked_me'] as String? ?? '',
        nextFocus: m['next_focus'] as String? ?? '',
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'week_key': weekKey,
        'went_well': wentWell,
        'blocked_me': blockedMe,
        'next_focus': nextFocus,
        'created_at': createdAt,
      };
}

class Medication {
  final int? id;
  final String name;
  final String dosage;

  /// أوقات الجرعات بصيغة HH:mm.
  final List<String> times;
  final String notes;
  final bool active;

  /// آخر يوم في الكورس (YYYY-MM-DD) — null يعني دواء مستمر.
  final String? endDate;

  /// نوع الدواء (أقراص/شراب/كريم...) والوحدة (علبة/شريط/سرنجة...).
  final String form;
  final String unit;

  const Medication({
    this.id,
    required this.name,
    this.dosage = '',
    required this.times,
    this.notes = '',
    this.active = true,
    this.endDate,
    this.form = '',
    this.unit = '',
  });

  factory Medication.fromMap(Map<String, Object?> m) {
    final raw = m['times'] as String? ?? '';
    return Medication(
      id: m['id'] as int?,
      name: m['name'] as String,
      dosage: m['dosage'] as String? ?? '',
      times: raw.isEmpty ? [] : raw.split(','),
      notes: m['notes'] as String? ?? '',
      active: (m['active'] as int? ?? 1) == 1,
      endDate: m['end_date'] as String?,
      form: m['form'] as String? ?? '',
      unit: m['unit'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => {
        'name': name,
        'dosage': dosage,
        'times': times.join(','),
        'notes': notes,
        'active': active ? 1 : 0,
        'end_date': endDate,
        'form': form,
        'unit': unit,
      };

  Medication copyWith({bool? active}) => Medication(
        id: id,
        name: name,
        dosage: dosage,
        times: times,
        notes: notes,
        active: active ?? this.active,
        endDate: endDate,
        form: form,
        unit: unit,
      );

  /// الأيام المتبقية في الكورس (شامل النهارده) — null للمستمر.
  int? daysLeft(DateTime now) {
    if (endDate == null) return null;
    final end = DateTime.parse(endDate!);
    return end.difference(DateTime(now.year, now.month, now.day)).inDays + 1;
  }
}

/// دين أو سلفة. direction: 'لى' = الناس ليها عندي (أنا سلفتهم)،
/// 'عليا' = أنا عليّ ليهم (أنا خدت منهم).
class Debt {
  final int? id;
  final String person;
  final double amount;
  final String direction;
  final String note;
  final String createdAt;
  final bool settled;

  const Debt({
    this.id,
    required this.person,
    required this.amount,
    required this.direction,
    this.note = '',
    required this.createdAt,
    this.settled = false,
  });

  bool get theyOweMe => direction == 'لى';

  factory Debt.fromMap(Map<String, Object?> m) => Debt(
        id: m['id'] as int?,
        person: m['person'] as String,
        amount: (m['amount'] as num).toDouble(),
        direction: m['direction'] as String,
        note: m['note'] as String? ?? '',
        createdAt: m['created_at'] as String,
        settled: (m['settled'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'person': person,
        'amount': amount,
        'direction': direction,
        'note': note,
        'created_at': createdAt,
        'settled': settled ? 1 : 0,
      };
}

/// جمعية شهرية: كل شهر تدفع [amount]، ودورك تقبض في الشهر رقم [myTurn]
/// من إجمالي [totalMonths] شهور، بدايةً من [startMonth] (YYYY-MM).
class Gameya {
  final int? id;
  final String name;
  final double amount;
  final int dayOfMonth;
  final int totalMonths;
  final int myTurn;
  final String startMonth;

  const Gameya({
    this.id,
    required this.name,
    required this.amount,
    this.dayOfMonth = 1,
    required this.totalMonths,
    required this.myTurn,
    required this.startMonth,
  });

  factory Gameya.fromMap(Map<String, Object?> m) => Gameya(
        id: m['id'] as int?,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        dayOfMonth: m['day_of_month'] as int? ?? 1,
        totalMonths: m['total_months'] as int,
        myTurn: m['my_turn'] as int,
        startMonth: m['start_month'] as String,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'amount': amount,
        'day_of_month': dayOfMonth,
        'total_months': totalMonths,
        'my_turn': myTurn,
        'start_month': startMonth,
      };

  /// رقم الشهر الحالي في الجمعية (1-based)، أو 0 لو لسه ماابتدتش،
  /// أو أكبر من totalMonths لو خلصت.
  int monthIndex(DateTime now) {
    final parts = startMonth.split('-');
    final startYear = int.parse(parts[0]);
    final startMon = int.parse(parts[1]);
    return (now.year - startYear) * 12 + (now.month - startMon) + 1;
  }

  bool isActive(DateTime now) {
    final idx = monthIndex(now);
    return idx >= 1 && idx <= totalMonths;
  }

  /// كام شهر فاضل على دورك (0 = دورك الشهر ده، سالب = عدّى).
  int monthsUntilMyTurn(DateTime now) => myTurn - monthIndex(now);

  /// إجمالي اللي هتقبضه يوم دورك.
  double get payout => amount * totalMonths;
}

class HomeMaintenance {
  final int? id;
  final String name;
  final int intervalMonths;

  /// آخر مرة اتعملت (YYYY-MM-DD).
  final String lastDone;
  final String notes;

  const HomeMaintenance({
    this.id,
    required this.name,
    required this.intervalMonths,
    required this.lastDone,
    this.notes = '',
  });

  factory HomeMaintenance.fromMap(Map<String, Object?> m) => HomeMaintenance(
        id: m['id'] as int?,
        name: m['name'] as String,
        intervalMonths: m['interval_months'] as int,
        lastDone: m['last_done'] as String,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'interval_months': intervalMonths,
        'last_done': lastDone,
        'notes': notes,
      };

  DateTime nextDue() {
    final last = DateTime.parse(lastDone);
    return DateTime(last.year, last.month + intervalMonths, last.day);
  }

  bool isDue(DateTime now) =>
      !nextDue().isAfter(DateTime(now.year, now.month, now.day));

  int daysUntilDue(DateTime now) =>
      nextDue().difference(DateTime(now.year, now.month, now.day)).inDays;
}

class InboxNote {
  final int? id;
  final String text;
  final String createdAt;

  const InboxNote({this.id, required this.text, required this.createdAt});

  factory InboxNote.fromMap(Map<String, Object?> m) => InboxNote(
        id: m['id'] as int?,
        text: m['text'] as String,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'text': text,
        'created_at': createdAt,
      };
}

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String note;

  /// YYYY-MM-DD.
  final String day;

  /// المحفظة اللي اتصرف منها (null = غير محدد).
  final int? walletId;

  const Expense({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.day,
    this.walletId,
  });

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] as String,
        note: m['note'] as String? ?? '',
        day: m['day'] as String,
        walletId: m['wallet_id'] as int?,
      );

  Map<String, Object?> toMap() => {
        'amount': amount,
        'category': category,
        'note': note,
        'day': day,
        'wallet_id': walletId,
      };
}

class Income {
  final int? id;
  final double amount;

  /// مصدر الدخل: مرتب / عمل حر / مكافأة / بيع / أخرى (قيمة مخزّنة عربي).
  final String source;
  final String note;

  /// YYYY-MM-DD.
  final String day;

  /// المحفظة اللي دخل فيها (null = غير محدد).
  final int? walletId;

  const Income({
    this.id,
    required this.amount,
    required this.source,
    this.note = '',
    required this.day,
    this.walletId,
  });

  factory Income.fromMap(Map<String, Object?> m) => Income(
        id: m['id'] as int?,
        amount: (m['amount'] as num).toDouble(),
        source: m['source'] as String,
        note: m['note'] as String? ?? '',
        day: m['day'] as String,
        walletId: m['wallet_id'] as int?,
      );

  Map<String, Object?> toMap() => {
        'amount': amount,
        'source': source,
        'note': note,
        'day': day,
        'wallet_id': walletId,
      };
}

class RecurringIncome {
  final int? id;
  final String source;
  final double amount;

  /// يوم القبض من الشهر (1..28).
  final int dayOfMonth;

  /// آخر شهر اتقبض فيه بصيغة YYYY-MM — فاضي لو عمره مااتقبض.
  final String lastReceivedMonth;

  const RecurringIncome({
    this.id,
    required this.source,
    required this.amount,
    required this.dayOfMonth,
    this.lastReceivedMonth = '',
  });

  factory RecurringIncome.fromMap(Map<String, Object?> m) => RecurringIncome(
        id: m['id'] as int?,
        source: m['source'] as String,
        amount: (m['amount'] as num).toDouble(),
        dayOfMonth: m['day_of_month'] as int,
        lastReceivedMonth: m['last_received_month'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'source': source,
        'amount': amount,
        'day_of_month': dayOfMonth,
        'last_received_month': lastReceivedMonth,
      };

  /// مستحق الشهر ده: يومه جه ولسه مااتقبضش الشهر ده.
  bool isDue(DateTime now) {
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    return now.day >= dayOfMonth && lastReceivedMonth != monthKey;
  }
}

class PharmacyItem {
  final int? id;
  final String name;
  final int quantity;

  /// YYYY-MM-DD أو null.
  final String? expiry;
  final String notes;

  const PharmacyItem({
    this.id,
    required this.name,
    this.quantity = 1,
    this.expiry,
    this.notes = '',
  });

  factory PharmacyItem.fromMap(Map<String, Object?> m) => PharmacyItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        expiry: m['expiry'] as String?,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'quantity': quantity,
        'expiry': expiry,
        'notes': notes,
      };
}

/// دفعة من دواء في الصيدلية — كمية بتاريخ صلاحية مستقل (لو نفس الدوا بصلاحيات مختلفة).
class PharmacyBatch {
  final int? id;
  final int itemId;
  final int quantity;

  /// YYYY-MM-DD أو null.
  final String? expiry;

  const PharmacyBatch({
    this.id,
    required this.itemId,
    this.quantity = 1,
    this.expiry,
  });

  factory PharmacyBatch.fromMap(Map<String, Object?> m) => PharmacyBatch(
        id: m['id'] as int?,
        itemId: m['item_id'] as int,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        expiry: m['expiry'] as String?,
      );

  Map<String, Object?> toMap() => {
        'item_id': itemId,
        'quantity': quantity,
        'expiry': expiry,
      };
}

class Warranty {
  final int? id;
  final String itemName;

  /// YYYY-MM-DD.
  final String purchaseDate;
  final int warrantyMonths;
  final String photo;
  final String notes;

  const Warranty({
    this.id,
    required this.itemName,
    required this.purchaseDate,
    required this.warrantyMonths,
    this.photo = '',
    this.notes = '',
  });

  factory Warranty.fromMap(Map<String, Object?> m) => Warranty(
        id: m['id'] as int?,
        itemName: m['item_name'] as String,
        purchaseDate: m['purchase_date'] as String,
        warrantyMonths: (m['warranty_months'] as num).toInt(),
        photo: m['photo'] as String? ?? '',
        notes: m['notes'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'item_name': itemName,
        'purchase_date': purchaseDate,
        'warranty_months': warrantyMonths,
        'photo': photo,
        'notes': notes,
      };

  /// تاريخ انتهاء الضمان.
  DateTime get expiry {
    final start = DateTime.tryParse(purchaseDate) ?? DateTime.now();
    return DateTime(start.year, start.month + warrantyMonths, start.day);
  }
}

class MeterReading {
  final int? id;

  /// electricity / water / gas.
  final String meterType;
  final double reading;
  final double? cost;

  /// YYYY-MM-DD.
  final String day;

  const MeterReading({
    this.id,
    required this.meterType,
    required this.reading,
    this.cost,
    required this.day,
  });

  factory MeterReading.fromMap(Map<String, Object?> m) => MeterReading(
        id: m['id'] as int?,
        meterType: m['meter_type'] as String,
        reading: (m['reading'] as num).toDouble(),
        cost: (m['cost'] as num?)?.toDouble(),
        day: m['day'] as String,
      );

  Map<String, Object?> toMap() => {
        'meter_type': meterType,
        'reading': reading,
        'cost': cost,
        'day': day,
      };
}

class Wallet {
  final int? id;
  final String name;

  /// cash / bank / mobile / other.
  final String type;
  final double openingBalance;

  const Wallet({
    this.id,
    required this.name,
    this.type = 'cash',
    this.openingBalance = 0,
  });

  factory Wallet.fromMap(Map<String, Object?> m) => Wallet(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String? ?? 'cash',
        openingBalance: (m['opening_balance'] as num?)?.toDouble() ?? 0,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type,
        'opening_balance': openingBalance,
      };
}

class WalletTransfer {
  final int? id;
  final int fromWallet;
  final int toWallet;
  final double amount;

  /// YYYY-MM-DD.
  final String day;

  const WalletTransfer({
    this.id,
    required this.fromWallet,
    required this.toWallet,
    required this.amount,
    required this.day,
  });

  factory WalletTransfer.fromMap(Map<String, Object?> m) => WalletTransfer(
        id: m['id'] as int?,
        fromWallet: m['from_wallet'] as int,
        toWallet: m['to_wallet'] as int,
        amount: (m['amount'] as num).toDouble(),
        day: m['day'] as String,
      );

  Map<String, Object?> toMap() => {
        'from_wallet': fromWallet,
        'to_wallet': toWallet,
        'amount': amount,
        'day': day,
      };
}

/// أصل خارجي (فلوس مش سائلة): دهب / عقار / استثمار / شهادة / فلوس برّه / أخرى.
class Asset {
  final int? id;
  final String name;

  /// gold / property / investment / certificate / cash / other.
  final String type;
  final double value;
  final String note;

  const Asset({
    this.id,
    required this.name,
    this.type = 'gold',
    this.value = 0,
    this.note = '',
  });

  factory Asset.fromMap(Map<String, Object?> m) => Asset(
        id: m['id'] as int?,
        name: m['name'] as String,
        type: m['type'] as String? ?? 'gold',
        value: (m['value'] as num?)?.toDouble() ?? 0,
        note: m['note'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'type': type,
        'value': value,
        'note': note,
      };
}

/// نبتة بيت — بتتابع مواعيد الري كل كام يوم.
class Plant {
  final int? id;
  final String name;

  /// مكان النبتة (بلكونة/صالة/مطبخ...).
  final String location;
  final int waterIntervalDays;

  /// YYYY-MM-DD آخر ري أو null.
  final String? lastWatered;
  final String note;

  const Plant({
    this.id,
    required this.name,
    this.location = '',
    this.waterIntervalDays = 3,
    this.lastWatered,
    this.note = '',
  });

  factory Plant.fromMap(Map<String, Object?> m) => Plant(
        id: m['id'] as int?,
        name: m['name'] as String,
        location: m['location'] as String? ?? '',
        waterIntervalDays: (m['water_interval_days'] as num?)?.toInt() ?? 3,
        lastWatered: m['last_watered'] as String?,
        note: m['note'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'location': location,
        'water_interval_days': waterIntervalDays,
        'last_watered': lastWatered,
        'note': note,
      };

  DateTime nextWater() {
    final last = lastWatered == null ? null : DateTime.tryParse(lastWatered!);
    if (last == null) return DateTime.now();
    return last.add(Duration(days: waterIntervalDays));
  }

  bool isDue(DateTime now) =>
      !nextWater().isAfter(DateTime(now.year, now.month, now.day));
}

class Diary {
  final int? id;

  /// YYYY-MM-DD.
  final String day;
  final String text;
  final String createdAt;

  const Diary({
    this.id,
    required this.day,
    required this.text,
    required this.createdAt,
  });

  factory Diary.fromMap(Map<String, Object?> m) => Diary(
        id: m['id'] as int?,
        day: m['day'] as String,
        text: m['text'] as String,
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'text': text,
        'created_at': createdAt,
      };
}

class Recipe {
  final int? id;
  final String name;
  final String photo;

  /// مقادير مفصولة بسطر جديد.
  final String ingredients;
  final String steps;

  const Recipe({
    this.id,
    required this.name,
    this.photo = '',
    this.ingredients = '',
    this.steps = '',
  });

  factory Recipe.fromMap(Map<String, Object?> m) => Recipe(
        id: m['id'] as int?,
        name: m['name'] as String,
        photo: m['photo'] as String? ?? '',
        ingredients: m['ingredients'] as String? ?? '',
        steps: m['steps'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'photo': photo,
        'ingredients': ingredients,
        'steps': steps,
      };

  List<String> get ingredientList => ingredients
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

class QuranReview {
  final int? id;

  /// السورة أو الجزء (مثلًا: البقرة، جزء عم).
  final String portion;

  /// YYYY-MM-DD آخر مراجعة أو null (لسه مااتراجعتش).
  final String? lastReviewed;

  /// كل كام يوم تتراجع (بيكبر مع كل مراجعة ناجحة).
  final int intervalDays;
  final int reps;

  const QuranReview({
    this.id,
    required this.portion,
    this.lastReviewed,
    this.intervalDays = 1,
    this.reps = 0,
  });

  factory QuranReview.fromMap(Map<String, Object?> m) => QuranReview(
        id: m['id'] as int?,
        portion: m['portion'] as String,
        lastReviewed: m['last_reviewed'] as String?,
        intervalDays: (m['interval_days'] as num?)?.toInt() ?? 1,
        reps: (m['reps'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toMap() => {
        'portion': portion,
        'last_reviewed': lastReviewed,
        'interval_days': intervalDays,
        'reps': reps,
      };

  /// تاريخ المراجعة الجاية.
  DateTime nextDue() {
    final last = lastReviewed == null ? null : DateTime.tryParse(lastReviewed!);
    if (last == null) return DateTime.now();
    return last.add(Duration(days: intervalDays));
  }

  bool isDue(DateTime now) =>
      !nextDue().isAfter(DateTime(now.year, now.month, now.day));
}

class SecretNote {
  final int? id;
  final String title;
  final String body;
  final String createdAt;

  const SecretNote({
    this.id,
    required this.title,
    this.body = '',
    required this.createdAt,
  });

  factory SecretNote.fromMap(Map<String, Object?> m) => SecretNote(
        id: m['id'] as int?,
        title: m['title'] as String,
        body: m['body'] as String? ?? '',
        createdAt: m['created_at'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'body': body,
        'created_at': createdAt,
      };
}

class QuitCounter {
  final int? id;
  final String name;

  /// YYYY-MM-DD يوم البداية (آخر مرة).
  final String startDate;

  /// التوفير اليومي التقديري (ج.م).
  final double dailySaving;

  const QuitCounter({
    this.id,
    required this.name,
    required this.startDate,
    this.dailySaving = 0,
  });

  factory QuitCounter.fromMap(Map<String, Object?> m) => QuitCounter(
        id: m['id'] as int?,
        name: m['name'] as String,
        startDate: m['start_date'] as String,
        dailySaving: (m['daily_saving'] as num?)?.toDouble() ?? 0,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'start_date': startDate,
        'daily_saving': dailySaving,
      };

  int daysSince(DateTime now) {
    final start = DateTime.tryParse(startDate);
    if (start == null) return 0;
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime(start.year, start.month, start.day))
        .inDays;
  }

  double savedSoFar(DateTime now) => daysSince(now) * dailySaving;
}

class SocialObligation {
  final int? id;
  final String person;

  /// naqoot (نقوط) / ozooma (عزومة) / eidiya (عيدية) / other (أخرى).
  final String type;

  /// given (إنت قدّمت) / received (اتقدملك).
  final String direction;

  /// المبلغ (اختياري — العزومة ممكن تكون من غير فلوس).
  final double? amount;
  final String occasion;

  /// YYYY-MM-DD.
  final String day;
  final String notes;

  /// اترد الواجب (رددته لو اتقدملك، أو اترد لك لو قدّمته).
  final bool reciprocated;

  const SocialObligation({
    this.id,
    required this.person,
    required this.type,
    required this.direction,
    this.amount,
    this.occasion = '',
    required this.day,
    this.notes = '',
    this.reciprocated = false,
  });

  factory SocialObligation.fromMap(Map<String, Object?> m) => SocialObligation(
        id: m['id'] as int?,
        person: m['person'] as String,
        type: m['type'] as String,
        direction: m['direction'] as String,
        amount: (m['amount'] as num?)?.toDouble(),
        occasion: m['occasion'] as String? ?? '',
        day: m['day'] as String,
        notes: m['notes'] as String? ?? '',
        reciprocated: (m['reciprocated'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'person': person,
        'type': type,
        'direction': direction,
        'amount': amount,
        'occasion': occasion,
        'day': day,
        'notes': notes,
        'reciprocated': reciprocated ? 1 : 0,
      };
}

class BodyProgress {
  final int? id;

  /// YYYY-MM-DD.
  final String day;
  final double? weight;
  final double? waist;
  final double? chest;
  final double? arms;
  final String photo;

  const BodyProgress({
    this.id,
    required this.day,
    this.weight,
    this.waist,
    this.chest,
    this.arms,
    this.photo = '',
  });

  factory BodyProgress.fromMap(Map<String, Object?> m) => BodyProgress(
        id: m['id'] as int?,
        day: m['day'] as String,
        weight: (m['weight'] as num?)?.toDouble(),
        waist: (m['waist'] as num?)?.toDouble(),
        chest: (m['chest'] as num?)?.toDouble(),
        arms: (m['arms'] as num?)?.toDouble(),
        photo: m['photo'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'weight': weight,
        'waist': waist,
        'chest': chest,
        'arms': arms,
        'photo': photo,
      };
}

class SavingsGoal {
  final int? id;
  final String name;
  final double target;

  /// مجموع المدفوع (بيتحسب من المساهمات).
  final double saved;
  final String createdAt;

  /// YYYY-MM-DD أو null.
  final String? deadline;

  const SavingsGoal({
    this.id,
    required this.name,
    required this.target,
    this.saved = 0,
    required this.createdAt,
    this.deadline,
  });

  factory SavingsGoal.fromMap(Map<String, Object?> m) => SavingsGoal(
        id: m['id'] as int?,
        name: m['name'] as String,
        target: (m['target'] as num).toDouble(),
        saved: (m['saved'] as num?)?.toDouble() ?? 0,
        createdAt: m['created_at'] as String? ?? '',
        deadline: m['deadline'] as String?,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'target': target,
        'created_at': createdAt,
        'deadline': deadline,
      };

  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1);
  double get remaining => (target - saved).clamp(0, double.infinity);
}

class ClothingItem {
  final int? id;
  final String name;

  /// خانة اللبس: top / bottom / outer / shoes / accessory.
  final String category;
  final String color;

  /// all / summer / winter.
  final String season;

  /// casual / formal / sport.
  final String formality;
  final String photo;

  /// آخر يوم اتلبست فيه (YYYY-MM-DD) أو null.
  final String? lastWorn;
  final bool favorite;

  const ClothingItem({
    this.id,
    required this.name,
    required this.category,
    this.color = '',
    this.season = 'all',
    this.formality = 'casual',
    this.photo = '',
    this.lastWorn,
    this.favorite = false,
  });

  factory ClothingItem.fromMap(Map<String, Object?> m) => ClothingItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        category: m['category'] as String,
        color: m['color'] as String? ?? '',
        season: m['season'] as String? ?? 'all',
        formality: m['formality'] as String? ?? 'casual',
        photo: m['photo'] as String? ?? '',
        lastWorn: m['last_worn'] as String?,
        favorite: (m['favorite'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'category': category,
        'color': color,
        'season': season,
        'formality': formality,
        'photo': photo,
        'last_worn': lastWorn,
        'favorite': favorite ? 1 : 0,
      };
}

class GymSession {
  final int? id;

  /// YYYY-MM-DD.
  final String day;

  /// اسم الوضع/اليوم (مثلًا: Push، Pull، Legs، كارديو).
  final String program;
  final int durationMin;
  final String notes;

  const GymSession({
    this.id,
    required this.day,
    this.program = '',
    this.durationMin = 0,
    this.notes = '',
  });

  factory GymSession.fromMap(Map<String, Object?> m) => GymSession(
        id: m['id'] as int?,
        day: m['day'] as String,
        program: m['program'] as String? ?? '',
        durationMin: (m['duration_min'] as num?)?.toInt() ?? 0,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'program': program,
        'duration_min': durationMin,
        'notes': notes,
      };
}

class GymSet {
  final int? id;
  final int sessionId;
  final String exercise;
  final int reps;
  final double weight;
  final int setIndex;

  const GymSet({
    this.id,
    required this.sessionId,
    required this.exercise,
    required this.reps,
    required this.weight,
    required this.setIndex,
  });

  factory GymSet.fromMap(Map<String, Object?> m) => GymSet(
        id: m['id'] as int?,
        sessionId: m['session_id'] as int,
        exercise: m['exercise'] as String,
        reps: (m['reps'] as num).toInt(),
        weight: (m['weight'] as num).toDouble(),
        setIndex: (m['set_index'] as num).toInt(),
      );

  Map<String, Object?> toMap() => {
        'session_id': sessionId,
        'exercise': exercise,
        'reps': reps,
        'weight': weight,
        'set_index': setIndex,
      };
}

class MedicalRecord {
  final int? id;

  /// visit (زيارة) / lab (تحاليل) / imaging (أشعة) / procedure (إجراء).
  final String type;

  /// YYYY-MM-DD.
  final String day;
  final String title;

  /// الطبيب أو المكان (عيادة/مستشفى/معمل).
  final String provider;
  final String specialty;

  /// النتيجة/القيم/التشخيص/الملاحظات.
  final String result;
  final double cost;

  /// مسارات الصور المرفقة (روشتة/تقرير/أشعة).
  final List<String> photos;

  const MedicalRecord({
    this.id,
    required this.type,
    required this.day,
    required this.title,
    this.provider = '',
    this.specialty = '',
    this.result = '',
    this.cost = 0,
    this.photos = const [],
  });

  factory MedicalRecord.fromMap(Map<String, Object?> m) => MedicalRecord(
        id: m['id'] as int?,
        type: m['type'] as String,
        day: m['day'] as String,
        title: m['title'] as String,
        provider: m['provider'] as String? ?? '',
        specialty: m['specialty'] as String? ?? '',
        result: m['result'] as String? ?? '',
        cost: (m['cost'] as num?)?.toDouble() ?? 0,
        photos: (m['photos'] as String? ?? '')
            .split('\n')
            .where((s) => s.isNotEmpty)
            .toList(),
      );

  Map<String, Object?> toMap() => {
        'type': type,
        'day': day,
        'title': title,
        'provider': provider,
        'specialty': specialty,
        'result': result,
        'cost': cost,
        'photos': photos.join('\n'),
      };
}

class DocItem {
  final int? id;
  final String title;
  final String imagePath;

  /// YYYY-MM-DD أو null لو المستند من غير تاريخ انتهاء.
  final String? expiry;
  final int remindDays;
  final String notes;

  const DocItem({
    this.id,
    required this.title,
    this.imagePath = '',
    this.expiry,
    this.remindDays = 30,
    this.notes = '',
  });

  factory DocItem.fromMap(Map<String, Object?> m) => DocItem(
        id: m['id'] as int?,
        title: m['title'] as String,
        imagePath: m['image_path'] as String? ?? '',
        expiry: m['expiry'] as String?,
        remindDays: m['remind_days'] as int? ?? 30,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'image_path': imagePath,
        'expiry': expiry,
        'remind_days': remindDays,
        'notes': notes,
      };
}

class Meal {
  final int? id;

  /// YYYY-MM-DD.
  final String day;

  /// فطار / غدا / عشا / سناك / سحور.
  final String slot;
  final String description;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  /// الكمية بالجرام/المل (اختياري — لو الوجبة اتسجّلت من قاعدة الأكل).
  final double? grams;

  const Meal({
    this.id,
    required this.day,
    required this.slot,
    required this.description,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.grams,
  });

  factory Meal.fromMap(Map<String, Object?> m) => Meal(
        id: m['id'] as int?,
        day: m['day'] as String,
        slot: m['slot'] as String,
        description: m['description'] as String,
        calories: (m['calories'] as num?)?.toDouble(),
        protein: (m['protein'] as num?)?.toDouble(),
        carbs: (m['carbs'] as num?)?.toDouble(),
        fat: (m['fat'] as num?)?.toDouble(),
        grams: (m['grams'] as num?)?.toDouble(),
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'slot': slot,
        'description': description,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'grams': grams,
      };
}

/// جلسة نشاط بالـGPS (مشي/جري) — مسافة ومدة وسعرات.
class ActivitySession {
  final int? id;
  final String day;
  final String type; // 'walk' / 'run'
  final double distanceKm;
  final int durationSec;
  final int calories;
  final int steps;
  final String createdAt;

  const ActivitySession({
    this.id,
    required this.day,
    required this.type,
    required this.distanceKm,
    required this.durationSec,
    required this.calories,
    this.steps = 0,
    required this.createdAt,
  });

  factory ActivitySession.fromMap(Map<String, Object?> m) => ActivitySession(
        id: m['id'] as int?,
        day: m['day'] as String,
        type: m['type'] as String? ?? 'walk',
        distanceKm: (m['distance_km'] as num?)?.toDouble() ?? 0,
        durationSec: (m['duration_sec'] as num?)?.toInt() ?? 0,
        calories: (m['calories'] as num?)?.toInt() ?? 0,
        steps: (m['steps'] as num?)?.toInt() ?? 0,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'type': type,
        'distance_km': distanceKm,
        'duration_sec': durationSec,
        'calories': calories,
        'steps': steps,
        'created_at': createdAt,
      };
}

/// بداية دورة شهرية مسجّلة (للسيدات).
class CycleLog {
  final int? id;
  final String startDay; // YYYY-MM-DD
  final int periodDays; // مدة نزول الدم التقريبية
  final String notes;
  final String createdAt;

  const CycleLog({
    this.id,
    required this.startDay,
    this.periodDays = 5,
    this.notes = '',
    required this.createdAt,
  });

  factory CycleLog.fromMap(Map<String, Object?> m) => CycleLog(
        id: m['id'] as int?,
        startDay: m['start_day'] as String,
        periodDays: (m['period_days'] as num?)?.toInt() ?? 5,
        notes: m['notes'] as String? ?? '',
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'start_day': startDay,
        'period_days': periodDays,
        'notes': notes,
        'created_at': createdAt,
      };
}

/// تسجيل يومي للدورة (مزاج/أعراض/شدة نزيف/وزن/ملاحظة/علاقة).
class CycleDay {
  final String day; // YYYY-MM-DD
  final String mood;

  /// أعراض بصيغة `key:severity` مفصولة بفاصلة (severity 1/2/3).
  /// الصيغة القديمة `key` (بدون شدة) تُقرأ كشدة متوسطة (2).
  final String symptoms;
  final String flow;
  final double? weight;
  final String note;
  final bool intimacy;

  const CycleDay({
    required this.day,
    this.mood = '',
    this.symptoms = '',
    this.flow = '',
    this.weight,
    this.note = '',
    this.intimacy = false,
  });

  /// مفاتيح الأعراض فقط (بدون الشدة) — للتوافق مع التحليل والتقارير.
  List<String> get symptomList => symptomMap.keys.toList();

  /// خريطة العرض → الشدة (1 خفيف / 2 متوسط / 3 شديد).
  Map<String, int> get symptomMap {
    final out = <String, int>{};
    for (final part in symptoms.split(',')) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final bits = p.split(':');
      final key = bits[0];
      final sev = bits.length > 1 ? int.tryParse(bits[1]) ?? 2 : 2;
      out[key] = sev.clamp(1, 3);
    }
    return out;
  }

  static String encodeSymptoms(Map<String, int> m) =>
      m.entries.map((e) => '${e.key}:${e.value}').join(',');

  factory CycleDay.fromMap(Map<String, Object?> m) => CycleDay(
        day: m['day'] as String,
        mood: m['mood'] as String? ?? '',
        symptoms: m['symptoms'] as String? ?? '',
        flow: m['flow'] as String? ?? '',
        weight: (m['weight'] as num?)?.toDouble(),
        note: m['note'] as String? ?? '',
        intimacy: (m['intimacy'] as num?)?.toInt() == 1,
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'mood': mood,
        'symptoms': symptoms,
        'flow': flow,
        'weight': weight,
        'note': note,
        'intimacy': intimacy ? 1 : 0,
      };
}

class ShoppingItem {
  final int? id;
  final String name;
  final bool checked;
  final String createdAt;

  const ShoppingItem({
    this.id,
    required this.name,
    this.checked = false,
    required this.createdAt,
  });

  factory ShoppingItem.fromMap(Map<String, Object?> m) => ShoppingItem(
        id: m['id'] as int?,
        name: m['name'] as String,
        checked: (m['checked'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'checked': checked ? 1 : 0,
        'created_at': createdAt,
      };
}

class Occasion {
  final int? id;
  final String title;
  final String person;

  /// مناسبة سنوية: شهر ويوم بس.
  final int month;
  final int day;
  final int remindDays;

  const Occasion({
    this.id,
    required this.title,
    this.person = '',
    required this.month,
    required this.day,
    this.remindDays = 1,
  });

  factory Occasion.fromMap(Map<String, Object?> m) => Occasion(
        id: m['id'] as int?,
        title: m['title'] as String,
        person: m['person'] as String? ?? '',
        month: m['month'] as int,
        day: m['day'] as int,
        remindDays: m['remind_days'] as int? ?? 1,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'person': person,
        'month': month,
        'day': day,
        'remind_days': remindDays,
      };

  /// أقرب حدوث جاي للمناسبة (النهارده محسوب جاي).
  DateTime nextOccurrence(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var candidate = DateTime(now.year, month, day);
    if (candidate.isBefore(today)) {
      candidate = DateTime(now.year + 1, month, day);
    }
    return candidate;
  }
}

/// فاتورة دورية شهرية — بتتسجل مرة واحدة وبتتدفع بضغطة كل شهر.
class RecurringBill {
  final int? id;
  final String name;
  final double amount;

  /// يوم الاستحقاق من الشهر (1..28).
  final int dayOfMonth;
  final String category;

  /// آخر شهر اتدفعت فيه بصيغة YYYY-MM — فاضي لو عمرها مااتدفعت.
  final String lastPaidMonth;

  const RecurringBill({
    this.id,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    this.category = 'فواتير',
    this.lastPaidMonth = '',
  });

  factory RecurringBill.fromMap(Map<String, Object?> m) => RecurringBill(
        id: m['id'] as int?,
        name: m['name'] as String,
        amount: (m['amount'] as num).toDouble(),
        dayOfMonth: m['day_of_month'] as int,
        category: m['category'] as String? ?? 'فواتير',
        lastPaidMonth: m['last_paid_month'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'amount': amount,
        'day_of_month': dayOfMonth,
        'category': category,
        'last_paid_month': lastPaidMonth,
      };

  /// مستحقة الشهر ده: يومها جه ولسه مااتدفعتش الشهر ده.
  bool isDue(DateTime now) {
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    return now.day >= dayOfMonth && lastPaidMonth != monthKey;
  }
}

/// قياس صحي: ضغط (value/value2) أو سكر أو وزن أو حرارة.
class Measurement {
  final int? id;
  final String day;

  /// ضغط / سكر / وزن / حرارة.
  final String type;
  final double value;

  /// للضغط: الرقم التاني (الانبساطي).
  final double? value2;
  final String unit;

  const Measurement({
    this.id,
    required this.day,
    required this.type,
    required this.value,
    this.value2,
    this.unit = '',
  });

  factory Measurement.fromMap(Map<String, Object?> m) => Measurement(
        id: m['id'] as int?,
        day: m['day'] as String,
        type: m['type'] as String,
        value: (m['value'] as num).toDouble(),
        value2: (m['value2'] as num?)?.toDouble(),
        unit: m['unit'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
        'day': day,
        'type': type,
        'value': value,
        'value2': value2,
        'unit': unit,
      };

  String display() {
    final v = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    if (value2 != null) {
      final v2 = value2! == value2!.roundToDouble()
          ? value2!.toInt().toString()
          : value2!.toStringAsFixed(1);
      return '$v/$v2';
    }
    return unit.isEmpty ? v : '$v $unit';
  }
}

class Habit {
  final int? id;
  final String name;
  final bool archived;
  final String createdAt;

  const Habit({
    this.id,
    required this.name,
    this.archived = false,
    required this.createdAt,
  });

  factory Habit.fromMap(Map<String, Object?> m) => Habit(
        id: m['id'] as int?,
        name: m['name'] as String,
        archived: (m['archived'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'archived': archived ? 1 : 0,
        'created_at': createdAt,
      };
}

/// مشروع يجمع مهام.
class Project {
  final int? id;
  final String name;
  final int color;
  final bool archived;
  final String createdAt;

  const Project({
    this.id,
    required this.name,
    this.color = 0,
    this.archived = false,
    required this.createdAt,
  });

  factory Project.fromMap(Map<String, Object?> m) => Project(
        id: m['id'] as int?,
        name: m['name'] as String,
        color: (m['color'] as int?) ?? 0,
        archived: (m['archived'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'color': color,
        'archived': archived ? 1 : 0,
        'created_at': createdAt,
      };
}

/// مهمة — عنوان + أولوية + موعد اختيارى + مشروع اختيارى.
class Task {
  final int? id;
  final int? projectId;
  final String title;
  final String notes;

  /// ISO datetime أو null.
  final String? dueAt;

  /// 0 منخفضة، 1 عادية، 2 عالية.
  final int priority;
  final bool done;
  final String? doneAt;
  final String createdAt;

  const Task({
    this.id,
    this.projectId,
    required this.title,
    this.notes = '',
    this.dueAt,
    this.priority = 1,
    this.done = false,
    this.doneAt,
    required this.createdAt,
  });

  DateTime? get due => dueAt == null ? null : DateTime.tryParse(dueAt!);
  bool get overdue =>
      !done && due != null && due!.isBefore(DateTime.now());

  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id'] as int?,
        projectId: m['project_id'] as int?,
        title: m['title'] as String,
        notes: m['notes'] as String? ?? '',
        dueAt: m['due_at'] as String?,
        priority: (m['priority'] as int?) ?? 1,
        done: (m['done'] as int? ?? 0) == 1,
        doneAt: m['done_at'] as String?,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'project_id': projectId,
        'title': title,
        'notes': notes,
        'due_at': dueAt,
        'priority': priority,
        'done': done ? 1 : 0,
        'done_at': doneAt,
        'created_at': createdAt,
      };
}

/// اشتراك دورى (نتفليكس/جيم/إنترنت…) — شهرى أو سنوى.
class Subscription {
  final int? id;
  final String name;
  final double amount;

  /// monthly / yearly.
  final String cycle;
  final int dayOfMonth;
  final String category;
  final bool active;
  final String notes;
  final String lastPaidMonth;
  final String createdAt;

  const Subscription({
    this.id,
    required this.name,
    this.amount = 0,
    this.cycle = 'monthly',
    this.dayOfMonth = 1,
    this.category = '',
    this.active = true,
    this.notes = '',
    this.lastPaidMonth = '',
    required this.createdAt,
  });

  /// التكلفة الشهرية المكافئة (السنوى ÷ ١٢).
  double get monthlyCost => cycle == 'yearly' ? amount / 12 : amount;

  factory Subscription.fromMap(Map<String, Object?> m) => Subscription(
        id: m['id'] as int?,
        name: m['name'] as String,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        cycle: m['cycle'] as String? ?? 'monthly',
        dayOfMonth: (m['day_of_month'] as int?) ?? 1,
        category: m['category'] as String? ?? '',
        active: (m['active'] as int? ?? 1) == 1,
        notes: m['notes'] as String? ?? '',
        lastPaidMonth: m['last_paid_month'] as String? ?? '',
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'name': name,
        'amount': amount,
        'cycle': cycle,
        'day_of_month': dayOfMonth,
        'category': category,
        'active': active ? 1 : 0,
        'notes': notes,
        'last_paid_month': lastPaidMonth,
        'created_at': createdAt,
      };
}

/// هدف بمعالم (milestones).
class Goal {
  final int? id;
  final String title;
  final String notes;

  /// ISO date أو null.
  final String? targetDate;
  final bool done;
  final String createdAt;

  const Goal({
    this.id,
    required this.title,
    this.notes = '',
    this.targetDate,
    this.done = false,
    required this.createdAt,
  });

  DateTime? get target =>
      targetDate == null ? null : DateTime.tryParse(targetDate!);

  factory Goal.fromMap(Map<String, Object?> m) => Goal(
        id: m['id'] as int?,
        title: m['title'] as String,
        notes: m['notes'] as String? ?? '',
        targetDate: m['target_date'] as String?,
        done: (m['done'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as String,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'notes': notes,
        'target_date': targetDate,
        'done': done ? 1 : 0,
        'created_at': createdAt,
      };
}

/// معلم داخل هدف.
class GoalMilestone {
  final int? id;
  final int goalId;
  final String title;
  final bool done;
  final int sort;

  const GoalMilestone({
    this.id,
    required this.goalId,
    required this.title,
    this.done = false,
    this.sort = 0,
  });

  factory GoalMilestone.fromMap(Map<String, Object?> m) => GoalMilestone(
        id: m['id'] as int?,
        goalId: m['goal_id'] as int,
        title: m['title'] as String,
        done: (m['done'] as int? ?? 0) == 1,
        sort: (m['sort'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        'goal_id': goalId,
        'title': title,
        'done': done ? 1 : 0,
        'sort': sort,
      };
}
