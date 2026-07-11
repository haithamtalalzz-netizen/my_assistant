import 'package:flutter/material.dart';

import '../core/geocoding.dart';
import '../core/l10n.dart';
import '../core/prayers.dart';
import '../data/settings_repo.dart';
import '../widgets/city_search_sheet.dart';

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
  String _governorate = kGovernorates.first.name;
  GeoPlace? _worldCity; // مدينة عالمية مختارة (بديلة للمحافظة)
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _saving = true);
    await _settings.set('user_name', _name.text.trim());
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

  Future<void> _pickWorldCity() async {
    final place = await pickCity(context);
    if (place != null && mounted) setState(() => _worldCity = place);
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
              if (_worldCity == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: _governorate,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: tr('محافظتك (لمواعيد الصلاة والطقس)',
                        'Your governorate (for prayer times & weather)'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final g in kGovernorates)
                      DropdownMenuItem(value: g.name, child: Text(g.name)),
                  ],
                  onChanged: (v) =>
                      setState(() => _governorate = v ?? _governorate),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _pickWorldCity,
                    icon: const Icon(Icons.public, size: 18),
                    label: Text(tr('مش في مصر؟ دوّر على أي مدينة في العالم',
                        'Not in Egypt? Search any city worldwide')),
                  ),
                ),
              ] else
                Card(
                  child: ListTile(
                    leading: Icon(Icons.public,
                        color: Theme.of(context).colorScheme.primary),
                    title: Text(_worldCity!.name),
                    subtitle: Text(_worldCity!.label),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: tr('رجوع للمحافظات', 'Back to governorates'),
                      onPressed: () => setState(() => _worldCity = null),
                    ),
                    onTap: _pickWorldCity,
                  ),
                ),
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
