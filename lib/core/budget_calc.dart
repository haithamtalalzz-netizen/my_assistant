// حساب «المتاح للصرف» — نقى وقابل للاختبار. كله على الجهاز.

class SafeToSpend {
  final double remaining; // المتبقّى لباقى الشهر بعد الالتزامات
  final int daysLeft; // شامل النهاردة
  final double perDay; // المتاح صرفه النهاردة

  const SafeToSpend(this.remaining, this.daysLeft, this.perDay);
}

/// عدد أيام شهر [now].
int daysInMonth(DateTime now) => DateTime(now.year, now.month + 1, 0).day;

/// المتاح للصرف يوميًا = (الميزانية − المصروف − الالتزامات المتبقّية) ÷ باقى الأيام.
SafeToSpend safeToSpend({
  required double budget,
  required double spent,
  required double upcomingObligations,
  required DateTime now,
}) {
  final remaining = budget - spent - upcomingObligations;
  final daysLeft = daysInMonth(now) - now.day + 1;
  final perDay = daysLeft > 0 ? remaining / daysLeft : remaining;
  return SafeToSpend(remaining, daysLeft, perDay);
}
