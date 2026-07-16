import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/notifications.dart';
import '../../data/tasks_repo.dart';

/// جلسة تركيز (بومودورو) — عدّاد تنازلى بيتسجّل فى focus_sessions لما يخلص،
/// واختيارى يرتبط بمهمة معينة.
class FocusScreen extends StatefulWidget {
  final int? taskId;
  final String? taskTitle;

  const FocusScreen({super.key, this.taskId, this.taskTitle});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  final _repo = TasksRepo();
  int _minutes = 25;
  int _remaining = 25 * 60; // بالثوانى
  Timer? _timer;
  bool _running = false;
  int _todayMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    final m = await _repo.focusMinutesOn(dayKey(DateTime.now()));
    if (mounted) setState(() => _todayMinutes = m);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pick(int minutes) {
    if (_running) return;
    setState(() {
      _minutes = minutes;
      _remaining = minutes * 60;
    });
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_remaining <= 1) {
        _timer?.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        await _finish();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _minutes * 60;
    });
  }

  Future<void> _finish() async {
    HapticFeedback.heavyImpact();
    await _repo.logFocus(taskId: widget.taskId, minutes: _minutes);
    await Notifications.showNow(
      id: 1300001,
      title: tr('خلصت جلسة التركيز 🎉', 'Focus session done 🎉'),
      body: widget.taskTitle == null
          ? tr('${arNum(_minutes)} دقيقة تركيز — خد بريك ٥ دقايق.',
              '${arNum(_minutes)} minutes of focus — take a 5-min break.')
          : tr(
              '${arNum(_minutes)} دقيقة على «${widget.taskTitle}» — خد بريك.',
              '${arNum(_minutes)} min on "${widget.taskTitle}" — take a break.'),
    );
    await _loadToday();
    if (mounted) {
      setState(() => _remaining = _minutes * 60);
    }
  }

  String get _clock {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${arNum(m)}:${arNum(s).padLeft(2, arNum(0))}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress =
        _minutes == 0 ? 0.0 : 1 - (_remaining / (_minutes * 60));
    return Scaffold(
      appBar: AppBar(title: Text(tr('جلسة تركيز 🍅', 'Focus session 🍅'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.taskTitle != null) ...[
                Text(widget.taskTitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                    Center(
                      child: Text(_clock,
                          style: const TextStyle(
                              fontSize: 44, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // اختيار المدة (متقفل أثناء التشغيل).
              Wrap(
                spacing: 8,
                children: [
                  for (final m in const [15, 25, 45])
                    ChoiceChip(
                      label: Text(tr('${arNum(m)} د', '${arNum(m)} m')),
                      selected: _minutes == m,
                      onSelected: _running ? null : (_) => _pick(m),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                    label: Text(_running
                        ? tr('إيقاف مؤقت', 'Pause')
                        : tr('ابدأ', 'Start')),
                    onPressed: _running ? _pause : _start,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('من الأول', 'Reset')),
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                tr('تركيز النهارده: ${arNum(_todayMinutes)} دقيقة',
                    "Today's focus: ${arNum(_todayMinutes)} min"),
                style: TextStyle(color: scheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
