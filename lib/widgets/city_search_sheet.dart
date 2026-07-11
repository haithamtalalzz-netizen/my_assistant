import 'dart:async';

import 'package:flutter/material.dart';

import '../core/countries.dart';
import '../core/geocoding.dart';
import '../core/l10n.dart';

/// شيت البحث عن مدينة — يرجّع [GeoPlace] المختار أو null.
/// لو اتحدد [countryCode] بيفلتر على الدولة دي بس.
Future<GeoPlace?> pickCity(BuildContext context,
    {String? countryCode, String? countryName}) {
  return showModalBottomSheet<GeoPlace>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _CitySearchSheet(countryCode: countryCode, countryName: countryName),
    ),
  );
}

/// شيت اختيار الدولة — قائمة كل دول العالم مع بحث. يرجّع [Country] أو null.
Future<Country?> pickCountry(BuildContext context) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _CountryPickerSheet(),
    ),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _q = '';

  List<Country> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return kCountries;
    return kCountries
        .where((c) =>
            c.ar.toLowerCase().contains(q) || c.en.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('اختر الدولة', 'Choose country'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('دوّر على الدولة', 'Search country'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(tr('مفيش نتائج', 'No results'),
                          style: TextStyle(color: scheme.outline)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final c = list[i];
                        return ListTile(
                          dense: true,
                          leading: Text(_flag(c.code),
                              style: const TextStyle(fontSize: 22)),
                          title: Text(c.name),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// علم الدولة كإيموجي من كود ISO (حرفين → Regional Indicator).
String _flag(String code) {
  if (code.length != 2) return '🏳️';
  const base = 0x1F1E6;
  final cc = code.toUpperCase();
  return String.fromCharCodes([
    base + (cc.codeUnitAt(0) - 65),
    base + (cc.codeUnitAt(1) - 65),
  ]);
}

class _CitySearchSheet extends StatefulWidget {
  final String? countryCode;
  final String? countryName;
  const _CitySearchSheet({this.countryCode, this.countryName});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<GeoPlace> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (q.trim().length < 2) {
        setState(() => _results = []);
        return;
      }
      setState(() => _loading = true);
      final r = await searchCities(q, countryCode: widget.countryCode);
      if (mounted) {
        setState(() {
          _results = r;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('دوّر على مدينتك', 'Find your city'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
                tr('أي مدينة في العالم — للمواعيد الصلاة والطقس',
                    'Any city worldwide — for prayer times & weather'),
                style: TextStyle(color: scheme.outline, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('اكتب اسم المدينة (مثلًا: دبي، لندن، جدة)',
                    'Type a city (e.g. Dubai, London)'),
                border: const OutlineInputBorder(),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                          _ctrl.text.trim().length < 2
                              ? tr('ابدأ الكتابة...', 'Start typing...')
                              : _loading
                                  ? ''
                                  : tr('مفيش نتائج', 'No results'),
                          style: TextStyle(color: scheme.outline)))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        return ListTile(
                          leading: Icon(Icons.location_on_outlined,
                              color: scheme.primary),
                          title: Text(p.name),
                          subtitle: Text([
                            if (p.admin1.isNotEmpty && p.admin1 != p.name)
                              p.admin1,
                            if (p.country.isNotEmpty) p.country,
                          ].join('، ')),
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
