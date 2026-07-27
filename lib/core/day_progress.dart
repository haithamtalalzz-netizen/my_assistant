// حساب «إنجاز اليوم %» — نقى وقابل للاختبار.

/// نسبة إنجاز اليوم من عدّة بنود (كل بند: منجَز/إجمالى). الإجمالى صفر → صفر.
int dayCompletionPercent(List<({int done, int total})> parts) {
  var done = 0, total = 0;
  for (final p in parts) {
    if (p.total <= 0) continue;
    done += p.done.clamp(0, p.total);
    total += p.total;
  }
  if (total == 0) return 0;
  return ((done / total) * 100).round();
}

/// جملة تحفيزية حسب النسبة.
String progressMessageAr(int pct) {
  if (pct >= 100) return 'يوم كامل 👏 كله اتعمل';
  if (pct >= 75) return 'قربت تخلّص — فاضل القليل';
  if (pct >= 40) return 'ماشى كويس، كمّل';
  if (pct > 0) return 'بداية كويسة، يلا نكمّل';
  return 'ابدأ يومك — أول خطوة تفرق';
}

String progressMessageEn(int pct) {
  if (pct >= 100) return 'A full day 👏 all done';
  if (pct >= 75) return 'Almost there — just a little left';
  if (pct >= 40) return 'Going well, keep going';
  if (pct > 0) return 'Good start, let’s keep it up';
  return 'Start your day — the first step counts';
}
