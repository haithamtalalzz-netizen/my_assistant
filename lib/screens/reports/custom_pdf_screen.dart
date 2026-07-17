import '../../core/log.dart';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/custom_report.dart';
import '../../core/l10n.dart';
import '../../widgets/wheel_date_picker.dart';

/// شاشة تقرير PDF مخصّص — يختار المستخدم البنود ومدى التاريخ.
class CustomPdfScreen extends StatefulWidget {
  const CustomPdfScreen({super.key});

  @override
  State<CustomPdfScreen> createState() => _CustomPdfScreenState();
}

class _CustomPdfScreenState extends State<CustomPdfScreen> {
  final Set<String> _selected = {...kReportSections.keys};
  late DateTime _from;
  late DateTime _to;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: isFrom ? _from : _to,
      first: now.subtract(const Duration(days: 366 * 5)),
      last: now.add(const Duration(days: 366)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _export() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اختار بند واحد على الأقل', 'Pick at least one section'))));
      return;
    }
    setState(() => _busy = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(tr('بجهّز التقرير...', 'Preparing report...'))));
    try {
      await CustomReport.generateAndShare(
          kinds: _selected, from: _from, to: _to);
    } on Exception catch (e) {
      logError('فشل تقرير PDF', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('حصلت مشكلة', 'Something went wrong'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selected.length == kReportSections.length;
    return Scaffold(
      appBar: AppBar(title: Text(tr('تقرير PDF مخصّص', 'Custom PDF report'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: tr('من', 'From')),
                    child: Text(arShortDate(_from)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: InputDecorator(
                    decoration: InputDecoration(labelText: tr('إلى', 'To')),
                    child: Text(arShortDate(_to)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(tr('البنود المطلوبة', 'Sections'),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => setState(() {
                  if (allSelected) {
                    _selected.clear();
                  } else {
                    _selected
                      ..clear()
                      ..addAll(kReportSections.keys);
                  }
                }),
                child: Text(allSelected
                    ? tr('إلغاء الكل', 'Clear all')
                    : tr('اختيار الكل', 'Select all')),
              ),
            ],
          ),
          for (final e in kReportSections.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(e.value),
              value: _selected.contains(e.key),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _selected.add(e.key);
                } else {
                  _selected.remove(e.key);
                }
              }),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(tr('تصدير PDF ومشاركته', 'Export & share PDF')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportCsv,
            icon: const Icon(Icons.table_view_outlined),
            label: Text(tr('تصدير Excel (CSV)', 'Export Excel (CSV)')),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(tr('اختار بند واحد على الأقل', 'Pick at least one section'))));
      return;
    }
    setState(() => _busy = true);
    try {
      await CustomReport.generateCsvAndShare(
          kinds: _selected, from: _from, to: _to);
    } on Exception catch (e) {
      logError('فشل تقرير Excel', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('حصلت مشكلة', 'Something went wrong'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
