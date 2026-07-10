import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/medical_repo.dart';
import '../../models/models.dart';
import '../../widgets/search_action.dart';
import '../../widgets/common.dart';
import 'medical_form.dart';

class MedicalScreen extends StatefulWidget {
  final Widget? drawer;

  const MedicalScreen({super.key, this.drawer});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  final _repo = MedicalRepo();
  bool _loading = true;
  List<MedicalRecord> _records = [];

  /// null = الكل، وإلا نوع محدد.
  String? _filter;

  /// فلتر التخصص (null = كل التخصصات).
  String? _specFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await _repo.all(type: _filter);
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _openForm([MedicalRecord? r]) async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => MedicalForm(record: r)));
    if (saved == true && mounted) await _load();
  }

  IconData _iconFor(String type) => switch (type) {
        'visit' => Icons.local_hospital_outlined,
        'lab' => Icons.science_outlined,
        'imaging' => Icons.image_outlined,
        'procedure' => Icons.healing_outlined,
        _ => Icons.medical_information_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final specialties = _records
        .map((r) => r.specialty)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final shown = _specFilter == null
        ? _records
        : _records.where((r) => r.specialty == _specFilter).toList();
    return Scaffold(
      drawer: widget.drawer,
      appBar: AppBar(
        title: Text(tr('الملف الطبي', 'Medical file')),
        actions: [
          if (specialties.isNotEmpty)
            PopupMenuButton<String?>(
              tooltip: tr('فلتر التخصص', 'Filter by specialty'),
              icon: Icon(_specFilter == null
                  ? Icons.filter_list
                  : Icons.filter_list_alt),
              onSelected: (v) => setState(() => _specFilter = v),
              itemBuilder: (_) => [
                PopupMenuItem(value: null, child: Text(tr('كل التخصصات', 'All specialties'))),
                for (final s in specialties)
                  PopupMenuItem(value: s, child: Text('🩺 $s')),
              ],
            ),
          searchAction(context),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      ChoiceChip(
                        label: Text(tr('الكل', 'All')),
                        selected: _filter == null,
                        onSelected: (_) {
                          setState(() => _filter = null);
                          _load();
                        },
                      ),
                      for (final t in kMedicalTypes)
                        ChoiceChip(
                          label: Text(medicalTypeLabel(t)),
                          selected: _filter == t,
                          onSelected: (_) {
                            setState(() => _filter = t);
                            _load();
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? EmptyHint(
                          icon: Icons.medical_information_outlined,
                          text: tr(
                              'سجّل زياراتك وتحاليلك وأشعتك وإجراءاتك — كلها في مكان واحد وتطلع في تقرير الدكتور',
                              'Log your visits, labs, scans & procedures — all in one place and in the doctor report'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                            itemCount: shown.length,
                            itemBuilder: (context, i) {
                              final r = shown[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: scheme.secondaryContainer,
                                    child: Icon(_iconFor(r.type),
                                        color: scheme.onSecondaryContainer),
                                  ),
                                  title: Text(r.title),
                                  subtitle: Text([
                                    if (r.specialty.isNotEmpty) '🩺 ${r.specialty}',
                                    medicalTypeLabel(r.type),
                                    arShortDate(DateTime.parse(r.day)),
                                    if (r.provider.isNotEmpty) r.provider,
                                    if (r.photos.isNotEmpty)
                                      tr('${arNum(r.photos.length)} مرفق',
                                          '${arNum(r.photos.length)} attached'),
                                  ].join(' • ')),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        await _openForm(r);
                                      } else if (v == 'delete') {
                                        if (!await confirmDelete(context,
                                            tr('السجل "${r.title}"',
                                                'record "${r.title}"'))) {
                                          return;
                                        }
                                        await _repo.delete(r.id!);
                                        if (mounted) await _load();
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text(tr('تعديل', 'Edit'))),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text(tr('حذف', 'Delete'))),
                                    ],
                                  ),
                                  onTap: () => _openForm(r),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'medical_fab',
        onPressed: () => _openForm(),
        tooltip: tr('سجل طبي جديد', 'New medical record'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
