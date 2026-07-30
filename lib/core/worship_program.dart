// «برنامجى الدينى» — منطق نقى قابل للاختبار: بيحوّل بيانات العبادات المتفرّقة
// (صلوات/أذكار/ورد قرآن/سنن/حفظ/صدقة) لخطة يوم واحدة بنسبة إنجاز ومستوى.
// مافيش أى استعلام قاعدة بيانات هنا — الشاشة بتجمع الأرقام وتمرّرها.

/// بند واحد فى خطة اليوم.
class ProgramTask {
  final String id;
  final String title;
  final String emoji;

  /// المُنجَز والمطلوب (مثلاً ٣ من ٥ صلوات).
  final int done;
  final int target;

  /// وزن البند فى حساب النسبة (الصلاة أثقل من الباقى).
  final int weight;

  const ProgramTask({
    required this.id,
    required this.title,
    required this.emoji,
    required this.done,
    required this.target,
    this.weight = 1,
  });

  bool get complete => target <= 0 || done >= target;

  /// نسبة إنجاز البند ٠..١.
  double get ratio =>
      target <= 0 ? 1 : (done / target).clamp(0.0, 1.0).toDouble();
}

/// نتيجة اليوم: النسبة + المستوى + البنود الناقصة.
class ProgramDay {
  final List<ProgramTask> tasks;
  const ProgramDay(this.tasks);

  /// نسبة إنجاز اليوم ٠..١٠٠ (موزونة).
  int get percent {
    final totalW = tasks.fold<int>(0, (s, t) => s + t.weight);
    if (totalW == 0) return 0;
    final got = tasks.fold<double>(0, (s, t) => s + t.ratio * t.weight);
    return (got / totalW * 100).round().clamp(0, 100);
  }

  List<ProgramTask> get remaining => tasks.where((t) => !t.complete).toList();
  int get completedCount => tasks.where((t) => t.complete).length;

  /// أهم بند ناقص (الأعلى وزنًا) — «اللى المفروض تعمله دلوقتى».
  ProgramTask? get nextUp {
    final r = remaining;
    if (r.isEmpty) return null;
    r.sort((a, b) => b.weight.compareTo(a.weight));
    return r.first;
  }
}

/// مستوى الالتزام بحسب متوسط نسبة آخر فترة.
enum ProgramLevel { starting, regular, committed, excelling }

ProgramLevel levelFor(int avgPercent) {
  if (avgPercent >= 90) return ProgramLevel.excelling;
  if (avgPercent >= 70) return ProgramLevel.committed;
  if (avgPercent >= 40) return ProgramLevel.regular;
  return ProgramLevel.starting;
}

String levelLabelAr(ProgramLevel l) => switch (l) {
      ProgramLevel.excelling => 'مُتقِن',
      ProgramLevel.committed => 'مُلتزِم',
      ProgramLevel.regular => 'مُنتظِم',
      ProgramLevel.starting => 'فى البداية',
    };

String levelLabelEn(ProgramLevel l) => switch (l) {
      ProgramLevel.excelling => 'Excelling',
      ProgramLevel.committed => 'Committed',
      ProgramLevel.regular => 'Regular',
      ProgramLevel.starting => 'Starting',
    };

/// رسالة تشجيع بحسب نسبة اليوم.
String programMessageAr(int pct) {
  if (pct >= 100) return 'أتممت برنامج اليوم كاملًا — تقبّل الله 🤍';
  if (pct >= 75) return 'قربت تكمّل يومك — باقى القليل';
  if (pct >= 40) return 'ماشى كويس، كمّل اللى فاضل';
  if (pct > 0) return 'بدأت — وأحبّ العمل إلى الله أدومه وإن قلّ';
  return 'ابدأ بخطوة واحدة من برنامج اليوم';
}

String programMessageEn(int pct) {
  if (pct >= 100) return 'Today\'s program is complete — may Allah accept 🤍';
  if (pct >= 75) return 'Almost there — just a little left';
  if (pct >= 40) return 'Going well — finish what remains';
  if (pct > 0) return 'You started — small and steady wins';
  return 'Start with one step of today\'s program';
}
