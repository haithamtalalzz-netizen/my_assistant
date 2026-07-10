import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
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
      dev.log('فشل فتح الاتصال', error: e);
    }
  }

  Widget _row(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = _blood.isEmpty &&
        _allergies.isEmpty &&
        _conditions.isEmpty &&
        _contactPhone.isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('كارت الطوارئ', 'Emergency card')),
        backgroundColor: scheme.errorContainer,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : empty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr('كارت الطوارئ فاضي — املا بياناته من الإعدادات:\nفصيلة الدم، الحساسيات، الأمراض المزمنة، ورقم للطوارئ',
                          'Emergency card is empty — fill it in settings:\nblood type, allergies, chronic conditions, and an emergency number'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _row(context, tr('فصيلة الدم', 'Blood type'), _blood),
                    _row(context, tr('الحساسيات', 'Allergies'), _allergies),
                    _row(context, tr('أمراض مزمنة', 'Chronic conditions'),
                        _conditions),
                    _row(
                        context,
                        tr('شخص للطوارئ', 'Emergency contact'),
                        _contactName.isEmpty
                            ? _contactPhone
                            : '$_contactName — $_contactPhone'),
                    if (_contactPhone.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _call,
                        icon: const Icon(Icons.call),
                        label: Text(tr('اتصل بشخص الطوارئ', 'Call emergency contact'),
                            style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ],
                ),
    );
  }
}
