import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/l10n.dart';
import '../core/log.dart';
import '../widgets/common.dart';

/// «شارك التشخيص» — بيعرض ملف اللوج المحلى (آخر الأخطاء والقياسات) وبيديك
/// تشاركه أو تنسخه أو تمسحه.
///
/// **بيعرضه قبل المشاركة عن قصد**: التطبيق كله مبنى على إن بياناتك ماتخرجش
/// من الجهاز، فلازم تشوف بعينك بتبعت إيه قبل ما تبعته لأى حد.
class DiagnosticsScreen extends StatefulWidget {
  /// قراءة اللوج — بتتحقن فى التستات بس. (قراءة `dart:io` الحقيقية مابتخلصش
  /// جوه الزمن الوهمى بتاع `testWidgets`، فالشاشة بتفضل على لودينج للأبد؛
  /// الفتحة دى بتخلّى تست الودجت يجرّب منطق العرض من غير I/O — والقراءة
  /// الفعلية متغطية فى تستات `AppLog`.)
  final Future<String> Function()? readLog;

  const DiagnosticsScreen({super.key, this.readLog});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  String? _text;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await (widget.readLog ?? AppLog.read)();
    if (mounted) setState(() => _text = t);
  }

  Future<void> _share() async {
    final file = await AppLog.fileForShare();
    if (file == null) {
      _toast(tr('مفيش حاجة تتشارك', 'Nothing to share'));
      return;
    }
    await Share.shareXFiles([XFile(file.path)],
        subject: tr('تشخيص مساعدي', 'My Assistant diagnostics'));
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text ?? ''));
    _toast(tr('اتنسخ ✓', 'Copied ✓'));
  }

  Future<void> _clear() async {
    if (!await confirmDelete(context, tr('سجل التشخيص', 'the diagnostics log'))) {
      return;
    }
    await AppLog.clear();
    if (mounted) await _load();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _text;
    final empty = t == null || t.trim().isEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('التشخيص', 'Diagnostics')),
        actions: [
          IconButton(
            tooltip: tr('تحديث', 'Refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
          if (!empty)
            IconButton(
              tooltip: tr('مسح السجل', 'Clear log'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
            ),
        ],
      ),
      body: t == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 18, color: scheme.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('السجل ده محلى على جهازك — ❌ يعنى خطأ، ℹ️ يعنى معلومة. مافيهوش بياناتك، ومابيتبعتش لحد إلا لو شاركته بنفسك.',
                            'This log is local to your device — ❌ is an error, ℹ️ is info. It holds no personal data and is never sent unless you share it.'),
                        style: TextStyle(fontSize: 12, color: scheme.outline),
                      ),
                    ),
                  ]),
                ),
                const Divider(height: 16),
                Expanded(
                  child: empty
                      ? EmptyHint(
                          icon: Icons.check_circle_outline,
                          text: tr(
                              'السجل فاضى — مفيش أخطاء اتسجّلت.\nلو حصلت مشكلة، ارجع هنا وشاركها.',
                              'Log is empty — no errors recorded.\nIf something goes wrong, come back and share it.'))
                      : Scrollbar(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: SelectableText(
                              t,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 11.5),
                            ),
                          ),
                        ),
                ),
                if (!empty)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: Text(tr('نسخ', 'Copy')),
                            onPressed: _copy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.share, size: 18),
                            label: Text(tr('شارك', 'Share')),
                            onPressed: _share,
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}
