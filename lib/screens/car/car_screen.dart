import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/cars_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// السيارة — قائمة السيارات، كل واحدة تفتح صفحتها بأحداثها وإحصائياتها.
class CarScreen extends StatefulWidget {
  const CarScreen({super.key});

  @override
  State<CarScreen> createState() => _CarScreenState();
}

class _CarScreenState extends State<CarScreen> {
  final _repo = CarsRepo();
  bool _loading = true;
  List<Car> _cars = [];
  final Map<int, double> _spent = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cars = await _repo.cars();
    _spent.clear();
    for (final c in cars) {
      if (c.id != null) _spent[c.id!] = await _repo.totalSpent(c.id!);
    }
    if (!mounted) return;
    setState(() {
      _cars = cars;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('السيارة', 'Car'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _cars.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 60),
                      EmptyHint(
                          icon: Icons.directions_car_outlined,
                          text: tr('ضيف سيارتك بزرار +', 'Add your car with +')),
                    ])
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                      children: [
                        for (final c in _cars)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    scheme.primaryContainer,
                                child: const Icon(Icons.directions_car),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text([
                                if (c.plate.isNotEmpty) c.plate,
                                if (c.odometer > 0)
                                  tr('${arNum(c.odometer)} كم',
                                      '${arNum(c.odometer)} km'),
                                tr('صُرف ${egp(_spent[c.id] ?? 0)}',
                                    'Spent ${egp(_spent[c.id] ?? 0)}'),
                              ].join('  •  ')),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => _openCar(c),
                            ),
                          ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _carForm(),
        tooltip: tr('سيارة جديدة', 'New car'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCar(Car c) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => CarDetailScreen(car: c)));
    if (mounted) await _load();
  }

  Future<void> _carForm([Car? car]) async {
    final name = TextEditingController(text: car?.name ?? '');
    final plate = TextEditingController(text: car?.plate ?? '');
    final make = TextEditingController(text: car?.make ?? '');
    final model = TextEditingController(text: car?.model ?? '');
    final odo = TextEditingController(
        text: car == null || car.odometer == 0 ? '' : '${car.odometer}');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(car == null ? tr('سيارة جديدة', 'New car') : tr('تعديل', 'Edit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                autofocus: car == null,
                decoration: InputDecoration(
                    labelText: tr('الاسم (عربيتي…)', 'Name (my car…)'))),
            const SizedBox(height: 8),
            TextField(
                controller: plate,
                decoration:
                    InputDecoration(labelText: tr('رقم اللوحة', 'Plate'))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: make,
                      decoration: InputDecoration(
                          labelText: tr('الماركة', 'Make')))),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: model,
                      decoration: InputDecoration(
                          labelText: tr('الموديل', 'Model')))),
            ]),
            const SizedBox(height: 8),
            TextField(
                controller: odo,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: tr('العدّاد (كم)', 'Odometer (km)'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr('إلغاء', 'Cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('حفظ', 'Save'))),
        ],
      ),
    );

    if (saved == true && name.text.trim().isNotEmpty) {
      await _repo.saveCar(Car(
        id: car?.id,
        name: name.text.trim(),
        plate: plate.text.trim(),
        make: make.text.trim(),
        model: model.text.trim(),
        odometer: int.tryParse(toEnglishDigits(odo.text.trim())) ?? 0,
        notes: car?.notes ?? '',
        createdAt: car?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    for (final c in [name, plate, make, model, odo]) {
      c.dispose();
    }
  }
}

/// صفحة سيارة واحدة — إحصائياتها وأحداثها.
class CarDetailScreen extends StatefulWidget {
  final Car car;
  const CarDetailScreen({super.key, required this.car});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  final _repo = CarsRepo();
  List<CarEvent> _events = [];
  double _spent = 0;
  double? _economy;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await _repo.events(widget.car.id!, type: _typeFilter);
    final spent = await _repo.totalSpent(widget.car.id!);
    final economy = await _repo.fuelEconomy(widget.car.id!);
    if (!mounted) return;
    setState(() {
      _events = events;
      _spent = spent;
      _economy = economy;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.car.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _stat(tr('صُرف', 'Spent'), egp(_spent), scheme),
                    _stat(tr('العدّاد', 'Odometer'),
                        tr('${arNum(widget.car.odometer)} كم',
                            '${arNum(widget.car.odometer)} km'),
                        scheme),
                    _stat(
                        tr('كفاءة الوقود', 'Fuel eco'),
                        _economy == null
                            ? '—'
                            : tr('${_economy!.toStringAsFixed(1)} كم/ل',
                                '${_economy!.toStringAsFixed(1)} km/L'),
                        scheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(tr('الكل', 'All')),
                      selected: _typeFilter == null,
                      onSelected: (_) {
                        setState(() => _typeFilter = null);
                        _load();
                      },
                    ),
                  ),
                  for (final t in kCarEventTypes)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text(carEventTypeLabel(t)),
                        selected: _typeFilter == t,
                        onSelected: (_) {
                          setState(() => _typeFilter = t);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (_events.isEmpty)
              EmptyHint(
                  icon: Icons.build_outlined,
                  text: tr('مفيش أحداث — ضيف بزرار +', 'No events — add with +'))
            else
              for (final e in _events) _eventTile(e, scheme),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _eventForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _stat(String label, String value, ColorScheme scheme) => Expanded(
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: scheme.onPrimaryContainer)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8))),
          ],
        ),
      );

  Widget _eventTile(CarEvent e, ColorScheme scheme) {
    final sub = <String>[
      arShortDate(DateTime.parse(e.day)),
      if (e.cost > 0) egp(e.cost),
      if (e.liters != null) tr('${e.liters} لتر', '${e.liters} L'),
      if (e.odometer != null) tr('${arNum(e.odometer!)} كم', '${arNum(e.odometer!)} km'),
      if (e.note.isNotEmpty) e.note,
    ].join('  •  ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(_typeIcon(e.type), color: scheme.primary),
        title: Text(carEventTypeLabel(e.type),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sub +
            (e.nextDueDate != null
                ? '\n${tr('التجديد: ${arShortDate(e.nextDueDate!)}', 'Renew: ${arShortDate(e.nextDueDate!)}')}'
                : '')),
        isThreeLine: e.nextDueDate != null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') await _eventForm(e);
            if (v == 'delete') {
              await _repo.deleteEvent(e.id!);
              await _load();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Text(tr('تعديل', 'Edit'))),
            PopupMenuItem(value: 'delete', child: Text(tr('حذف', 'Delete'))),
          ],
        ),
        onTap: () => _eventForm(e),
      ),
    );
  }

  IconData _typeIcon(String t) => switch (t) {
        'service' => Icons.build_outlined,
        'fuel' => Icons.local_gas_station_outlined,
        'insurance' => Icons.shield_outlined,
        'license' => Icons.badge_outlined,
        _ => Icons.receipt_long_outlined,
      };

  Future<void> _eventForm([CarEvent? ev]) async {
    var type = ev?.type ?? 'service';
    DateTime day = ev == null ? DateTime.now() : DateTime.parse(ev.day);
    final cost = TextEditingController(
        text: ev == null || ev.cost == 0 ? '' : ev.cost.toStringAsFixed(0));
    final odo = TextEditingController(
        text: ev?.odometer == null ? '' : '${ev!.odometer}');
    final liters = TextEditingController(
        text: ev?.liters == null ? '' : '${ev!.liters}');
    final note = TextEditingController(text: ev?.note ?? '');
    DateTime? nextDue = ev?.nextDueDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(ev == null ? tr('حدث جديد', 'New event') : tr('تعديل', 'Edit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  for (final t in kCarEventTypes)
                    ChoiceChip(
                      label: Text(carEventTypeLabel(t)),
                      selected: type == t,
                      onSelected: (_) => setD(() => type = t),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Text(arShortDate(day))),
                TextButton.icon(
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(tr('التاريخ', 'Date')),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: day,
                      firstDate: DateTime(2015),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setD(() => day = d);
                  },
                ),
              ]),
              TextField(
                  controller: cost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: tr('التكلفة (ج.م)', 'Cost (EGP)'))),
              TextField(
                  controller: odo,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: tr('العدّاد (كم)', 'Odometer (km)'))),
              if (type == 'fuel')
                TextField(
                    controller: liters,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: tr('عدد اللترات', 'Liters'))),
              if (type == 'insurance' || type == 'license') ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Text(nextDue == null
                        ? tr('موعد التجديد الجاى', 'Next renewal')
                        : tr('التجديد: ${arShortDate(nextDue!)}',
                            'Renew: ${arShortDate(nextDue!)}')),
                  ),
                  if (nextDue != null)
                    IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setD(() => nextDue = null)),
                  TextButton.icon(
                    icon: const Icon(Icons.event_repeat, size: 18),
                    label: Text(tr('تجديد', 'Renew')),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate:
                            nextDue ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setD(() => nextDue = d);
                    },
                  ),
                ]),
              ],
              TextField(
                  controller: note,
                  decoration:
                      InputDecoration(labelText: tr('ملاحظة', 'Note'))),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('إلغاء', 'Cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('حفظ', 'Save'))),
          ],
        ),
      ),
    );

    if (saved == true) {
      await _repo.saveEvent(CarEvent(
        id: ev?.id,
        carId: widget.car.id!,
        type: type,
        day: dayKey(day),
        cost: double.tryParse(toEnglishDigits(cost.text.trim())) ?? 0,
        odometer: int.tryParse(toEnglishDigits(odo.text.trim())),
        liters: type == 'fuel'
            ? double.tryParse(toEnglishDigits(liters.text.trim()))
            : null,
        nextDue: (type == 'insurance' || type == 'license')
            ? nextDue?.toIso8601String()
            : null,
        note: note.text.trim(),
        createdAt: ev?.createdAt ?? DateTime.now().toIso8601String(),
      ));
      if (mounted) await _load();
    }
    for (final c in [cost, odo, liters, note]) {
      c.dispose();
    }
  }
}
