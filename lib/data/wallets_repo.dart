import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';
import 'settings_repo.dart';

const List<String> kWalletTypes = [
  'cash',
  'bank',
  'card',
  'mobile',
  'gold',
  'silver',
  'asset',
  'livestock',
  'other',
];

String walletTypeLabel(String t) => switch (t) {
      'cash' => tr('كاش', 'Cash'),
      'bank' => tr('بنك', 'Bank'),
      'card' => tr('فيزا / كارت ائتمان', 'Credit card'),
      'mobile' => tr('محفظة موبايل', 'Mobile wallet'),
      'gold' => tr('ذهب', 'Gold'),
      'silver' => tr('فضة', 'Silver'),
      'asset' => tr('أصل (بيت · عربية · أرض)', 'Asset'),
      'livestock' => tr('مواشى', 'Livestock'),
      'other' => tr('أخرى', 'Other'),
      _ => t,
    };

/// الأنواع اللى قيمتها **رقم بتكتبه** مش محصّلة حركات.
///
/// الذهب والأصول والمواشى مالهاش «دخل ومصروف» — قيمتها بتتحدّث لما
/// تقدّرها من جديد، فبتتكتب فى الرصيد الافتتاحى وخلاص.
const Set<String> kValueOnlyWalletTypes = {
  'gold',
  'silver',
  'asset',
  'livestock'
};

/// المعادن: قيمتها **بتتحسب** من الوزن والعيار وسعر الجرام.
const Set<String> kMetalWalletTypes = {'gold', 'silver'};

bool isMetalWallet(String type) => kMetalWalletTypes.contains(type);

/// العيارات المتاحة لكل معدن، والرقم الأصلى اللى النقاوة بتتقاس عليه.
///
/// الذهب: عيار ٢٤ = ذهب صافى، فعيار ٢١ نقاوته ٢١÷٢٤.
/// الفضة: ٩٩٩ = فضة صافية، فـ٩٢٥ نقاوتها ٩٢٥÷٩٩٩.
List<double> metalKarats(String type) =>
    type == 'silver' ? const [999, 925, 800] : const [24, 22, 21, 18, 14];

double metalBaseKarat(String type) => type == 'silver' ? 999 : 24;

String metalKaratLabel(String type, double k) => type == 'silver'
    ? tr('فضة ${arNum(k.round())}', '${arNum(k.round())} silver')
    : tr('عيار ${arNum(k.round())}', '${arNum(k.round())}K');

/// قيمة المعدن = الوزن × سعر جرام العيار الأصلى × نقاوة العيار.
///
/// يعنى ٥٠ جرام عيار ٢١ وسعر جرام الـ٢٤ = ٥٬٠٠٠ →
/// 50 × 5000 × (21÷24) = 218,750.
double metalValue({
  required String type,
  required double grams,
  required double karat,
  required double gramPrice,
}) {
  if (grams <= 0 || gramPrice <= 0) return 0;
  final base = metalBaseKarat(type);
  final purity = karat <= 0 ? 1.0 : (karat / base);
  return grams * gramPrice * purity;
}

bool isValueOnlyWallet(String type) => kValueOnlyWalletTypes.contains(type);

IconData walletTypeIcon(String t) => switch (t) {
      'cash' => Icons.payments,
      'bank' => Icons.account_balance,
      'card' => Icons.credit_card,
      'mobile' => Icons.phone_android,
      'gold' => Icons.diamond,
      'silver' => Icons.circle,
      'asset' => Icons.home_work,
      'livestock' => Icons.pets,
      _ => Icons.account_balance_wallet,
    };

/// لون ثابت لكل نوع — عشان تعرف المحفظة من لونها قبل ما تقرا.
Color walletTypeColor(String t) => switch (t) {
      'cash' => const Color(0xFF10B981),
      'bank' => const Color(0xFF14B8A6),
      'card' => const Color(0xFF3B82F6),
      'mobile' => const Color(0xFF06B6D4),
      'gold' => const Color(0xFFD9A441),
      'silver' => const Color(0xFF94A3B8),
      'asset' => const Color(0xFF8B5CF6),
      'livestock' => const Color(0xFF9A6B4F),
      _ => const Color(0xFF64748B),
    };

/// **سعر جرام المعدن — واحد لكل معدن، مش لكل قطعة.**
///
/// قبل كده كان كل محفظة ذهب ليها سعرها، فلو عندك ٣ قطع كنت بتعدّل
/// السعر ٣ مرات. دلوقتى السعر واحد: تحدّثه مرة وكل قطع الذهب تتحسب
/// من جديد.
///
/// السعر القديم اللى فى المحفظة نفسها بيفضل موجود ويُستعمل لو السعر
/// المشترك لسه مااتحطّش — فمحدش بيخسر رقم كان كاتبه.
class MetalPrices {
  static const _kGold = 'gold_gram_price';
  static const _kSilver = 'silver_gram_price';

  static double _gold = 0;
  static double _silver = 0;
  static bool _loaded = false;

  static double of(String type) => type == 'silver' ? _silver : _gold;

  static Future<void> load({bool force = false}) async {
    if (_loaded && !force) return;
    final st = SettingsRepo();
    _gold = double.tryParse(await st.get(_kGold) ?? '') ?? 0;
    _silver = double.tryParse(await st.get(_kSilver) ?? '') ?? 0;
    _loaded = true;
  }

  static Future<void> set(String type, double price) async {
    if (type == 'silver') {
      _silver = price;
      await SettingsRepo().set(_kSilver, price.toString());
    } else {
      _gold = price;
      await SettingsRepo().set(_kGold, price.toString());
    }
  }

  static void resetForTests() {
    _gold = 0;
    _silver = 0;
    _loaded = false;
  }
}

/// نوع الحساب البنكى: متاح تسحب منه، ولا شهادة بعائد وتاريخ انتهاء.
const List<String> kBankKinds = ['available', 'certificate'];

String bankKindLabel(String k) => switch (k) {
      'certificate' => tr('شهادة', 'Certificate'),
      _ => tr('متاح', 'Available'),
    };

class WalletsRepo {
  Future<int> save(Wallet w) async {
    final db = await AppDb.instance;
    if (w.id == null) return db.insert('wallets', w.toMap());
    await db.update('wallets', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
    return w.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    // نفكّ ربط الحركات بالمحفظة المحذوفة بدل ما نمسحها.
    await db.update('expenses', {'wallet_id': null},
        where: 'wallet_id = ?', whereArgs: [id]);
    await db.update('income', {'wallet_id': null},
        where: 'wallet_id = ?', whereArgs: [id]);
    await db.delete('wallet_transfers',
        where: 'from_wallet = ? OR to_wallet = ?', whereArgs: [id, id]);
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Wallet>> all() async {
    final db = await AppDb.instance;
    // الترتيب اللى اختاره الأول، وبعدين الـid — فالمحافظ اللى لسه
    // ماترتّبتش (sort_order = 0) بتفضل بترتيب إضافتها زى الأول.
    final rows = await db.query('wallets', orderBy: 'sort_order, id');
    return rows.map(Wallet.fromMap).toList();
  }

  /// بيحفظ ترتيب الظهور الجديد — الأول فى القايمة ياخد ١.
  ///
  /// بنبدأ من ١ مش صفر عشان المحفظة اللى تتضاف بعدين (افتراضيها صفر)
  /// تظهر **فوق**، مش تحت وسط اللى اترتّبوا.
  Future<void> saveOrder(List<int> idsInOrder) async {
    final db = await AppDb.instance;
    final batch = db.batch();
    for (var i = 0; i < idsInOrder.length; i++) {
      batch.update('wallets', {'sort_order': i + 1},
          where: 'id = ?', whereArgs: [idsInOrder[i]]);
    }
    await batch.commit(noResult: true);
  }

  Future<int> count() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM wallets');
    return (r.first['c'] as num).toInt();
  }

  /// رصيد محفظة = الرصيد الافتتاحي + الدخل − المصروف + التحويلات الداخلة − الخارجة.
  ///
  /// إلا الذهب والفضة: قيمتهم **بتتحسب** من الوزن والعيار وسعر الجرام،
  /// فمالهمش دخل ومصروف أصلاً.
  Future<double> balanceOf(Wallet w) async {
    if (isMetalWallet(w.type)) {
      // السعر المشترك هو المرجع؛ واللى فى المحفظة احتياطى للقديم.
      final price =
          MetalPrices.of(w.type) > 0 ? MetalPrices.of(w.type) : w.gramPrice;
      final v = metalValue(
          type: w.type, grams: w.grams, karat: w.karat, gramPrice: price);
      // لو لسه مادخّلش وزن وسعر، بنرجع اللى كتبه بإيده (لو كان كاتب).
      return v > 0 ? v : w.openingBalance;
    }
    final db = await AppDb.instance;
    Future<double> sum(String sql, List<Object?> args) async {
      final r = await db.rawQuery(sql, args);
      return (r.first['s'] as num?)?.toDouble() ?? 0;
    }

    final income = await sum(
        'SELECT SUM(amount) AS s FROM income WHERE wallet_id = ?', [w.id]);
    final expense = await sum(
        'SELECT SUM(amount) AS s FROM expenses WHERE wallet_id = ?', [w.id]);
    final tIn = await sum(
        'SELECT SUM(amount) AS s FROM wallet_transfers WHERE to_wallet = ?',
        [w.id]);
    final tOut = await sum(
        'SELECT SUM(amount) AS s FROM wallet_transfers WHERE from_wallet = ?',
        [w.id]);
    return w.openingBalance + income - expense + tIn - tOut;
  }

  Future<List<({Wallet wallet, double balance})>> allWithBalances() async {
    final wallets = await all();
    return [
      for (final w in wallets) (wallet: w, balance: await balanceOf(w))
    ];
  }

  /// بياخد السعر القديم اللى كان متكتوب فى المحفظة نفسها ويخلّيه هو
  /// السعر المشترك — مرة واحدة.
  ///
  /// من غير كده أول ما السعر المشترك يشتغل، الرقم اللى كان كاتبه
  /// **يتجاهل** وقيمة الذهب تقع لصفر. ده أهم من إنه يبقى «نضيف».
  Future<void> adoptLegacyMetalPrices() async {
    await MetalPrices.load();
    for (final type in kMetalWalletTypes) {
      if (MetalPrices.of(type) > 0) continue;
      final withPrice = (await all())
          .where((w) => w.type == type && w.gramPrice > 0)
          .toList();
      if (withPrice.isEmpty) continue;
      await MetalPrices.set(type, withPrice.first.gramPrice);
    }
  }

  /// **فلوسك السايلة** = اللى تقدر تلمسه النهاردة (كاش · بنك متاح ·
  /// كارت · محفظة موبايل).
  ///
  /// الذهب والأصول والمواشى والشهادة مربوطين: عندهم قيمة، بس مش فلوس
  /// فى إيدك. الفرق ده هو اللى بيخلّى واحد «معاه مليون» ومش لاقى إيجار.
  static bool isLiquid(Wallet w) =>
      !isValueOnlyWallet(w.type) &&
      !(w.type == 'bank' && w.bankKind == 'certificate');

  Future<({double liquid, double locked})> liquidSplit() async {
    final list = await allWithBalances();
    var liquid = 0.0;
    var locked = 0.0;
    for (final e in list) {
      if (isLiquid(e.wallet)) {
        liquid += e.balance;
      } else {
        locked += e.balance;
      }
    }
    return (liquid: liquid, locked: locked);
  }

  /// مجموع عائد الشهادات الشهرى — دخل ثابت زى المرتب بالظبط.
  Future<double> monthlyCertificateInterest() async {
    final list = await all();
    return list
        .where((w) => w.type == 'bank' && w.bankKind == 'certificate')
        .fold<double>(0, (t, w) => t + w.monthlyInterest);
  }

  /// الشهادات اللى بتنتهى خلال [days] يوم.
  Future<List<Wallet>> certificatesMaturingSoon({int days = 30}) async {
    final today = dateOnly(DateTime.now());
    final out = <Wallet>[];
    for (final w in await all()) {
      if (w.type != 'bank' || w.bankKind != 'certificate') continue;
      final end = DateTime.tryParse(w.maturity);
      if (end == null) continue;
      final left = dateOnly(end).difference(today).inDays;
      if (left >= 0 && left <= days) out.add(w);
    }
    return out;
  }

  Future<double> totalBalance() async {
    final list = await allWithBalances();
    return list.fold<double>(0, (s, e) => s + e.balance);
  }

  Future<void> transfer(int from, int to, double amount, {DateTime? now}) async {
    final db = await AppDb.instance;
    await db.insert('wallet_transfers', WalletTransfer(
      fromWallet: from,
      toWallet: to,
      amount: amount,
      day: dayKey(now ?? DateTime.now()),
    ).toMap());
  }
}
