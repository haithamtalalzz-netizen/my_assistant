import 'package:flutter/material.dart';

import '../core/ar.dart';
import '../core/day_close.dart';
import '../core/l10n.dart';
import '../core/prayers.dart';
import '../data/habits_repo.dart';
import '../data/health_repo.dart';
import '../data/worship_repo.dart';
import 'food/meal_sheet.dart';
import 'money/quick_expense_sheet.dart';
import 'schedule/schedule_screen.dart';

/// «قفل اليوم» — مراجعة مسائية بتلف على الناقص وتسجّله بضغطة، عشان مفيش
/// حاجة تفوت مع قلب اليوم بعد ١٢ بالليل.
class DayCloseScreen extends StatefulWidget {
  const DayCloseScreen({super.key});

  @override
  State<DayCloseScreen> createState() => _DayCloseScreenState();
}

class _DayCloseScreenState extends State<DayCloseScreen> {
  DayCloseStatus? _s;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await collectDayClose();
    if (mounted) setState(() => _s = s);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: Text(tr('قفل اليوم 🌙', 'Close the day 🌙'))),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (s.allDone)
                  _doneBanner(scheme)
                else
                  Text(
                    tr('فاضل ${arNum(s.pendingCount)} بند قبل ما تنام — سجّلهم بضغطة:',
                        '${arNum(s.pendingCount)} items left — one tap each:'),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                const SizedBox(height: 12),

                // ————— الصلوات الناقصة —————
                if (s.missedPrayers.isNotEmpty) ...[
                  _header('🕌', tr('صلوات لسه ماتسجّلتش', 'Unlogged prayers'),
                      scheme),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final i in s.missedPrayers)
                      ActionChip(
                        avatar: const Icon(Icons.check, size: 16),
                        label: Text(prayerNameLabel(i)),
                        onPressed: () async {
                          await WorshipRepo()
                              .togglePrayer(DateTime.now(), i, true);
                          await _load();
                        },
                      ),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ————— المياه —————
                if (s.remainingWaterMl > 0) ...[
                  _header('💧',
                      tr('فاضل ${arNum(s.remainingWaterMl)} مل مياه',
                          '${arNum(s.remainingWaterMl)} mL water left'),
                      scheme),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final ml in const [250, 500])
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text('${arNum(ml)} ${tr('مل', 'mL')}'),
                        onPressed: () async {
                          await HealthRepo()
                              .addWaterMl(dayKey(DateTime.now()), ml);
                          await _load();
                        },
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.done_all, size: 16),
                      label: Text(tr('وصلت للهدف', 'Reached the goal')),
                      onPressed: () async {
                        await HealthRepo().setWaterMl(
                            dayKey(DateTime.now()), s.waterGoalMl);
                        await _load();
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ————— العادات —————
                if (s.pendingHabits.isNotEmpty) ...[
                  _header('✅', tr('عادات لسه ماتعملتش', 'Pending habits'),
                      scheme),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final h in s.pendingHabits)
                      ActionChip(
                        avatar: const Icon(Icons.check, size: 16),
                        label: Text(h.name),
                        onPressed: () async {
                          // markDone بيوصّل العدّاد للهدف — يشتغل للعادة
                          // العادية والمعدودة.
                          await HabitsRepo()
                              .markDone(h.id!, dayKey(DateTime.now()));
                          await _load();
                        },
                      ),
                  ]),
                  const SizedBox(height: 16),
                ],

                // ————— الأدوية —————
                if (s.missedDoses > 0) ...[
                  _header('💊',
                      tr('${arNum(s.missedDoses)} جرعة دوا ناقصة',
                          '${arNum(s.missedDoses)} missed doses'),
                      scheme),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.medication_outlined, size: 18),
                      label: Text(tr('افتح الأدوية وسجّلها', 'Open meds & log')),
                      onPressed: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScheduleScreen()));
                        await _load();
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const Divider(),
                const SizedBox(height: 8),
                // ————— مراجعة (مش ناقص، بس تسجّل لو نسيت) —————
                _reviewRow(
                  scheme,
                  '💸',
                  tr('مصروف النهارده: ${egp(s.todaySpend)}',
                      "Today's spend: ${egp(s.todaySpend)}"),
                  tr('+ مصروف', '+ Expense'),
                  () async {
                    await showQuickExpenseSheet(context);
                    await _load();
                  },
                ),
                _reviewRow(
                  scheme,
                  '🍽',
                  tr('سعرات النهارده: ${arNum(s.mealKcal.round())}',
                      "Today's kcal: ${arNum(s.mealKcal.round())}"),
                  tr('+ وجبة', '+ Meal'),
                  () async {
                    await showMealSheet(context);
                    await _load();
                  },
                ),
                const SizedBox(height: 20),
                if (s.allDone)
                  Center(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.nightlight_round),
                      label: Text(tr('تصبح على خير 🌙', 'Good night 🌙')),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _doneBanner(ColorScheme scheme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Text('🎉', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('يومك مقفول — كل حاجة متسجّلة. تصبح على خير!',
                  'Day closed — everything logged. Good night!'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ]),
      );

  Widget _header(String emoji, String text, ColorScheme scheme) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: scheme.primary)),
        ]),
      );

  Widget _reviewRow(ColorScheme scheme, String emoji, String text,
          String action, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
          TextButton(onPressed: onTap, child: Text(action)),
        ]),
      );
}
