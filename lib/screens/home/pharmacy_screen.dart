import 'package:flutter/material.dart';

import '../../core/app_images.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/med_forms.dart';
import '../../data/pharmacy_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../schedule/med_form.dart';
import 'pharmacy_form.dart';
import '../../core/privacy.dart';

/// جسم صيدلية البيت من غير شريط — عشان «أدويتى» المدمجة تحطّه فى
/// تبويب. الشاشة المستقلة لسه موجودة لأى مكان بيفتحها لوحدها.
class PharmacyScreen extends StatefulWidget {
  /// جوّه تبويب: من غير شريط علوى (الشريط بتاع «أدويتى» بيكفى).
  final bool embedded;

  const PharmacyScreen({super.key, this.embedded = false});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _repo = PharmacyRepo();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  bool _expiredOnly = false;
  List<PharmacyItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.search(_searchCtrl.text);
    // الأقرب انتهاءً (والمنتهي) الأول؛ اللي من غير صلاحية في الآخر.
    items.sort((a, b) {
      if (a.expiry == null && b.expiry == null) return 0;
      if (a.expiry == null) return 1;
      if (b.expiry == null) return -1;
      return a.expiry!.compareTo(b.expiry!);
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  /// عدد المنتهي + القريب من الانتهاء (خلال ٦٠ يوم) + المخزون المنخفض.
  ({int expired, int soon, int low}) _expiryCounts() {
    final now = DateTime.now();
    var expired = 0, soon = 0, low = 0;
    for (final it in _items) {
      if (it.quantity > 0 && it.quantity <= it.lowAt) low++;
      final exp = it.expiry == null ? null : DateTime.tryParse(it.expiry!);
      if (exp == null) continue;
      if (exp.isBefore(now)) {
        expired++;
      } else if (exp.difference(now).inDays <= 60) {
        soon++;
      }
    }
    return (expired: expired, soon: soon, low: low);
  }

  bool _isExpired(PharmacyItem it, DateTime now) {
    final e = it.expiry == null ? null : DateTime.tryParse(it.expiry!);
    return e != null && e.isBefore(now);
  }

  /// بيفتح الفورم بالشكل المناسب للمقاس (صفحة على الموبايل · حوار عريض
  /// على التابلت) — التفاصيل كلها فى `pharmacy_form.dart`.
  Future<void> _form([PharmacyItem? item]) async {
    final batches =
        item == null ? const <PharmacyBatch>[] : await _repo.batchesFor(item.id!);
    if (!mounted) return;
    final saved = await showPharmacyForm(context, item: item, batches: batches);
    if (saved == true && mounted) await _load();
  }

  Widget _expiryBanner(BuildContext context) {
    final c = _expiryCounts();
    if (c.expired == 0 && c.soon == 0 && c.low == 0) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final parts = [
      if (c.expired > 0) tr('${arNum(c.expired)} منتهي', '${arNum(c.expired)} expired'),
      if (c.soon > 0)
        tr('${arNum(c.soon)} قربت تنتهي', '${arNum(c.soon)} expiring soon'),
      if (c.low > 0)
        tr('${arNum(c.low)} مخزون منخفض', '${arNum(c.low)} low stock'),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.expired > 0
            ? scheme.errorContainer
            : scheme.tertiary.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: c.expired > 0 ? scheme.onErrorContainer : scheme.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(parts.join(' • '),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: c.expired > 0 ? scheme.onErrorContainer : null)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final visible =
        _expiredOnly ? _items.where((it) => _isExpired(it, now)).toList() : _items;
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(tr('صيدلية البيت', 'Home pharmacy')),
              actions: [
                const PrivacyAction(),
                IconButton(
                  tooltip: tr('المنتهى فقط', 'Expired only'),
                  isSelected: _expiredOnly,
                  icon: const Icon(Icons.filter_alt_outlined),
                  selectedIcon: const Icon(Icons.filter_alt),
                  onPressed: () =>
                      setState(() => _expiredOnly = !_expiredOnly),
                ),
              ]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: tr('عندك بانادول؟ دوّر...', 'Got Panadol? Search...'),
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          if (!_loading && _searchCtrl.text.isEmpty) _expiryBanner(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? EmptyHint(
                        icon: Icons.medication_outlined,
                        actionLabel: _searchCtrl.text.isEmpty && !_expiredOnly
                            ? tr('ضيف دوا', 'Add medicine')
                            : null,
                        onAction: _searchCtrl.text.isEmpty && !_expiredOnly
                            ? () => _form()
                            : null,
                        text: _expiredOnly
                            ? tr('مفيش دوا منتهى', 'No expired meds')
                            : _searchCtrl.text.isEmpty
                                ? tr('سجّل أدوية البيت وصلاحيتها — تعرف عندك إيه وتتنبّه قبل ما تخلص',
                                    'Log home meds & expiry — know what you have and get alerts')
                                : tr('مش موجود عندك', "You don't have it"))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final it = visible[i];
                          final exp = it.expiry == null
                              ? null
                              : DateTime.tryParse(it.expiry!);
                          final expired = exp != null && exp.isBefore(now);
                          final soon = exp != null &&
                              !expired &&
                              exp.difference(now).inDays <= 60;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            child: ListTile(
                              leading: it.photo.isEmpty
                                  ? Icon(medFormIcon(it.form),
                                      color: expired
                                          ? scheme.error
                                          : scheme.primary)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AppImage(it.photo,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover),
                                    ),
                              title: Text(
                                  '${it.display}  ×${arNum(it.quantity)}'),
                              subtitle: Text([
                                if (it.notes.isNotEmpty) it.notes,
                                // من غير إيموچى: خط التطبيق (Cairo)
                                // مافيهوش 📍/❄/👤/⚠ فبتطلع مربّعات فاضية.
                                if (it.place.isNotEmpty)
                                  tr('فى ${it.place}', 'in ${it.place}'),
                                if (it.cold) tr('مبرّد', 'Cold'),
                                if (it.person.isNotEmpty)
                                  tr('لـ ${it.person}', 'for ${it.person}'),
                                if (it.quantity > 0 &&
                                    it.quantity <= it.lowAt)
                                  tr('مخزون منخفض', 'Low stock'),
                                if (exp != null)
                                  expired
                                      ? tr('منتهي ${arShortDate(exp)}',
                                          'Expired ${arShortDate(exp)}')
                                      : tr('صلاحية ${arShortDate(exp)}',
                                          'Expires ${arShortDate(exp)}'),
                              ].join(' • ')),
                              subtitleTextStyle: expired || soon
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: expired
                                              ? scheme.error
                                              : Colors.orange)
                                  : null,
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    await _form(it);
                                  } else if (v == 'tomeds') {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                MedForm(initialName: it.name)));
                                    if (mounted) await _load();
                                  } else if (v == 'delete') {
                                    await _repo.delete(it.id!);
                                    if (mounted) await _load();
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: Text(tr('تعديل', 'Edit'))),
                                  PopupMenuItem(
                                      value: 'tomeds',
                                      child: Text(tr('أضفه لجدول الأدوية',
                                          'Add to med schedule'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: Text(tr('حذف', 'Delete'))),
                                ],
                              ),
                              onTap: () => _form(it),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'pharmacy_fab',
        onPressed: () => _form(),
        tooltip: tr('دوا جديد', 'New medicine'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
