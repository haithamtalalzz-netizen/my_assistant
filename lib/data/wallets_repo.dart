import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../models/models.dart';

const List<String> kWalletTypes = [
  'cash',
  'bank',
  'card',
  'mobile',
  'gold',
  'asset',
  'livestock',
  'other',
];

String walletTypeLabel(String t) => switch (t) {
      'cash' => tr('كاش', 'Cash'),
      'bank' => tr('بنك', 'Bank'),
      'card' => tr('فيزا / كارت ائتمان', 'Credit card'),
      'mobile' => tr('محفظة موبايل', 'Mobile wallet'),
      'gold' => tr('ذهب وفضة', 'Gold & silver'),
      'asset' => tr('أصل (بيت · عربية · أرض)', 'Asset'),
      'livestock' => tr('مواشى', 'Livestock'),
      'other' => tr('أخرى', 'Other'),
      _ => t,
    };

/// الأنواع اللى قيمتها **رقم بتكتبه** مش محصّلة حركات.
///
/// الذهب والأصول والمواشى مالهاش «دخل ومصروف» — قيمتها بتتحدّث لما
/// تقدّرها من جديد، فبتتكتب فى الرصيد الافتتاحى وخلاص.
const Set<String> kValueOnlyWalletTypes = {'gold', 'asset', 'livestock'};

bool isValueOnlyWallet(String type) => kValueOnlyWalletTypes.contains(type);

IconData walletTypeIcon(String t) => switch (t) {
      'cash' => Icons.payments,
      'bank' => Icons.account_balance,
      'card' => Icons.credit_card,
      'mobile' => Icons.phone_android,
      'gold' => Icons.diamond,
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
      'asset' => const Color(0xFF8B5CF6),
      'livestock' => const Color(0xFF9A6B4F),
      _ => const Color(0xFF64748B),
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
    final rows = await db.query('wallets', orderBy: 'id');
    return rows.map(Wallet.fromMap).toList();
  }

  Future<int> count() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM wallets');
    return (r.first['c'] as num).toInt();
  }

  /// رصيد محفظة = الرصيد الافتتاحي + الدخل − المصروف + التحويلات الداخلة − الخارجة.
  Future<double> balanceOf(Wallet w) async {
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
