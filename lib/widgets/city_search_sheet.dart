import 'dart:async';

import 'package:flutter/material.dart';

import '../core/geocoding.dart';
import '../core/l10n.dart';

/// شيت البحث عن أي مدينة في العالم — يرجّع [GeoPlace] المختار أو null.
Future<GeoPlace?> pickCity(BuildContext context) {
  return showModalBottomSheet<GeoPlace>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: const _CitySearchSheet(),
    ),
  );
}

class _CitySearchSheet extends StatefulWidget {
  const _CitySearchSheet();

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
      final r = await searchCities(q);
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
