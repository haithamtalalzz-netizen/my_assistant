import '../core/log.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/ar.dart';
import '../core/l10n.dart';
import '../widgets/a_kit.dart';
import 'settings_screen.dart';
import '../data/settings_repo.dart';

/// كارت الطوارئ — متاح من شاشة القفل من غير بصمة عمدًا:
/// وقت الطوارئ أي حد ماسك الموبايل لازم يوصل للمعلومات دي.
class EmergencyView extends StatefulWidget {
  const EmergencyView({super.key});

  @override
  State<EmergencyView> createState() => _EmergencyViewState();
}

class _EmergencyViewState extends State<EmergencyView> {
  bool _loading = true;
  String _blood = '';
  String _allergies = '';
  String _conditions = '';
  String _contactName = '';
  String _contactPhone = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = SettingsRepo();
    final blood = await settings.get('emergency_blood') ?? '';
    final allergies = await settings.get('emergency_allergies') ?? '';
    final conditions = await settings.get('emergency_conditions') ?? '';
    final contactName = await settings.get('emergency_contact_name') ?? '';
    final contactPhone = await settings.get('emergency_contact_phone') ?? '';
    if (!mounted) return;
    setState(() {
      _blood = blood;
      _allergies = allergies;
      _conditions = conditions;
      _contactName = contactName;
      _contactPhone = contactPhone;
      _loading = false;
    });
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _contactPhone);
    try {
      await launchUrl(uri);
    } on Exception catch (e) {
      logError('فشل فتح الاتصال', e);
    }
  }

  /// سطر بيانات — بيختفى لو فاضى (كارت الطوارئ مايعرضش خانات فاضية).
  Widget _row(BuildContext context, IconData icon, String label, String value,
      {bool last = false, VoidCallback? onTap}) {
    if (value.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.7)))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 19, color: scheme.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 11.5)),
            const SizedBox(height: 2),
            // كبير عن قصد: حد تانى بيقراه من على بُعد فى لحظة ضغط.
            Text(value,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700)),
          ]),
        ),
        if (onTap != null)
          Icon(Icons.call, size: 20, color: scheme.error),
      ]),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = _blood.isEmpty &&
        _allergies.isEmpty &&
        _conditions.isEmpty &&
        _contactPhone.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(tr('كارت الطوارئ', 'Emergency card'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                AppPad(
                  AppHero(
                    icon: Icons.medical_services_outlined,
                    kicker: tr('فى حالة الطوارئ', 'In an emergency'),
                    title: empty
                        ? tr('الكارت فاضى', 'Card is empty')
                        : (_blood.isEmpty
                            ? tr('بياناتك الطبية', 'Your medical info')
                            : tr('فصيلة دمك ${ltr(_blood)}', 'Blood type ${ltr(_blood)}')),
                    primaryLabel: _contactPhone.isEmpty
                        ? tr('املا البيانات', 'Fill it in')
                        : tr('اتصل بشخص الطوارئ', 'Call emergency contact'),
                    primaryIcon:
                        _contactPhone.isEmpty ? Icons.edit : Icons.call,
                    onPrimary: _contactPhone.isEmpty
                        // زرار بيقول «املا البيانات» ومايعملش حاجة = وعد
                        // كاذب؛ بيفتح قسم الطوارئ فى الإعدادات على طول.
                        ? () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(
                                        initialCategory: 'emergency')));
                            if (mounted) await _load();
                          }
                        : _call,
                    colors: [
                      scheme.error,
                      Color.lerp(scheme.error, Colors.black, 0.3)!
                    ],
                    extra: empty
                        ? null
                        : Text(
                            _contactName.isEmpty
                                ? _contactPhone
                                : '$_contactName — $_contactPhone',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.white.withValues(alpha: 0.9))),
                  ),
                  top: 12,
                  bottom: 20,
                ),
                if (empty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr('كارت الطوارئ فاضي — املا بياناته من الإعدادات:\nفصيلة الدم، الحساسيات، الأمراض المزمنة، ورقم للطوارئ',
                          'Emergency card is empty — fill it in settings:\nblood type, allergies, chronic conditions, and an emergency number'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  )
                else ...[
                  // قايمة واحدة بعناوين: «بياناتك» اللى المسعف بيسأل
                  // عليها الأول، بعدها «لازم يعرفوا»، بعدها الأرقام.
                  if (_blood.isNotEmpty)
                    AppPad(AppGroupHead(tr('بياناتك', 'About you'))),
                  if (_blood.isNotEmpty)
                    AppPad(_row(context, Icons.bloodtype,
                        tr('فصيلة الدم', 'Blood type'), ltr(_blood),
                        last: true)),
                  if (_allergies.isNotEmpty || _conditions.isNotEmpty) ...[
                    AppPad(AppGroupHead(tr('لازم يعرفوا', 'They must know'),
                        trail: arNum([_allergies, _conditions]
                            .where((e) => e.isNotEmpty)
                            .length))),
                    AppPad(_row(context, Icons.warning_amber_rounded,
                        tr('الحساسيات', 'Allergies'), _allergies,
                        last: _conditions.isEmpty)),
                    AppPad(_row(context, Icons.monitor_heart_outlined,
                        tr('أمراض مزمنة', 'Chronic conditions'), _conditions,
                        last: true)),
                  ],
                  if (_contactPhone.isNotEmpty) ...[
                    AppPad(AppGroupHead(
                        tr('أرقام الطوارئ', 'Emergency numbers'))),
                    AppPad(_row(
                        context,
                        Icons.contact_phone_outlined,
                        _contactName.isEmpty
                            ? tr('شخص للطوارئ', 'Emergency contact')
                            : _contactName,
                        ltr(_contactPhone),
                        last: true,
                        onTap: _call)),
                  ],
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}
