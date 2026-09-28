import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_images.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/med_forms.dart';
import '../../data/pharmacy_repo.dart';
import '../../models/models.dart';
import '../../widgets/wheel_date_picker.dart';

/// صف دفعة قابل للتعديل (كمية + صلاحية مستقلة).
class BatchEdit {
  final TextEditingController qty;
  DateTime? exp;
  BatchEdit(this.qty, this.exp);
}

/// فورم «دوا فى صيدلية البيت».
///
/// بيتفتح بشكلين حسب المقاس (`showPharmacyForm`): صفحة كاملة على الموبايل،
/// وحوار عريض على التابلت/الفولد. الجسم واحد فى الحالتين.
///
/// 🔴 الشكل القديم كان `AlertDialog` بعرض ثابت، وجوّه خانة العدد ملفوفة فى
/// `SizedBox(width: 56)` — فالعنوان العائم «عدد» كان **بيتقصّ «عـ...»**
/// و«صلاحية» جنبه مزنوقة. دلوقتى الصف بيوزّع بالنِّسَب من غير عرض ثابت.
class PharmacyForm extends StatefulWidget {
  final PharmacyItem? item;

  /// دفعات الصنف الموجودة (فاضية للجديد).
  final List<PharmacyBatch> batches;

  /// true = الفورم جوّه حوار (بيرسم أزراره بنفسه بدل شريط علوى).
  final bool inDialog;

  const PharmacyForm({
    super.key,
    this.item,
    this.batches = const [],
    this.inDialog = false,
  });

  @override
  State<PharmacyForm> createState() => _PharmacyFormState();
}

class _PharmacyFormState extends State<PharmacyForm> {
  final _repo = PharmacyRepo();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _strength;
  late final TextEditingController _ingredient;
  late final TextEditingController _place;
  late final TextEditingController _person;
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _lowAt;
  final _batches = <BatchEdit>[];
  String _form = '';
  bool _cold = false;
  String _photo = '';
  bool _saving = false;

  /// التفاصيل مطويّة افتراضيًا — الإضافة السريعة تفضل «اسم + عدد + حفظ».
  /// بتتفتح لوحدها لو الصنف عنده تفاصيل متسجّلة أصلاً.
  bool _more = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _name = TextEditingController(text: it?.name ?? '');
    _notes = TextEditingController(text: it?.notes ?? '');
    _strength = TextEditingController(text: it?.strength ?? '');
    _ingredient = TextEditingController(text: it?.ingredient ?? '');
    _place = TextEditingController(text: it?.place ?? '');
    _person = TextEditingController(text: it?.person ?? '');
    _brand = TextEditingController(text: it?.brand ?? '');
    _price = TextEditingController(
        text: (it?.price ?? 0) == 0 ? '' : arNum(it!.price));
    _lowAt = TextEditingController(text: (it?.lowAt ?? 2).toString());
    _form = it?.form ?? '';
    _cold = it?.cold ?? false;
    _photo = it?.photo ?? '';
    _more = it != null &&
        (it.form.isNotEmpty ||
            it.strength.isNotEmpty ||
            it.ingredient.isNotEmpty ||
            it.place.isNotEmpty ||
            it.person.isNotEmpty ||
            it.brand.isNotEmpty ||
            it.photo.isNotEmpty ||
            it.cold ||
            it.price > 0);

    if (widget.batches.isNotEmpty) {
      for (final b in widget.batches) {
        _batches.add(BatchEdit(
            TextEditingController(text: b.quantity.toString()),
            b.expiry == null ? null : DateTime.tryParse(b.expiry!)));
      }
    } else if (it != null) {
      _batches.add(BatchEdit(TextEditingController(text: it.quantity.toString()),
          it.expiry == null ? null : DateTime.tryParse(it.expiry!)));
    } else {
      _batches.add(BatchEdit(TextEditingController(text: '1'), null));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _notes,
      _strength,
      _ingredient,
      _place,
      _person,
      _brand,
      _price,
      _lowAt,
    ]) {
      c.dispose();
    }
    for (final b in _batches) {
      b.qty.dispose();
    }
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final list = [
      for (final b in _batches)
        PharmacyBatch(
            itemId: 0,
            quantity: parseNumber(b.qty.text)?.round() ?? 1,
            expiry: b.exp == null ? null : dayKey(b.exp!)),
    ];
    final totalQty = list.fold<int>(0, (s, b) => s + b.quantity);
    final expiries = list.map((b) => b.expiry).whereType<String>().toList()
      ..sort();
    final id = await _repo.save(PharmacyItem(
      id: widget.item?.id,
      name: _name.text.trim(),
      quantity: totalQty,
      expiry: expiries.isEmpty ? null : expiries.first,
      notes: _notes.text.trim(),
      form: _form,
      strength: _strength.text.trim(),
      ingredient: _ingredient.text.trim(),
      place: _place.text.trim(),
      cold: _cold,
      lowAt: parseNumber(_lowAt.text)?.round() ?? 2,
      photo: _photo,
      person: _person.text.trim(),
      brand: _brand.text.trim(),
      price: parseNumber(_price.text) ?? 0,
    ));
    await _repo.replaceBatches(id, list);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _pickPhoto() async {
    final path = await AppImages.pickAndStore(ImageSource.gallery);
    if (path != null && mounted) setState(() => _photo = path);
  }

  Future<void> _pickExpiry(int i) async {
    final now = DateTime.now();
    final picked = await pickWheelDate(
      context,
      initial: _batches[i].exp ?? now,
      first: DateTime(now.year - 1),
      last: DateTime(now.year + 15),
    );
    if (picked != null) setState(() => _batches[i].exp = picked);
  }

  @override
  Widget build(BuildContext context) {
    final body = _body(context);
    if (widget.inDialog) return body;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null
            ? tr('دوا جديد', 'New medicine')
            : tr('تعديل', 'Edit')),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(tr('حفظ', 'Save')),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _body(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        shrinkWrap: widget.inDialog,
        physics: widget.inDialog ? const ClampingScrollPhysics() : null,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _name,
                autofocus: widget.item == null,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: tr('الاسم (مثلًا: بانادول)', 'Name (e.g. Panadol)'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _strength,
                decoration: InputDecoration(
                  labelText: tr('التركيز', 'Strength'),
                  hintText: '500mg',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: InputDecoration(
              labelText: tr('ملاحظة (لإيه؟)', 'Note (what for?)'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          _sectionLabel(context, tr('الكميات والصلاحيات', 'Quantities & expiry')),
          for (var i = 0; i < _batches.length; i++) _batchRow(context, i),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() =>
                  _batches.add(BatchEdit(TextEditingController(text: '1'), null))),
              icon: const Icon(Icons.add),
              label: Text(tr('أضف دفعة بصلاحية مختلفة', 'Add batch')),
            ),
          ),
          const SizedBox(height: 4),
          // التفاصيل مطويّة: الإضافة السريعة تفضل تلات ثوانى.
          _moreSection(context),
        ],
      );

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(text, style: Theme.of(context).textTheme.labelLarge),
        ),
      );

  /// صف الدفعة: العدد والصلاحية **بالنِّسَب** — مفيش عرض ثابت يقصّ العنوان.
  Widget _batchRow(BuildContext context, int i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _batches[i].qty,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('عدد', 'Qty'),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: () => _pickExpiry(i),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: tr('صلاحية', 'Expiry'),
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                child: Text(
                  _batches[i].exp == null
                      ? tr('بدون', 'None')
                      : arShortDate(_batches[i].exp!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: tr('شيل الدفعة', 'Remove batch'),
            icon: const Icon(Icons.close, size: 18),
            onPressed: _batches.length == 1
                ? null
                : () => setState(() => _batches.removeAt(i)),
          ),
        ]),
      );

  Widget _moreSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: () => setState(() => _more = !_more),
          icon: Icon(_more ? Icons.expand_less : Icons.expand_more),
          label: Text(_more
              ? tr('إخفاء التفاصيل', 'Hide details')
              : tr('تفاصيل أكتر', 'More details')),
        ),
      ),
      if (!_more) const SizedBox.shrink() else ...[
        const SizedBox(height: 4),
        _sectionLabel(context, tr('الشكل', 'Form')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in kMedForms)
              ChoiceChip(
                // showCheckmark: false + لون صريح — من غيرهم الشريحة
                // المختارة بتحطّ الأيقونة جوّه دايرة غامقة والتباين بيوحش.
                showCheckmark: false,
                avatar: Icon(medFormIcon(f),
                    size: 16,
                    color: _form == f
                        ? scheme.onSecondaryContainer
                        : scheme.primary),
                label: Text(f),
                selected: _form == f,
                onSelected: (on) => setState(() => _form = on ? f : ''),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ingredient,
          decoration: InputDecoration(
            labelText: tr('المادة الفعّالة', 'Active ingredient'),
            helperText: tr('بتخلّيك تعرف إن عندك نفس الدوا باسم تانى',
                'Lets you spot the same medicine under another brand'),
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _place,
          decoration: InputDecoration(
            labelText: tr('مكانه فى البيت', 'Where at home'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final p in kStoragePlaces)
              ActionChip(
                label: Text(p),
                onPressed: () => setState(() {
                  _place.text = p;
                  if (p == 'التلاجة') _cold = true;
                }),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _cold,
          onChanged: (v) => setState(() => _cold = v),
          title: Text(tr('يتحفظ مبرّد (تلاجة)', 'Keep refrigerated')),
          secondary: Icon(Icons.ac_unit, color: scheme.primary),
        ),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: _lowAt,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('نبّهنى لمّا يقلّ عن', 'Warn me under'),
                helperText: tr('بدل الرقم الثابت ٢', 'Instead of a fixed 2'),
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _person,
              decoration: InputDecoration(
                labelText: tr('لمين؟', 'For whom?'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: _brand,
              decoration: InputDecoration(
                labelText: tr('الشركة', 'Brand'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: tr('السعر', 'Price'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _sectionLabel(context, tr('صورة العلبة/النشرة', 'Box / leaflet photo')),
        _photoBox(context),
      ],
      if (widget.inDialog) ...[
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          const SizedBox(width: 8),
          FilledButton(
              onPressed: _canSave ? _save : null,
              child: Text(tr('حفظ', 'Save'))),
        ]),
      ],
    ]);
  }

  Widget _photoBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_photo.isEmpty) {
      return OutlinedButton.icon(
        onPressed: _pickPhoto,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(tr('أضف صورة', 'Add photo')),
      );
    }
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AppImage(_photo, width: 84, height: 84, fit: BoxFit.cover),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Wrap(spacing: 8, children: [
          TextButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: Text(tr('غيّرها', 'Replace')),
          ),
          TextButton.icon(
            onPressed: () => setState(() => _photo = ''),
            icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
            label: Text(tr('شيلها', 'Remove'),
                style: TextStyle(color: scheme.error)),
          ),
        ]),
      ),
    ]);
  }
}

/// بيفتح الفورم بالشكل اللى يناسب المقاس:
/// **موبايل → صفحة كاملة** (مساحة أوسع للكتابة)، **تابلت/فولد → حوار عريض**
/// (مايبقاش كارت صغير وسط شاشة فاضية). بيرجّع true لو اتحفظ.
Future<bool?> showPharmacyForm(
  BuildContext context, {
  PharmacyItem? item,
  List<PharmacyBatch> batches = const [],
}) {
  final wide = MediaQuery.of(context).size.width >= 600;
  if (!wide) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PharmacyForm(item: item, batches: batches)),
    );
  }
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                item == null
                    ? tr('دوا جديد', 'New medicine')
                    : tr('تعديل', 'Edit'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
          ),
          Flexible(
            child: PharmacyForm(item: item, batches: batches, inDialog: true),
          ),
        ]),
      ),
    ),
  );
}
