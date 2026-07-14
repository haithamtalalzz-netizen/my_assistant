import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../data/fasting_repo.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';

/// الصيام المتقطّع — مؤقّت نافذة الصيام (16:8 وغيره) + سجل + عدّاد الأسبوع.
class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

const _targets = [14, 16, 18, 20];

class _FastingScreenState extends State<FastingScreen> {
  final _repo = FastingRepo();
  Timer? _ticker;
  bool _loading = true;
  FastSession? _current;
  List<FastSession> _history = [];
  int _weekCount = 0;
  int _target = 16;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _current != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final cur = await _repo.current();
    final hist = await _repo.recent();
    final week = await _repo.completedLast(7);
    if (!mounted) return;
    setState(() {
      _current = cur;
      _history = hist;
      _weekCount = week;
      if (cur != null) _target = cur.targetHours;
      _loading = false;
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('الصيام المتقطّع', 'Intermittent fasting'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _timerCard(scheme),
                const SizedBox(height: 16),
                if (_weekCount > 0)
                  Center(
                    child: Text(
                        tr('🔥 ${arNum(_weekCount)} صيام مكتمل هذا الأسبوع',
                            '🔥 ${arNum(_weekCount)} fasts completed this week'),
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 8),
                if (_history.isNotEmpty) ...[
                  SectionHeader(tr('السجل', 'History')),
                  for (final f in _history) _historyTile(f, scheme),
                ],
              ],
            ),
    );
  }

  Widget _timerCard(ColorScheme scheme) {
    final ongoing = _current != null;
    final elapsed = _current?.elapsed ?? Duration.zero;
    final targetDur = Duration(hours: _target);
    final progress = ongoing
        ? (elapsed.inSeconds / targetDur.inSeconds).clamp(0.0, 1.0)
        : 0.0;
    final reached = ongoing && _current!.reachedTarget;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CircularProgressIndicator(
                      value: ongoing ? progress : 0,
                      strokeWidth: 12,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: reached ? Colors.green : scheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ongoing ? _fmt(elapsed) : '--:--',
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w900)),
                      Text(
                          ongoing
                              ? tr('من ${arNum(_target)} ساعة', 'of ${arNum(_target)}h')
                              : tr('مش صايم', 'Not fasting'),
                          style: TextStyle(color: scheme.outline)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!ongoing) ...[
              Wrap(
                spacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  for (final t in _targets)
                    ChoiceChip(
                      label: Text('$t:${24 - t}'),
                      selected: _target == t,
                      onSelected: (_) => setState(() => _target = t),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: Text(tr('ابدأ الصيام', 'Start fasting')),
                  onPressed: () async {
                    await _repo.start(targetHours: _target);
                    await _load();
                  },
                ),
              ),
            ] else ...[
              Text(
                  tr('بدأت ${arTime(_current!.start)}',
                      'Started ${arTime(_current!.start)}'),
                  style: TextStyle(color: scheme.outline)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.stop),
                  label: Text(reached
                      ? tr('أفطر (اكتمل ✓)', 'Break fast (done ✓)')
                      : tr('أنهِ الصيام', 'End fast')),
                  onPressed: () async {
                    await _repo.stop();
                    await _load();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historyTile(FastSession f, ColorScheme scheme) {
    final ok = f.reachedTarget;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(ok ? Icons.check_circle : Icons.timelapse,
            color: ok ? Colors.green : scheme.outline),
        title: Text(tr('${arNum(f.elapsed.inHours)} ساعة ${arNum(f.elapsed.inMinutes % 60)} دقيقة',
            '${arNum(f.elapsed.inHours)}h ${arNum(f.elapsed.inMinutes % 60)}m')),
        subtitle: Text(
            '${arShortDate(f.start)} · ${arTime(f.start)}'
            '${f.end != null ? ' → ${arTime(f.end!)}' : ''}'),
        trailing: Text(tr('هدف ${arNum(f.targetHours)}س', 'goal ${arNum(f.targetHours)}h'),
            style: TextStyle(fontSize: 12, color: scheme.outline)),
      ),
    );
  }
}
