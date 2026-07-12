import 'package:flutter/material.dart';

import '../core/countries.dart';
import '../core/geocoding.dart';
import '../core/l10n.dart';
import '../core/location_tracker.dart';
import 'city_search_sheet.dart';

/// بنود اختيار الموقع: الدولة ← المدينة (المدن حسب الدولة) + زر GPS تلقائي.
/// بيبعت [onPicked] بمكان فيه إحداثيات (lat/lng) + label للعرض والحفظ.
class LocationFields extends StatefulWidget {
  final String? initialCountryCode;
  final String? initialCityLabel;
  final void Function(GeoPlace place) onPicked;

  const LocationFields({
    super.key,
    this.initialCountryCode,
    this.initialCityLabel,
    required this.onPicked,
  });

  @override
  State<LocationFields> createState() => _LocationFieldsState();
}

class _LocationFieldsState extends State<LocationFields> {
  Country? _country;
  String? _cityLabel;
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    _country = countryByCode(widget.initialCountryCode);
    _cityLabel = widget.initialCityLabel;
  }

  Future<void> _pickCountry() async {
    final c = await pickCountry(context);
    if (c == null || !mounted) return;
    setState(() {
      _country = c;
      _cityLabel = null; // اتغيرت الدولة → امسح المدينة
    });
  }

  Future<void> _pickCity() async {
    final c = _country;
    if (c == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اختر الدولة الأول', 'Choose the country first'))));
      return;
    }
    final place = await pickCity(context,
        countryCode: c.code, countryName: c.name, countryEnglishName: c.en);
    if (place == null || !mounted) return;
    setState(() => _cityLabel = place.label);
    widget.onPicked(place);
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    final err = await WalkTracker.ensureReady(); // نفس فحص الإذن/الـGPS
    if (err != null) {
      if (mounted) {
        setState(() => _detecting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    final pos = await currentPosition();
    if (pos == null) {
      if (mounted) {
        setState(() => _detecting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('تعذّر تحديد الموقع — جرّب تاني',
                'Could not get location — try again'))));
      }
      return;
    }
    final place = await reverseGeocode(pos.latitude, pos.longitude) ??
        GeoPlace(
          name: tr('موقعي الحالي', 'My location'),
          country: '',
          admin1: '',
          lat: pos.latitude,
          lng: pos.longitude,
        );
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _country = countryByCode(place.countryCode) ?? _country;
      _cityLabel = place.label;
    });
    widget.onPicked(place);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر تحديد تلقائي بالـGPS.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _detecting ? null : _detect,
            icon: _detecting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: Text(_detecting
                ? tr('بيحدد موقعك...', 'Locating...')
                : tr('حدد موقعي تلقائيًا (GPS)', 'Detect my location (GPS)')),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Divider(color: scheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(tr('أو اختر يدويًا', 'or choose manually'),
                style: TextStyle(fontSize: 12, color: scheme.outline)),
          ),
          Expanded(child: Divider(color: scheme.outlineVariant)),
        ]),
        const SizedBox(height: 12),
        // بند الدولة.
        _fieldTile(
          icon: Icons.flag_outlined,
          label: tr('الدولة', 'Country'),
          value: _country?.name,
          hint: tr('اختر الدولة', 'Choose country'),
          onTap: _pickCountry,
        ),
        const SizedBox(height: 10),
        // بند المدينة (متاح بعد اختيار الدولة).
        _fieldTile(
          icon: Icons.location_city_outlined,
          label: tr('المدينة', 'City'),
          value: _cityLabel,
          hint: _country == null
              ? tr('اختر الدولة الأول', 'Choose country first')
              : tr('اختر المدينة', 'Choose city'),
          enabled: _country != null,
          onTap: _pickCity,
        ),
      ],
    );
  }

  Widget _fieldTile({
    required IconData icon,
    required String label,
    required String? value,
    required String hint,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          enabled: enabled,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value == null
                      ? scheme.outline
                      : scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
