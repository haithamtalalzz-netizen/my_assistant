import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/city_data.dart';
import '../core/countries.dart';
import '../core/geocoding.dart';
import '../core/l10n.dart';

/// شيت البحث عن مدينة — يرجّع [GeoPlace] المختار أو null.
/// لو اتحدد [countryCode] بيفلتر على الدولة دي، و[countryEnglishName] بيجيب كل مدنها.
Future<GeoPlace?> pickCity(BuildContext context,
    {String? countryCode, String? countryName, String? countryEnglishName}) {
  return showModalBottomSheet<GeoPlace>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _CitySearchSheet(
        countryCode: countryCode,
        countryName: countryName,
        countryEnglishName: countryEnglishName,
      ),
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
  final String? countryEnglishName;
  const _CitySearchSheet(
      {this.countryCode, this.countryName, this.countryEnglishName});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

/// صف مدينة: اسم + إحداثيات جاهزة (لو موجودة) — وإلا بتتجاب عند الاختيار.
class _CityRow {
  final String name;
  final GeoPlace? place;
  const _CityRow(this.name, this.place);
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<_CityRow> _all = []; // كل مدن الدولة (مدمجة + من الإنترنت)
  List<_CityRow> _shown = [];
  bool _loadingCities = false; // بيجيب قائمة المدن الكاملة
  bool _resolving = false; // بيجيب إحداثيات مدينة مختارة
  bool _searchingOnline = false; // بحث Open-Meteo لمدينة مش في القائمة

  @override
  void initState() {
    super.initState();
    _initCities();
  }

  Future<void> _initCities() async {
    // 1) المدن المدمجة (بإحداثيات) تظهر فورًا.
    final bundled = <_CityRow>[
      for (final c in citiesForCountry(widget.countryCode))
        _CityRow(
          AppState.isEnglish ? c.en : c.ar,
          GeoPlace(
            name: AppState.isEnglish ? c.en : c.ar,
            country: widget.countryName ?? '',
            admin1: '',
            countryCode: widget.countryCode ?? '',
            lat: c.lat,
            lng: c.lng,
          ),
        ),
    ];
    setState(() {
      _all = bundled;
      _shown = bundled;
      _loadingCities = widget.countryEnglishName != null;
    });
    // 2) كل مدن الدولة بالاسم من الإنترنت (تُحلّ إحداثياتها عند الاختيار).
    if (widget.countryEnglishName == null) return;
    final names = await fetchCountryCities(widget.countryEnglishName!);
    if (!mounted) return;
    final have = bundled.map((r) => r.name.toLowerCase()).toSet();
    final merged = [...bundled];
    for (final n in names) {
      if (have.add(n.toLowerCase())) merged.add(_CityRow(n, null));
    }
    setState(() {
      _all = merged;
      _shown = _filter(_ctrl.text);
      _loadingCities = false;
    });
  }

  List<_CityRow> _filter(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return _all;
    return _all.where((r) => r.name.toLowerCase().contains(query)).toList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    setState(() => _shown = _filter(q));
    // لو مفيش نتائج محلية، ابحث أونلاين في Open-Meteo (احتياطي).
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 2 || _shown.isNotEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searchingOnline = true);
      final online = await searchCities(query, countryCode: widget.countryCode);
      if (!mounted) return;
      setState(() {
        _shown = [for (final p in online) _CityRow(p.name, p)];
        _searchingOnline = false;
      });
    });
  }

  Future<void> _pick(_CityRow row) async {
    if (row.place != null) {
      Navigator.pop(context, row.place);
      return;
    }
    // مدينة بالاسم بس → هات إحداثياتها للمواعيد والطقس.
    setState(() => _resolving = true);
    final place = await resolveCity(row.name, countryCode: widget.countryCode);
    if (!mounted) return;
    setState(() => _resolving = false);
    if (place != null) {
      Navigator.pop(context, place);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('تعذّر تحديد إحداثيات «${row.name}»',
              'Could not locate "${row.name}"'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                      widget.countryName != null
                          ? tr('مدن ${widget.countryName}',
                              'Cities in ${widget.countryName}')
                          : tr('دوّر على مدينتك', 'Find your city'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (_loadingCities)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                _all.isNotEmpty
                    ? tr('${_all.length} مدينة — اختر أو ابحث',
                        '${_all.length} cities — pick or search')
                    : tr('اكتب اسم المدينة', 'Type the city name'),
                style: TextStyle(color: scheme.outline, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: false,
              onChanged: _onChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('ابحث عن مدينة', 'Search a city'),
                border: const OutlineInputBorder(),
                suffixIcon: _searchingOnline
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
              child: Stack(
                children: [
                  _shown.isEmpty
                      ? Center(
                          child: Text(
                              _loadingCities
                                  ? tr('بيحمّل المدن...', 'Loading cities...')
                                  : tr('مفيش نتائج', 'No results'),
                              style: TextStyle(color: scheme.outline)))
                      : ListView.builder(
                          itemCount: _shown.length,
                          itemBuilder: (context, i) {
                            final r = _shown[i];
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.location_on_outlined,
                                  color: scheme.primary),
                              title: Text(r.name),
                              subtitle: r.place != null &&
                                      r.place!.admin1.isNotEmpty &&
                                      r.place!.admin1 != r.name
                                  ? Text(r.place!.admin1)
                                  : null,
                              onTap: _resolving ? null : () => _pick(r),
                            );
                          },
                        ),
                  if (_resolving)
                    Positioned.fill(
                      child: ColoredBox(
                        color: scheme.surface.withValues(alpha: 0.6),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
