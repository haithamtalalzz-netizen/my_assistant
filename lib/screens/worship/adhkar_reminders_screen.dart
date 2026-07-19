import 'package:flutter/material.dart';

import '../../core/adhkar_reminders.dart';
import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/settings_repo.dart';

/// إعداد تذكير أذكار الصباح والمساء — تنبيهين يوميين في الأوقات اللى تختارها.
class AdhkarRemindersScreen extends StatefulWidget {
  const AdhkarRemindersScreen({super.key});

  @override
  State<AdhkarRemindersScreen> createState() => _AdhkarRemindersScreenState();
}

class _AdhkarRemindersScreenState extends State<AdhkarRemindersScreen> {
  final _settings = SettingsRepo();
  bool _loading = true;
  bool _on = false;
  TimeOfDay _morning = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _evening = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _on = (await _settings.get('adhkar_reminders')) == '1';
    final (mh, mm) =
        parseHm(await _settings.get('adhkar_morning_time'), defH: 6, defM: 30);
    final (eh, em) =
        parseHm(await _settings.get('adhkar_evening_time'), defH: 17, defM: 0);
    _morning = TimeOfDay(hour: mh, minute: mm);
    _evening = TimeOfDay(hour: eh, minute: em);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  String _hm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _label(TimeOfDay t) => arTime(DateTime(2000, 1, 1, t.hour, t.minute));

  Future<void> _save() async {
    await _settings.set('adhkar_reminders', _on ? '1' : '0');
    await _settings.set('adhkar_morning_time', _hm(_morning));
    await _settings.set('adhkar_evening_time', _hm(_evening));
    await AdhkarReminders.reschedule();
  }

  Future<void> _pick(bool morning) async {
    final picked = await showTimePicker(
        context: context, initialTime: morning ? _morning : _evening);
    if (picked == null) return;
    setState(() {
      if (morning) {
        _morning = picked;
      } else {
        _evening = picked;
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('تذكير الأذكار', 'Adhkar reminders'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Text(
                tr('نبّهك بأذكار الصباح والمساء في وقتها كل يوم.',
                    'Remind you of morning & evening adhkar at their time daily.'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  title: Text(tr('تفعيل التذكير', 'Enable reminders')),
                  secondary: const Icon(Icons.notifications_active_outlined),
                  value: _on,
                  onChanged: (v) async {
                    setState(() => _on = v);
                    await _save();
                  },
                ),
              ),
              if (_on) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: Text(tr('أذكار الصباح', 'Morning adhkar')),
                    trailing: Text(_label(_morning),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _pick(true),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.nightlight_round),
                    title: Text(tr('أذكار المساء', 'Evening adhkar')),
                    trailing: Text(_label(_evening),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () => _pick(false),
                  ),
                ),
              ],
            ]),
    );
  }
}
