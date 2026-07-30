import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/l10n.dart';
import '../../core/log.dart';

/// شيت إملاء عام: بيسمع كلامك ويحوّله نصًّا ويرجّعه لمّا تدوس «تمام».
/// بيرجّع النص، أو null لو اتلغى/مفيش نص.
///
/// [initial] نص موجود يتكمّل عليه (للتعديل)، و[title] عنوان الشيت.
Future<String?> showDictationSheet(
  BuildContext context, {
  String initial = '',
  String? title,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).viewPadding.bottom),
      child: _DictationSheet(initial: initial, title: title),
    ),
  );
}

class _DictationSheet extends StatefulWidget {
  final String initial;
  final String? title;
  const _DictationSheet({required this.initial, this.title});

  @override
  State<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends State<_DictationSheet> {
  final _stt = SpeechToText();
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  /// النص اللى كان موجود قبل جولة السماع الحالية — عشان الإملاء يتراكم
  /// بدل ما كل جولة تمسح اللى قبلها.
  String _base = '';
  bool _listening = false;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _stt.stop();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final ok = await _stt.initialize(
        onStatus: (status) {
          if (status == 'notListening' && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (e) => logInfo('خطأ فى الإملاء الصوتى: ${e.errorMsg}'),
      );
      if (!ok) {
        if (mounted) setState(() => _unavailable = true);
        return;
      }
      await _listen();
    } on Exception catch (e) {
      logError('فشلت تهيئة الإملاء الصوتى', e);
      if (mounted) setState(() => _unavailable = true);
    }
  }

  Future<void> _listen() async {
    // نثبّت النص الحالى كأساس، واللى هيتقال يتضاف عليه.
    _base = _ctrl.text.trim();
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions:
          SpeechListenOptions(partialResults: true, localeId: 'ar_EG'),
      onResult: (result) {
        if (!mounted) return;
        final said = result.recognizedWords.trim();
        final merged = _base.isEmpty ? said : '$_base $said';
        setState(() {
          _ctrl.text = merged;
          _ctrl.selection =
              TextSelection.collapsed(offset: _ctrl.text.length);
        });
      },
    );
  }

  Future<void> _stop() async {
    await _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_listening ? Icons.mic : Icons.mic_off,
                  color: _listening ? scheme.error : scheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title ?? tr('اكتب بصوتك', 'Dictate'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (_listening)
                TextButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop, size: 18),
                  label: Text(tr('إيقاف', 'Stop')),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _unavailable
                ? tr('التعرّف الصوتى مش متاح على الجهاز ده — تقدر تكتب بإيدك.',
                    'Speech recognition unavailable — you can type instead.')
                : _listening
                    ? tr('اتكلم دلوقتى…', 'Speak now…')
                    : tr('وقفت السمع — تقدر تعدّل النص أو تسجّل تانى',
                        'Stopped — edit the text or record again'),
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: null,
            minLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              filled: true,
              border: const OutlineInputBorder(),
              hintText: tr('النص هيظهر هنا…', 'Text will appear here…'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!_listening && !_unavailable)
                OutlinedButton.icon(
                  onPressed: _listen,
                  icon: const Icon(Icons.mic, size: 18),
                  label: Text(tr('سجّل تانى', 'Record again')),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('إلغاء', 'Cancel')),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () async {
                  await _stt.stop();
                  final text = _ctrl.text.trim();
                  if (!context.mounted) return;
                  Navigator.pop(context, text.isEmpty ? null : text);
                },
                child: Text(tr('تمام', 'Done')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
