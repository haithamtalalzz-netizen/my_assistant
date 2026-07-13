import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/settings_repo.dart';

/// مؤقّت راحة بين المجموعات — عدّاد تنازلى + اهتزاز عند الانتهاء (محلى ومجانى).
Future<void> showRestTimer(BuildContext context) async {
  final saved = int.tryParse(await SettingsRepo().get('gym_rest_seconds') ?? '') ?? 90;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RestTimerSheet(initial: saved),
  );
}

const _presets = [30, 60, 90, 120, 180];

class _RestTimerSheet extends StatefulWidget {
  final int initial;
  const _RestTimerSheet({required this.initial});

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  late int _total = widget.initial;
  late int _remaining = widget.initial;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    if (_remaining <= 0) _remaining = _total;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        setState(() => _running = false);
        _fireDone();
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset(int seconds) {
    _timer?.cancel();
    SettingsRepo().set('gym_rest_seconds', '$seconds');
    setState(() {
      _total = seconds;
      _remaining = seconds;
      _running = false;
    });
  }

  Future<void> _fireDone() async {
    // اهتزاز متكرّر عند انتهاء الراحة.
    for (var i = 0; i < 3; i++) {
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  String _fmt(int s) {
    final m = (s ~/ 60).toString();
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _total == 0 ? 0.0 : (_remaining / _total).clamp(0.0, 1.0);
    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 24 + MediaQuery.of(context).viewPadding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('مؤقّت الراحة', 'Rest timer'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: _remaining <= 5 && _remaining > 0
                        ? scheme.error
                        : scheme.primary,
                  ),
                ),
                Text(_fmt(_remaining < 0 ? 0 : _remaining),
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            children: [
              for (final s in _presets)
                ChoiceChip(
                  label: Text(tr('${arNum(s)} ث', '${arNum(s)}s')),
                  selected: _total == s,
                  onSelected: (_) => _reset(s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _reset(_total),
                icon: const Icon(Icons.replay),
                label: Text(tr('صفّر', 'Reset')),
              ),
              FilledButton.icon(
                onPressed: _running ? _pause : _start,
                icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                label: Text(_running ? tr('إيقاف', 'Pause') : tr('ابدأ', 'Start')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
