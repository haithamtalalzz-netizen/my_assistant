import 'package:flutter/material.dart';

import '../core/l10n.dart';

/// عنصر قائمة يتشال بالسحب (يمين→شمال في RTL) مع خلفية حمرا وأيقونة سلة،
/// وبعد الحذف بيطلع سناك-بار «تراجع» (لو `onUndo` متوفّر) بيرجّع العنصر.
///
/// الاستخدام: لُفّ الـ`Card` بتاعتك جواه وادّي `id` فريد + `onDelete` (بيحذف
/// ويعيد التحميل) + `onUndo` اختياري (بيعيد إضافة العنصر ويعيد التحميل).
class SwipeToDelete extends StatelessWidget {
  final Object id;
  final Widget child;
  final Future<void> Function() onDelete;
  final Future<void> Function()? onUndo;
  final String? undoLabel;
  final EdgeInsetsGeometry margin;

  const SwipeToDelete({
    super.key,
    required this.id,
    required this.child,
    required this.onDelete,
    this.onUndo,
    this.undoLabel,
    this.margin = const EdgeInsets.symmetric(vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 24),
        margin: margin,
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onError),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        await onDelete();
        if (onUndo != null) {
          messenger.showSnackBar(SnackBar(
            content: Text(undoLabel ?? tr('اتمسح', 'Deleted')),
            action: SnackBarAction(
              label: tr('تراجع', 'Undo'),
              onPressed: () => onUndo!(),
            ),
          ));
        }
      },
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;

  /// زر اختياري تحت النص (مثلًا «＋ ضيف أول واحد») — بيبدأ إجراء الإضافة مباشرة.
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyHint({
    super.key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.outline;
    // Center + سقف عرض + padding أفقي → النص بيلفّ دايمًا ومبيتقصّش من الأطراف،
    // حتى لو الأب مدّى عرض غير محدود أو المستخدم مكبّر خط النظام.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.10),
                ),
                child: Icon(icon,
                    size: 34, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: muted)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('إلغاء', 'Cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> confirmDelete(BuildContext context, String what) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr('حذف $what', 'Delete $what')),
      content: Text(tr('متأكد إنك عايز تحذف $what؟ مفيش رجوع في الخطوة دي.',
          'Delete $what? This cannot be undone.')),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('إلغاء', 'Cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(tr('حذف', 'Delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}
