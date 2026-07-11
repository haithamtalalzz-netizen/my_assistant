import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/location_tracker.dart';
import '../../data/activity_repo.dart';
import '../../data/measurements_repo.dart';
import '../../data/settings_repo.dart';
import '../../models/models.dart';

/// شاشة تتبّع المشي/الجري بالـGPS — مسافة ومدة وسرعة وسعرات لحظية.
class WalkTrackerScreen extends StatefulWidget {
  const WalkTrackerScreen({super.key});

  @override
  State<WalkTrackerScreen> createState() => _WalkTrackerScreenState();
}

class _WalkTrackerScreenState extends State<WalkTrackerScreen> {
  final _repo = ActivityRepo();
  WalkTracker? _tracker;
  Timer? _ticker;

  bool _running = false; // نوع النشاط: مشي/جري
  bool _active = false; // بيتتبّع حاليًا؟
  bool _started = false; // بدأ جلسة (حتى لو متوقّفة مؤقتًا)
  double _meters = 0;
  Duration _elapsed = Duration.zero;
  double? _speedKmh;
  double _weight = 70;
  List<ActivitySession> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final weights = await MeasurementsRepo().recent(type: 'وزن', limit: 1);
    final recent = await _repo.recent(limit: 10);
    if (!mounted) return;
    setState(() {
      if (weights.isNotEmpty) _weight = weights.first.value;
      _recent = recent;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _tracker?.dispose();
    super.dispose();
  }

  double get _distanceKm => _meters / 1000;
  int get _calories =>
      estimateCalories(distanceKm: _distanceKm, weightKg: _weight, running: _running)
          .round();
  int get _steps => estimateSteps(_meters);

  Future<void> _start() async {
    final err = await WalkTracker.ensureReady();
    if (err != null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    _tracker ??= WalkTracker((s) {
      if (!mounted) return;
      setState(() {
        _meters = s.distanceMeters;
        _elapsed = s.elapsed;
        _speedKmh = s.speedKmh;
      });
    });
    await _tracker!.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _tracker == null) return;
      setState(() => _elapsed = _tracker!.elapsed);
    });
    setState(() {
      _active = true;
      _started = true;
    });
  }

  void _pause() {
    _tracker?.pause();
    _ticker?.cancel();
    setState(() => _active = false);
  }

  Future<void> _finish() async {
    _tracker?.stop();
    _ticker?.cancel();
    if (_meters < 10) {
      // مفيش مسافة تُذكر — نلغي من غير حفظ.
      _reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('المسافة صغيرة — مفيش حاجة تتحفظ',
                'Distance too small — nothing to save'))));
      }
      return;
    }
    final day = dayKey(DateTime.now());
    await _repo.add(ActivitySession(
      day: day,
      type: _running ? 'run' : 'walk',
      distanceKm: _distanceKm,
      durationSec: _elapsed.inSeconds,
      calories: _calories,
      steps: _steps,
      createdAt: DateTime.now().toIso8601String(),
    ));
    // لو مفيش ساعة ذكية (المزامنة مقفولة)، نضيف نشاط الـGPS لحرق اليوم.
    if (!await SettingsRepo().healthSyncEnabled()) {
      final totals = await _repo.todayTotals(day);
      await MeasurementsRepo().upsertFitness(day,
          calories: totals.calories, distanceKm: totals.distanceKm);
    }
    _reset();
    await _loadContext();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr('اتحفظ: ${_fmtKm(_distanceKm)} كم · ${arNum(_calories)} سعرة',
              'Saved: ${_fmtKm(_distanceKm)} km · ${arNum(_calories)} kcal'))));
    }
  }

  void _reset() {
    _tracker?.dispose();
    _tracker = null;
    setState(() {
      _active = false;
      _started = false;
      _meters = 0;
      _elapsed = Duration.zero;
      _speedKmh = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('تتبّع المشي/الجري', 'Walk / run tracker'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // نوع النشاط.
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: false,
                  icon: const Text('🚶', style: TextStyle(fontSize: 16)),
                  label: Text(tr('مشي', 'Walk'))),
              ButtonSegment(
                  value: true,
                  icon: const Text('🏃', style: TextStyle(fontSize: 16)),
                  label: Text(tr('جري', 'Run'))),
            ],
            selected: {_running},
            onSelectionChanged:
                _started ? null : (s) => setState(() => _running = s.first),
          ),
          const SizedBox(height: 20),
          // المسافة الكبيرة.
          Center(
            child: Column(
              children: [
                Text(_fmtKm(_distanceKm),
                    style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        height: 1)),
                Text(tr('كيلومتر', 'kilometers'),
                    style: TextStyle(color: scheme.outline)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // شبكة القياسات.
          Row(
            children: [
              _stat(Icons.timer_outlined, tr('المدة', 'Time'), _fmtDuration(_elapsed)),
              _stat(Icons.local_fire_department, tr('سعرات', 'kcal'),
                  arNum(_calories)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(Icons.speed, tr('السرعة', 'Speed'),
                  _speedKmh == null ? '—' : '${_fmtKm(_speedKmh!)} ${tr('كم/س', 'km/h')}'),
              _stat(Icons.directions_walk, tr('خطوات تقريبية', 'Est. steps'),
                  arNum(_steps)),
            ],
          ),
          const SizedBox(height: 24),
          _controls(scheme),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(tr('آخر جلساتك', 'Recent sessions'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final s in _recent) _recentTile(s),
          ],
        ],
      ),
    );
  }

  Widget _controls(ColorScheme scheme) {
    if (!_started) {
      return FilledButton.icon(
        onPressed: _start,
        icon: const Icon(Icons.play_arrow),
        style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52)),
        label: Text(tr('ابدأ', 'Start')),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _active
              ? OutlinedButton.icon(
                  onPressed: _pause,
                  icon: const Icon(Icons.pause),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  label: Text(tr('إيقاف مؤقت', 'Pause')),
                )
              : FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  label: Text(tr('كمّل', 'Resume')),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _finish,
            icon: const Icon(Icons.stop),
            style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                minimumSize: const Size.fromHeight(52)),
            label: Text(tr('إنهاء وحفظ', 'Finish & save')),
          ),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label,
                style: TextStyle(fontSize: 11, color: scheme.outline)),
          ],
        ),
      ),
    );
  }

  Widget _recentTile(ActivitySession s) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Text(s.type == 'run' ? '🏃' : '🚶',
            style: const TextStyle(fontSize: 22)),
        title: Text(
            '${_fmtKm(s.distanceKm)} ${tr('كم', 'km')} · ${arNum(s.calories)} ${tr('سعرة', 'kcal')}'),
        subtitle: Text(
            '${_fmtDuration(Duration(seconds: s.durationSec))} · ${arNum(s.steps)} ${tr('خطوة', 'steps')}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            await _repo.delete(s.id!);
            await _loadContext();
          },
        ),
      ),
    );
  }

  String _fmtKm(double km) => km.toStringAsFixed(2);

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}
