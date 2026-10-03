import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/privacy.dart';
import '../../data/meds_repo.dart';
import '../home/pharmacy_screen.dart';
import '../schedule/schedule_screen.dart';

/// **أدويتى** — «الأدوية» و«صيدلية البيت» فى شاشة واحدة بتبويبين.
///
/// ليه الدمج: الاتنين عن الدوا، والاسمين ماكانوش بيقولوا الفرق — واحد
/// للجرعات وواحد للمخزون والصلاحية. فالناس كانت بتفتح الاتنين وتلاقيهم
/// شبه بعض.
///
/// والفايدة الحقيقية مش الدمج نفسه: إنك **تشوف إن الدوا هيخلص قبل ما
/// يخلص**. المعلومة دى كانت فى شاشة تانية ومحدش بيفتحها.
///
/// الشاشتين الأصليتين فضلوا موجودين — «الأدوية» بتتفتح لوحدها من خط
/// اليوم لمّا تدوس على جرعة.
class MedsHubScreen extends StatefulWidget {
  const MedsHubScreen({super.key});

  @override
  State<MedsHubScreen> createState() => _MedsHubScreenState();
}

class _MedsHubScreenState extends State<MedsHubScreen> {
  int? _adherence;

  @override
  void initState() {
    super.initState();
    _loadAdherence();
  }

  /// نسبة الالتزام آخر أسبوع — كانت كارت مدفون فى «لوحة الصحة»،
  /// ومكانها الطبيعى هنا جنب الجرعات.
  Future<void> _loadAdherence() async {
    final v = await MedsRepo().adherencePercent();
    if (mounted) setState(() => _adherence = v);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('أدويتى', 'My medicines')),
          actions: const [PrivacyAction()],
          bottom: TabBar(tabs: [
            Tab(text: tr('جرعاتك', 'Doses')),
            Tab(text: tr('مخزونك', 'Stock')),
          ]),
        ),
        body: Column(children: [
          if (_adherence != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13,
                    vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.22)),
                ),
                child: Row(children: [
                  Icon(Icons.verified_outlined,
                      size: 17, color: scheme.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                        tr('التزامك آخر أسبوع', "This week's adherence"),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  Text('$_adherence٪',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: scheme.primary)),
                ]),
              ),
            ),
          const Expanded(
            child: TabBarView(children: [
              MedsTab(),
              PharmacyScreen(embedded: true),
            ]),
          ),
        ]),
      ),
    );
  }
}
