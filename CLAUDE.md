# My Assistant — Root Context

> **This file is auto-loaded every session.** Entry point for all work on this project.

## Session Start Protocol

```
STEP 1: Read SESSION_HANDOVER.md — what's done, in progress, known issues
STEP 2: Read this file — architecture, rules, current state
STEP 3: Ask the user what they want to work on
STEP 4: Read the relevant module file in lib/
STEP 5: Read PRODUCT_VISION.md only when planning new features
```

## Quick Start

**Project:** تطبيق "مدير شخصي" عربي — صحة، مواعيد، أدوية، فلوس، مستندات، عادات،
صلاة، تخطيط أسبوعي، نسخ احتياطي، قفل بصمة، ويدجت، تسجيل صوتي، Health Connect.
**Stack:** Flutter 3.44 / Dart 3.12 + sqflite + flutter_local_notifications +
local_auth + adhan_dart + archive/share_plus/file_picker +
home_widget/health/speech_to_text (minSdk 26)
**Path:** `C:\work\my_assistant`
**Package:** `com.hhub.my_assistant` — display name "My Assistant"
**Language:** Arabic-first + English toggle (progressive i18n). `AppState.locale` drives MaterialApp locale/direction; `tr('عربي','English')` helper in `core/l10n.dart` — chrome/nav/settings translated, content screens migrate screen-by-screen. Theme via `AppState.themeMode` (system/light/dark).
**Navigation:** sidebar Drawer (`screens/app_drawer.dart`) — NO bottom nav. Shell swaps 5 top screens by index; each top screen takes `Widget? drawer`. Tools/بلدنا/settings are pushed (back-arrow) from the drawer.
**Tests:** `flutter test` — 84 passed / 0 failed
**Analyze:** `flutter analyze` — must stay at 0 issues
**Run:** `flutter run` (device/emulator) • **Build:** `flutter build apk --release`
**DB:** schema v7 (v6→v7 adds debts + gameya + gameya_payments + home_maintenance);
every schema change bumps version + adds `upgradeSchema` branch
(each branch checks BOTH `oldV < X && newV >= X`) + a migration test
**Font:** Cairo static weights bundled as assets (NO google_fonts — fully offline)
**Theme:** light + dark (ThemeMode.system)

## Architecture

```
lib/
  main.dart            bootstrap: intl ar + notifications init
  app.dart             MaterialApp (ar locale, RTL, theme)
  core/
    ar.dart            أرقام عربية للعرض + قراءة أرقام شرقية + تواريخ + dayKey
    db.dart            AppDb singleton (sqflite) + createSchema + useForTests
    notifications.dart Notifications wrapper (once / daily / cancel) + id ranges
    theme.dart         Material3, seed 0x0E7A5F, Cairo font (google_fonts)
    prayers.dart       مواعيد الصلاة (adhan_dart) + المحافظات + PrayerScheduler
    backup.dart        تصدير/استعادة zip + إعادة جدولة التنبيهات
    health_service.dart Health Connect (خطوات + نوم) — best-effort
    voice_parser.dart  محلل الأوامر الصوتية العربي (pure Dart — مختبر)
    widget_bridge.dart دفع بيانات الويدجت + callback زرار المياه
    insights.dart      محرك الرؤى الإحصائي (pure — بيرسون/أنماط/اتجاهات)
    day_planner.dart   مجدول «رتبلي يومي» (pure)
    doctor_report.dart تقرير PDF عربي RTL بخط Cairo (asset)
    ocr.dart           ML Kit (أرقام/تواريخ فقط — مفيش عربي) + مستخرجات نقية
    gemini.dart        عميل Gemini المجاني (REST + fallback موديلات)
  models/models.dart   Appointment, Medication, Expense, DocItem, Habit
  data/                repo per module — كل الـ SQL هنا، مفيش SQL في الشاشات
  screens/
    shell.dart         NavigationBar: اليوم/الجدول/الفلوس/العادات/المستندات
    today_screen.dart  شاشة اليوم + ملخص المدير المبني على قواعد
    schedule/          tabs: مواعيد + أدوية، وforms ليهم
    money/             شاشة الفلوس + quick_expense_sheet (مشترك مع اليوم)
    docs/              خزنة المستندات + form بصورة وتاريخ انتهاء
    habits/            عادات بسلاسل + يوم رحمة
    settings_screen.dart
  widgets/common.dart  SectionHeader, EmptyHint, confirmDelete
```

**Data flow:** Screen → Repo → AppDb. Screens never touch SQL directly.
Screens are rebuilt fresh on each tab switch (shell builds them per build) so
data is always reloaded — no global state management package on purpose.

## Notification ID ranges (DO NOT overlap)

| Range | Owner |
|---|---|
| 100000 + id | Appointment one-shot reminders |
| 200000 + id*10 + slot | Medication daily repeats (max 10 slots/med) |
| 300000 + id | Document expiry one-shots |
| 400000 + day*10 + prayer | Prayer adhan one-shots (7 days ahead, refreshed on every app open) |
| 500000 + weekday | Workout weekly repeats (dayOfWeekAndTime) |
| 600000 + id | Occasion next-occurrence one-shots (refreshed on every app open) |
| 700001 | Evening "ملخص بكرة" one-shot (refreshed on every app open) |
| 800000 + index | Day-plan item reminders (canceled+recreated per plan generation) |
| 900000 + id | Recurring-bill monthly repeats (dayOfMonthAndTime) w/ «اتدفعت ✓» action |
| 910001 | Streak-guard 21:00 one-shot (recomputed on open + every habit toggle) |
| 920001/920002 | Smart water 16:00/20:00 conditional one-shots (recomputed on every water change) |
| 930001 | Month-summary immediate notification (once per month, first 3 days) |
| 940000 + id | Med-course-ended immediate notifications |
| 950000 + id | Debt reminders (reserved) |
| 960000 + id | Gam'iya monthly installment reminders |
| 970000 + id | Home-maintenance due reminders |

Rescheduling rule: every repo `save()` cancels old notification(s) then
re-schedules. Deleting always cancels.

## Top Rules

1. **Arabic-first** — display numbers via `arNum()`, parse input via
   `parseNumber()` (accepts ٠-٩ and ۰-۹). Dates via `arFullDate/arShortDate/arTime`.
   New user-facing strings: wrap in `tr('عربي','English')` so they migrate to EN.
2. **dayKey(DateTime) = YYYY-MM-DD** is the canonical day format in every
   daily table (water, sleep, med_logs, habit_logs, expenses.day, documents.expiry).
3. **DB singleton** — `AppDb.instance`, never close it. Tests inject in-memory
   ffi DB via `AppDb.useForTests()` + `AppDb.reset()` in tearDown.
4. **Notifications are best-effort** — `Notifications` no-ops if init failed;
   exact alarm falls back to inexact on `PlatformException`. Never let
   notification failures break a save.
5. **Streak rule (العادات)** — `computeStreak()`: walking backwards, 1 mercy
   day per scanned 7 days; today-not-done-yet doesn't break the streak.
   Mercy day doesn't count toward the streak.
6. **Quick logging** — any user logging action must be ≤3 seconds
   (quick expense sheet, water +, sleep chips, habit chip). Keep it that way.
7. **No hardcoded category lists in screens** — categories live in
   `kExpenseCategories` (money_repo.dart) and `kApptCategories`
   (appointment_form.dart).
8. **Never swallow exceptions** — catch narrow and log with `dart:developer log`.

## Android specifics

- `flutter_local_notifications` needs **core library desugaring** — already
  enabled in `android/app/build.gradle.kts` (desugar_jdk_libs 2.1.5). Don't remove.
- Manifest has POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM,
  VIBRATE + the two flutter_local_notifications receivers (boot reschedule).
- Known build gotchas on this machine (from past Flutter projects): if Gradle
  hangs, stop the Kotlin daemon; `flutter clean` after adding new assets.

## Session End Protocol

1. `flutter analyze` — 0 issues
2. `flutter test` — all pass
3. Update SESSION_HANDOVER.md
4. New table/column? Update the schema section in db.dart and this file if structural
5. New feature decision? Append to PRODUCT_VISION.md
