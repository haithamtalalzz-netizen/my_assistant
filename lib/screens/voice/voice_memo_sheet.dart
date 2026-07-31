import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import '../../core/ar.dart';
import '../../core/l10n.dart';
import '../../core/log.dart';
import '../../data/voice_memos_repo.dart';

/// إشارة إن المستخدم شال المذكرة الصوتية.
class MemoRemoved {
  const MemoRemoved();
}

/// شيت تسجيل/تشغيل مذكرة صوتية لملاحظة.
/// بيرجّع [VoiceMemo] بعد الحفظ، أو [MemoRemoved] لو اتشالت، أو null.
Future<Object?> showVoiceMemoSheet(
  BuildContext context, {
  required int noteId,
  VoiceMemo? existing,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _VoiceMemoSheet(noteId: noteId, existing: existing),
  );
}

class _VoiceMemoSheet extends StatefulWidget {
  final int noteId;
  final VoiceMemo? existing;
  const _VoiceMemoSheet({required this.noteId, this.existing});

  @override
  State<_VoiceMemoSheet> createState() => _VoiceMemoSheetState();
}

class _VoiceMemoSheetState extends State<_VoiceMemoSheet> {
  final _rec = AudioRecorder();
  final _player = AudioPlayer();

  bool _recording = false;
  bool _playing = false;
  int _elapsed = 0; // ثوانى التسجيل الجارى
  Timer? _tick;
  bool _unavailable = false;

  /// مسار التسجيل الجديد قبل الحفظ (null = مفيش تسجيل جديد).
  String? _newPath;
  int _newSeconds = 0;

  /// المذكرة المحفوظة (لو فيه واحدة) — للتشغيل.
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _initSaved();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  Future<void> _initSaved() async {
    final e = widget.existing;
    if (e == null || kIsWeb) return;
    final path = await VoiceMemosRepo.pathOf(e.file);
    if (await File(path).exists() && mounted) {
      setState(() => _savedPath = path);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _rec.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (kIsWeb) {
      setState(() => _unavailable = true);
      return;
    }
    try {
      if (!await _rec.hasPermission()) {
        if (mounted) setState(() => _unavailable = true);
        return;
      }
      final dir = await VoiceMemosRepo.dir();
      final name = 'note_${widget.noteId}_'
          '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path = p.join(dir.path, name);
      await _rec.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed++);
      });
      if (mounted) {
        setState(() {
          _recording = true;
          _elapsed = 0;
          _newPath = path;
        });
      }
    } on Exception catch (e, st) {
      logError('فشل بدء التسجيل الصوتى', e, st);
      if (mounted) setState(() => _unavailable = true);
    }
  }

  Future<void> _stop() async {
    _tick?.cancel();
    try {
      final path = await _rec.stop();
      if (mounted) {
        setState(() {
          _recording = false;
          _newSeconds = _elapsed;
          _newPath = path ?? _newPath;
          // تسجيل قصير جدًا = على الأغلب دوسة غلط.
          if (_newSeconds < 1) _newPath = null;
        });
      }
    } on Exception catch (e, st) {
      logError('فشل إيقاف التسجيل الصوتى', e, st);
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _togglePlay(String path) async {
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(path));
    if (mounted) setState(() => _playing = true);
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // اللى هيتشغّل: التسجيل الجديد لو موجود، وإلا المحفوظ.
    final playable = _newPath ?? _savedPath;
    final canSave = _newPath != null && _newSeconds >= 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.mic, color: scheme.primary),
              const SizedBox(width: 8),
              Text(tr('مذكرة صوتية', 'Voice memo'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 6),
            Text(
              _unavailable
                  ? tr('التسجيل مش متاح — اتأكد من إذن الميكروفون.',
                      'Recording unavailable — check the mic permission.')
                  : _recording
                      ? tr('بسجّل… دوس «إيقاف» لما تخلص',
                          'Recording… tap Stop when done')
                      : canSave
                          ? tr('اسمعها قبل ما تحفظ', 'Listen before saving')
                          : widget.existing != null
                              ? tr('فيه مذكرة محفوظة — تقدر تشغّلها أو تسجّل بدلها',
                                  'A memo is saved — play it or record a new one')
                              : tr('دوس الميكروفون عشان تبدأ التسجيل',
                                  'Tap the mic to start recording'),
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            // زر التسجيل الكبير + العدّاد
            Center(
              child: Column(children: [
                Material(
                  color: _recording
                      ? scheme.error
                      : scheme.primaryContainer,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _unavailable
                        ? null
                        : (_recording ? _stop : _start),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Icon(_recording ? Icons.stop : Icons.mic,
                          size: 40,
                          color: _recording
                              ? scheme.onError
                              : scheme.onPrimaryContainer),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _recording
                      ? _fmt(_elapsed)
                      : canSave
                          ? _fmt(_newSeconds)
                          : widget.existing?.durationLabel ?? '0:00',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _recording ? scheme.error : scheme.onSurface),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            // تشغيل
            if (playable != null && !_recording)
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => _togglePlay(playable),
                  icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                  label: Text(_playing
                      ? tr('إيقاف التشغيل', 'Stop')
                      : tr('تشغيل', 'Play')),
                ),
              ),
            const SizedBox(height: 18),
            Row(children: [
              if (widget.existing != null && !_recording)
                TextButton.icon(
                  onPressed: () async {
                    await _player.stop();
                    if (!context.mounted) return;
                    Navigator.pop(context, const MemoRemoved());
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                  label: Text(tr('امسح المذكرة', 'Delete'),
                      style: TextStyle(color: scheme.error)),
                ),
              const Spacer(),
              TextButton(
                onPressed: _recording
                    ? null
                    : () async {
                        await _player.stop();
                        // تسجيل جديد اتعمل ومااتحفظش → نمسح ملفه.
                        final np = _newPath;
                        if (np != null) {
                          try {
                            final f = File(np);
                            if (await f.exists()) await f.delete();
                          } on FileSystemException catch (e) {
                            logError('فشل حذف تسجيل ملغى', e);
                          }
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: !canSave
                    ? null
                    : () async {
                        await _player.stop();
                        if (!context.mounted) return;
                        Navigator.pop(
                          context,
                          VoiceMemo(
                            noteId: widget.noteId,
                            file: p.basename(_newPath!),
                            seconds: _newSeconds,
                            createdAt: DateTime.now().toIso8601String(),
                          ),
                        );
                      },
                child: Text(tr('حفظ', 'Save')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// شارة صغيرة للمذكرة الصوتية تحت الملاحظة — بتشغّل/بتوقّف عند الضغط.
class VoiceMemoChip extends StatefulWidget {
  final VoiceMemo memo;
  const VoiceMemoChip({super.key, required this.memo});

  @override
  State<VoiceMemoChip> createState() => _VoiceMemoChipState();
}

class _VoiceMemoChipState extends State<VoiceMemoChip> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (kIsWeb) return;
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    final path = await VoiceMemosRepo.pathOf(widget.memo.file);
    if (!await File(path).exists()) return;
    await _player.play(DeviceFileSource(path));
    if (mounted) setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.tertiary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_playing ? Icons.stop : Icons.play_arrow,
              size: 13, color: scheme.tertiary),
          const SizedBox(width: 3),
          Text(arNum(widget.memo.durationLabel),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.tertiary)),
        ]),
      ),
    );
  }
}
