import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/geocoding.dart';
import '../core/l10n.dart';
import '../core/prayers.dart';
import '../data/settings_repo.dart';
import '../widgets/location_fields.dart';

/// تهيئة أول مرة — بتجمع الاسم والمحافظة (للصلاة والطقس) في خطوة واحدة بسيطة.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settings = SettingsRepo();
  final _name = TextEditingController();
  final String _governorate = kGovernorates.first.name; // احتياطي لو مااختارش
  GeoPlace? _worldCity; // مكان مختار (دولة+مدينة أو GPS)
  String _gender = ''; // 'male' / 'female'
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _saving = true);
    await _settings.set('user_name', _name.text.trim());
    if (_gender.isNotEmpty) await AppState.setGender(_gender);
    if (_worldCity != null) {
      // مدينة عالمية مختارة → إحداثيات مخصّصة.
      await _settings.setCustomLocation(
          _worldCity!.lat, _worldCity!.lng, _worldCity!.label);
    } else {
      await _settings.clearCustomLocation();
      await _settings.set('governorate', _governorate);
    }
    await _settings.set('onboarded', '1');
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.auto_awesome, size: 64, color: scheme.primary),
              const SizedBox(height: 16),
              Text(tr('أهلًا بيك في مساعدي', 'Welcome to My Assistant'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  tr('مديرك الشخصي لكل حاجة في يومك — صحة، فلوس، مواعيد وأكتر.',
                      'Your personal manager for everything — health, money, schedule & more.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline)),
              const SizedBox(height: 32),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: tr('اسمك', 'Your name'),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // النوع (ذكر / أنثى) — بيفعّل بند الدورة الشهرية للإناث.
              SegmentedButton<String>(
                // من غير إيموجى: الإيموجى كان بيتحط جنب «ذكر» فتبان الكلمة
                // متقطّعة (ذ مايتوصلش بالحرف اللى بعده أصلاً فى العربى).
                segments: [
                  ButtonSegment(
                      value: 'male', label: Text(tr('ذكر', 'Male'))),
                  ButtonSegment(
                      value: 'female', label: Text(tr('أنثى', 'Female'))),
                ],
                selected: _gender.isEmpty ? {} : {_gender},
                emptySelectionAllowed: true,
                onSelectionChanged: (s) =>
                    setState(() => _gender = s.isEmpty ? '' : s.first),
              ),
              const SizedBox(height: 16),
              // اختيار الموقع (لمواعيد الصلاة والطقس): الدولة ← المدينة أو GPS.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(tr('موقعك (لمواعيد الصلاة والطقس)',
                    'Your location (for prayer times & weather)'),
                    style: TextStyle(fontSize: 13, color: scheme.outline)),
              ),
              const SizedBox(height: 8),
              LocationFields(
                initialCityLabel: _worldCity?.label,
                onPicked: (place) => setState(() => _worldCity = place),
              ),
              if (_worldCity != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_worldCity!.label,
                        style: TextStyle(fontSize: 12, color: scheme.primary))),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                  tr('تقدر تفعّل قفل البصمة ومزامنة الساعة لاحقًا من الإعدادات.',
                      'You can enable fingerprint lock & watch sync later in settings.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _start,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(tr('يلا نبدأ', "Let's start")),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
