import '../../core/log.dart';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/voice_parser.dart';
import '../../data/appointments_repo.dart';
import '../../data/habits_repo.dart';
import '../../data/debts_repo.dart';
import '../../data/health_repo.dart';
import '../../data/inbox_repo.dart';
import '../../data/meals_repo.dart';
import '../../data/measurements_repo.dart';
import '../../data/meds_repo.dart';
import '../../data/income_repo.dart';
import '../../data/money_repo.dart';
import '../../data/workout_repo.dart';
import '../../models/models.dart';

/// شيت التسجيل الصوتي: اسمع → اعرض النص والأفعال المفهومة → نفّذ بعد التأكيد.
Future<bool?> showVoiceSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom),
      child: const _VoiceSheet(),
    ),
  );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  final _stt = SpeechToText();
  String _text = '';
  bool _listening = false;
  bool _unavailable = false;
  bool _busy = false;
  List<VoiceAction> _actions = [];
  List<Medication> _meds = [];
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  Future<void> _init() async {
    _meds = await MedsRepo().all(activeOnly: true);
    _habits = await HabitsRepo().active();
    try {
      final ok = await _stt.initialize(
        onStatus: (status) {
          if (status == 'notListening' && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (e) => logInfo('خطأ في التعرف الصوتي: ${e.errorMsg}'),
      );
      if (!ok) {
        if (mounted) setState(() => _unavailable = true);
        return;
      }
      await _listen();
    } on Exception catch (e) {
      logError('فشلت تهيئة التعرف الصوتي', e);
      if (mounted) setState(() => _unavailable = true);
    }
  }

  Future<void> _listen() async {
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions:
          SpeechListenOptions(partialResults: true, localeId: 'ar_EG'),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _text = result.recognizedWords;
          _actions = parseUtterance(
            _text,
            habitNames: [for (final h in _habits) h.name],
            medNames: [for (final m in _meds) m.name],
          );
        });
      },
    );
  }

  IconData _iconFor(VoiceActionType type) => switch (type) {
        VoiceActionType.expense => Icons.account_balance_wallet_outlined,
        VoiceActionType.income => Icons.south_west,
        VoiceActionType.water => Icons.water_drop_outlined,
        VoiceActionType.sleep => Icons.bedtime_outlined,
        VoiceActionType.medTaken => Icons.medication_outlined,
        VoiceActionType.habitDone => Icons.task_alt,
        VoiceActionType.appointment => Icons.event,
        VoiceActionType.meal => Icons.restaurant_outlined,
        VoiceActionType.workoutDone => Icons.fitness_center,
        VoiceActionType.measurement => Icons.monitor_heart_outlined,
        VoiceActionType.inboxNote => Icons.inbox_outlined,
        VoiceActionType.debt => Icons.handshake_outlined,
      };

  Future<void> _execute() async {
    if (_actions.isEmpty || _busy) return;
    setState(() => _busy = true);
    await _stt.stop();
    final day = dayKey(DateTime.now());
    for (final a in _actions) {
      switch (a.type) {
        case VoiceActionType.expense:
          await MoneyRepo().add(Expense(
            amount: a.amount!,
            category: a.category ?? 'أخرى',
            note: a.note ?? '',
            day: day,
          ));
        case VoiceActionType.income:
          await IncomeRepo().add(Income(
            amount: a.amount!,
            source: a.category ?? 'أخرى',
            day: day,
          ));
        case VoiceActionType.water:
          await HealthRepo().addWater(day, a.amount!.toInt());
        case VoiceActionType.sleep:
          await HealthRepo().setSleep(day, a.amount!);
        case VoiceActionType.medTaken:
          await _markMed(a, day);
        case VoiceActionType.habitDone:
          await _markHabit(a, day);
        case VoiceActionType.appointment:
          await AppointmentsRepo().save(Appointment(
            title: a.title!,
            category: a.category ?? 'شخصي',
            when: a.when!,
          ));
        case VoiceActionType.meal:
          await MealsRepo().add(Meal(
            day: day,
            slot: a.matchName ?? 'سناك',
            description: a.note ?? '',
          ));
        case VoiceActionType.workoutDone:
          final repo = WorkoutRepo();
          final plan = await repo.plan();
          await repo.setDone(day, true,
              title: plan[DateTime.now().weekday] ?? 'تمرين');
        case VoiceActionType.measurement:
          await MeasurementsRepo().add(Measurement(
            day: day,
            type: a.matchName!,
            value: a.amount!,
            value2: a.amount2,
            unit: a.note ?? '',
          ));
        case VoiceActionType.inboxNote:
          await InboxRepo().add(a.note!);
        case VoiceActionType.debt:
          await DebtsRepo().add(Debt(
            person: a.matchName!,
            amount: a.amount!,
            direction: a.category!,
            createdAt: DateTime.now().toIso8601String(),
          ));
      }
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _markMed(VoiceAction a, String day) async {
    final repo = MedsRepo();
    final taken = await repo.takenOn(day);
    final candidates = a.matchName == null || a.matchName!.isEmpty
        ? _meds
        : _meds.where((m) => m.name.contains(a.matchName!)).toList();
    for (final m in candidates) {
      for (final slot in m.times) {
        if (!taken.contains('${m.id}|$slot')) {
          await repo.setTaken(m.id!, day, slot, true);
          return;
        }
      }
    }
  }

  Future<void> _markHabit(VoiceAction a, String day) async {
    final repo = HabitsRepo();
    final habit = _habits.where((h) => h.name == a.matchName).toList();
    if (habit.isEmpty) return;
    final done = await repo.doneOn(day);
    if (!done.contains(habit.first.id)) {
      await repo.toggle(habit.first.id!, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _listening ? Icons.mic : Icons.mic_off,
                color: _listening ? scheme.error : scheme.outline,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _unavailable
                      ? tr('التعرف الصوتي مش متاح على الجهاز',
                          'Speech recognition unavailable')
                      : _listening
                          ? tr('بسمعك... اتكلم براحتك', "Listening... go ahead")
                          : tr('وقفت السمع', 'Stopped listening'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (!_listening && !_unavailable)
                TextButton.icon(
                  onPressed: _listen,
                  icon: const Icon(Icons.refresh),
                  label: Text(tr('سمّع تاني', 'Listen again')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _text.isEmpty
                  ? tr('مثلًا: «صرفت ١٥٠ بنزين وشربت ٣ مياه»\nأو «موعد دكتور بكرة الساعة ٥»',
                      'e.g. "صرفت ١٥٠ بنزين وشربت ٣ مياه"\nor "موعد دكتور بكرة الساعة ٥"')
                  : _text,
              style: TextStyle(
                color: _text.isEmpty ? scheme.outline : null,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_actions.isNotEmpty) ...[
            Text(tr('فهمت الآتي:', 'Understood:'),
                style: TextStyle(
                    color: scheme.outline, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in _actions)
                  Chip(
                    avatar: Icon(_iconFor(a.type),
                        size: 18, color: scheme.primary),
                    label: Text(a.describe(),
                        style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ] else if (_text.isNotEmpty) ...[
            Text(tr('لسه مش فاهم قصدك — كمّل كلام أو جرب صيغة تانية',
                "Didn't catch it — keep talking or rephrase"),
                style: TextStyle(color: scheme.outline)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed:
                      _actions.isEmpty || _busy ? null : _execute,
                  child: Text(_actions.isEmpty
                      ? tr('سجل', 'Log')
                      : tr('سجل (${arNum(_actions.length)})',
                          'Log (${arNum(_actions.length)})')),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
