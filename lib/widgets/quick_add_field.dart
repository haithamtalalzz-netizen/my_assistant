import 'package:flutter/material.dart';

import '../core/l10n.dart';

/// صف إضافة سريعة موحّد: خانة كتابة + زر «+» جنبها.
///
/// بيحل فئة أخطاء اتكشفت من لوج مستخدم (كيبورد سامسونج/العربى):
/// - `autocorrect/enableSuggestions = false` بيمنع «النص المعلّق» (composing)
///   اللى كان بيخلّى الخانة تتقرا فاضية وقت الضغط على «+».
/// - الضغط على «+» والخانة فاضية بيدّي تنبيه بدل ما يعمل حاجة صامتة (فيبان
///   إن الزرار مش شغّال).
/// - بعد الإضافة التركيز بيفضل فى الخانة عشان تكتب اللى بعده على طول.
class QuickAddField extends StatefulWidget {
  /// عنوان الخانة (label/hint).
  final String label;

  /// بينفّذ الإضافة بالنص المكتوب (بعد trim، مضمون إنه مش فاضى).
  final Future<void> Function(String text) onSubmit;

  /// تنبيه الخانة الفاضية (افتراضى رسالة عامة).
  final String? emptyHint;

  const QuickAddField({
    super.key,
    required this.label,
    required this.onSubmit,
    this.emptyHint,
  });

  @override
  State<QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends State<QuickAddField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _focus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(widget.emptyHint ??
              tr('اكتب فى الخانة الأول', 'Type in the field first'))));
      return;
    }
    await widget.onSubmit(text);
    if (!mounted) return;
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: widget.label),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _submit, icon: const Icon(Icons.add)),
      ],
    );
  }
}
