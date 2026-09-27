// تحقّق من الهارنس نفسه قبل ما نبنى عليه: عربى + أيقونات + ألوان.
// `flutter test tool/smoke_shot_test.dart`
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shot_harness.dart';

void main() {
  testWidgets('الهارنس بيرسم عربى وأيقونات فعلاً', (tester) async {
    await loadShotFonts();
    final f = await shot(
      tester,
      '_smoke',
      shotApp(
        ThemeData(
          useMaterial3: true,
          fontFamily: 'Cairo',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2FDE9B)),
        ),
        Scaffold(
          appBar: AppBar(title: const Text('اختبار الخط والأيقونات')),
          body: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مساء الخير — الأحد ٢٧ سبتمبر',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.favorite, size: 32, color: Colors.pink),
                  SizedBox(width: 12),
                  Icon(Icons.mosque, size: 32, color: Colors.teal),
                  SizedBox(width: 12),
                  Icon(Icons.account_balance_wallet, size: 32),
                  SizedBox(width: 12),
                  Icon(Icons.checkroom, size: 32),
                ]),
                SizedBox(height: 16),
                Text('الأرقام: 1234 · ٥٦٧٨', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
      size: const Size(390, 420),
      pixelRatio: 2,
    );
    expect(f.lengthSync(), greaterThan(5000));
  });
}
