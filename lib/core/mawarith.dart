/// حاسبة مواريث مبسّطة للحالات الشائعة (زوج/زوجة + أبناء + بنات + أب + أم +
/// إخوة أشقّاء). بتغطّي الفروض + التعصيب (٢:١) + العَوْل + الردّ + المسألتين
/// العُمريّتين. **للمسائل المركّبة (الجدّ/الجدّة/الحجب المتداخل) راجِع مختصًّا.**
class MawarithInput {
  final double estate;
  final String spouse; // 'husband' / 'wife' / 'none'
  final int wives; // عدد الزوجات لو spouse='wife'
  final int sons;
  final int daughters;
  final bool father;
  final bool mother;
  final int fullBrothers;
  final int fullSisters;

  const MawarithInput({
    required this.estate,
    this.spouse = 'none',
    this.wives = 1,
    this.sons = 0,
    this.daughters = 0,
    this.father = false,
    this.mother = false,
    this.fullBrothers = 0,
    this.fullSisters = 0,
  });
}

class HeirShare {
  final String name;
  final double fraction; // نصيب من الكل (0..1)
  final double amount;
  const HeirShare(this.name, this.fraction, this.amount);
}

class MawarithResult {
  final List<HeirShare> shares;
  final List<String> notes;
  const MawarithResult(this.shares, this.notes);
}

MawarithResult computeMawarith(MawarithInput inp) {
  final notes = <String>[];
  final fards = <String, double>{}; // أصحاب الفروض
  final hasDesc = inp.sons > 0 || inp.daughters > 0;
  final hasSon = inp.sons > 0;
  final siblings = inp.fullBrothers + inp.fullSisters;

  // الزوجية
  double spouseShare = 0;
  if (inp.spouse == 'husband') {
    spouseShare = hasDesc ? 1 / 4 : 1 / 2;
    fards['الزوج'] = spouseShare;
  } else if (inp.spouse == 'wife') {
    spouseShare = hasDesc ? 1 / 8 : 1 / 4;
    fards[inp.wives > 1 ? 'الزوجات' : 'الزوجة'] = spouseShare;
  }

  // المسألتان العُمريّتان: زوج/زوجة + أب + أم فقط (لا فرع ولا إخوة).
  final umariyya = inp.spouse != 'none' &&
      inp.father &&
      inp.mother &&
      !hasDesc &&
      siblings == 0;

  if (umariyya) {
    final motherShare = (1 - spouseShare) / 3;
    fards['الأم'] = motherShare;
    fards['الأب'] = 1 - spouseShare - motherShare;
    notes.add('مسألة عُمريّة: الأم تأخذ ثلث الباقى بعد الزوجية.');
  } else {
    // الأم
    if (inp.mother) {
      fards['الأم'] = (hasDesc || siblings >= 2) ? 1 / 6 : 1 / 3;
    }
  }

  // البنات (عند عدم وجود ابن يعصّبهنّ)
  if (!hasSon && inp.daughters > 0) {
    fards['البنات'] = inp.daughters == 1 ? 1 / 2 : 2 / 3;
  }

  // الأب
  if (!umariyya && inp.father) {
    if (hasSon) {
      fards['الأب'] = 1 / 6; // فرض فقط (الابن يأخذ الباقى)
    } else if (hasDesc) {
      fards['الأب'] = 1 / 6; // + باقى تعصيبًا (يُضاف تحت)
    }
    // لو لا فرع: الأب عاصب (يأخذ الباقى) — يُحسب تحت.
  }

  // مجموع الفروض
  var sumFards = fards.values.fold<double>(0, (a, b) => a + b);

  // العاصب: الابن/البنت (٢:١)، وإلا الأب، وإلا الإخوة.
  final residue = 1 - sumFards;
  final result = <String, double>{}..addAll(fards);

  if (hasSon) {
    // الأبناء والبنات يقتسمون الباقى ٢:١
    final units = inp.sons * 2 + inp.daughters;
    if (units > 0 && residue > 0) {
      if (inp.sons > 0) result['الأبناء'] = residue * (inp.sons * 2) / units;
      if (inp.daughters > 0) {
        result['البنات'] = (result['البنات'] ?? 0) + residue * inp.daughters / units;
      }
    }
  } else if (inp.father && (residue > 1e-9)) {
    // الأب يأخذ الباقى تعصيبًا (مع فرضه لو موجود)
    result['الأب'] = (result['الأب'] ?? 0) + residue;
  } else if (!hasDesc && !inp.father && siblings > 0 && residue > 1e-9) {
    final units = inp.fullBrothers * 2 + inp.fullSisters;
    if (units > 0) {
      if (inp.fullBrothers > 0) {
        result['الإخوة'] = residue * (inp.fullBrothers * 2) / units;
      }
      if (inp.fullSisters > 0) {
        result['الأخوات'] = residue * inp.fullSisters / units;
      }
    }
  } else if (residue > 1e-9) {
    // لا عاصب: ردّ الباقى على أصحاب الفروض (ما عدا الزوجية).
    final reddPool = fards.keys
        .where((k) => k != 'الزوج' && k != 'الزوجة' && k != 'الزوجات')
        .toList();
    final base =
        reddPool.fold<double>(0, (a, k) => a + (fards[k] ?? 0));
    if (base > 0) {
      for (final k in reddPool) {
        result[k] = (result[k] ?? 0) + residue * (fards[k]! / base);
      }
      notes.add('تمّ ردّ الباقى على أصحاب الفروض (عدا الزوجية).');
    }
  }

  // العَوْل: لو مجموع الفروض تجاوز 1 (ولا عاصب) نُنقص الكل بالتناسب.
  sumFards = result.values.fold<double>(0, (a, b) => a + b);
  if (sumFards > 1 + 1e-9) {
    for (final k in result.keys) {
      result[k] = result[k]! / sumFards;
    }
    notes.add('مسألة عائلة: تمّ تخفيض الأنصبة بالتناسب (العَوْل).');
  }

  final shares = result.entries
      .where((e) => e.value > 1e-6)
      .map((e) => HeirShare(e.key, e.value, e.value * inp.estate))
      .toList()
    ..sort((a, b) => b.fraction.compareTo(a.fraction));
  return MawarithResult(shares, notes);
}
