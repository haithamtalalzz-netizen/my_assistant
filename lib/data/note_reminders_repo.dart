import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/notifications.dart';
import 'settings_repo.dart';

/// تكرار التذكير.
enum NoteRepeat { once, daily, weekly }

String noteRepeatKey(NoteRepeat r) => switch (r) {
      NoteRepeat.daily => 'daily',
      NoteRepeat.weekly => 'weekly',
      NoteRepeat.once => 'once',
    };

NoteRepeat noteRepeatFrom(String? s) => switch (s) {
      'daily' => NoteRepeat.daily,
      'weekly' => NoteRepeat.weekly,
      _ => NoteRepeat.once,
    };

/// تذكير مربوط بملاحظة.
class NoteReminder {
  final int noteId;

  /// خانة التذكير جوّه الملاحظة (0..9) — بتسمح بأكتر من تذكير لنفس
  /// الملاحظة، وبتحدد معرّف الإشعار.
  final int slot;

  /// وقت التذكير (ISO). للتكرار اليومى/الأسبوعى بنستخدم الساعة/الدقيقة (واليوم
  /// للأسبوعى) منه.
  final String at;
  final NoteRepeat repeat;

  /// true = منبّه قوى (صوت alarm)، false = تنبيه عادى.
  final bool alarm;

  /// ملف صوت مخصّص (اختيارى) — content:// URI + قناته + اسمه للعرض.
  final String soundUri;
  final String soundChannel;
  final String soundLabel;

  const NoteReminder({
    required this.noteId,
    this.slot = 0,
    required this.at,
    this.repeat = NoteRepeat.once,
    this.alarm = true,
    this.soundUri = '',
    this.soundChannel = '',
    this.soundLabel = '',
  });

  DateTime? get time => DateTime.tryParse(at);

  Map<String, Object?> toJson() => {
        'n': noteId,
        's': slot,
        'at': at,
        'r': noteRepeatKey(repeat),
        'a': alarm,
        'u': soundUri,
        'c': soundChannel,
        'l': soundLabel,
      };

  factory NoteReminder.fromJson(Map<String, dynamic> m) => NoteReminder(
        noteId: (m['n'] as num?)?.toInt() ?? 0,
        // تذكيرات قديمة مافيهاش خانة = الخانة صفر.
        slot: (m['s'] as num?)?.toInt() ?? 0,
        at: m['at'] as String? ?? '',
        repeat: noteRepeatFrom(m['r'] as String?),
        alarm: m['a'] as bool? ?? true,
        soundUri: m['u'] as String? ?? '',
        soundChannel: m['c'] as String? ?? '',
        soundLabel: m['l'] as String? ?? '',
      );
}

/// تذكيرات ملاحظات «تذكيراتى» — مخزّنة JSON فى الإعدادات (بلا هجرة قاعدة
/// بيانات)، وبتتجدول كإشعارات محلية بصوت منبّه أو تنبيه عادى.
class NoteRemindersRepo {
  final _s = SettingsRepo();
  static const _key = 'note_reminders';

  Future<List<NoteReminder>> all() async {
    final raw = await _s.get(_key) ?? '';
    if (raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => NoteReminder.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  /// كل تذكيرات كل ملاحظة — مرتّبة بالميعاد.
  Future<Map<int, List<NoteReminder>>> byNote() async {
    final out = <int, List<NoteReminder>>{};
    for (final r in await all()) {
      out.putIfAbsent(r.noteId, () => []).add(r);
    }
    for (final list in out.values) {
      list.sort((a, b) => a.at.compareTo(b.at));
    }
    return out;
  }

  /// تذكيرات ملاحظة واحدة.
  Future<List<NoteReminder>> listFor(int noteId) async =>
      (await byNote())[noteId] ?? const [];

  /// أقرب خانة فاضية للملاحظة (لتذكير جديد). null = وصلت الحدّ (١٠).
  Future<int?> freeSlot(int noteId) async {
    final used = {for (final r in await listFor(noteId)) r.slot};
    for (var i = 0; i < 10; i++) {
      if (!used.contains(i)) return i;
    }
    return null;
  }

  Future<void> _save(List<NoteReminder> list) async =>
      _s.set(_key, jsonEncode([for (final r in list) r.toJson()]));

  /// يحفظ (أو يستبدل) تذكيرًا فى خانته ويجدوله.
  Future<void> setFor(NoteReminder r, String noteText) async {
    final list = await all()
      ..removeWhere((e) => e.noteId == r.noteId && e.slot == r.slot);
    list.add(r);
    await _save(list);
    await _schedule(r, noteText);
  }

  /// يشيل **كل** تذكيرات ملاحظة (بيتنادى عند حذفها).
  Future<void> removeFor(int noteId) async {
    for (final r in await listFor(noteId)) {
      await Notifications.cancel(
          Notifications.noteNotifId(noteId, r.slot));
    }
    // المعرّف القديم (قبل دعم التعدّد) — لو فاضل مجدول من نسخة أقدم.
    await Notifications.cancel(Notifications.legacyNoteNotifId(noteId));
    final list = await all()..removeWhere((e) => e.noteId == noteId);
    await _save(list);
  }

  /// يشيل تذكيرًا واحدًا بخانته.
  Future<void> removeOne(int noteId, int slot) async {
    final list = await all()
      ..removeWhere((e) => e.noteId == noteId && e.slot == slot);
    await _save(list);
    await Notifications.cancel(Notifications.noteNotifId(noteId, slot));
  }

  /// يعيد جدولة كل التذكيرات (عند فتح التطبيق) + ينضّف اللى ملاحظته اتمسحت
  /// أو اللى فات ميعاده ومش متكرر.
  Future<void> rescheduleAll(Map<int, String> noteTexts) async {
    final list = await all();
    final kept = <NoteReminder>[];
    final now = DateTime.now();
    // الترقية لدعم التعدّد غيّرت معرّفات الإشعارات — نلغى القديمة صراحةً
    // وإلا تفضل مجدولة فى النظام وترنّ ومحدش يقدر يوقّفها.
    for (final noteId in noteTexts.keys) {
      await Notifications.cancel(Notifications.legacyNoteNotifId(noteId));
    }
    for (final r in list) {
      final text = noteTexts[r.noteId];
      // الملاحظة اتمسحت → التذكير ملوش لازمة.
      if (text == null) {
        await Notifications.cancel(
            Notifications.noteNotifId(r.noteId, r.slot));
        continue;
      }
      final t = r.time;
      if (r.repeat == NoteRepeat.once && (t == null || t.isBefore(now))) {
        // مرّة واحدة وفات ميعادها — نسيبها فى القايمة عشان تفضل بادچ «فات»
        // لكن من غير جدولة جديدة.
        kept.add(r);
        continue;
      }
      kept.add(r);
      await _schedule(r, text);
    }
    await _save(kept);
  }

  Future<void> _schedule(NoteReminder r, String noteText) async {
    final t = r.time;
    if (t == null) return;
    final id = Notifications.noteNotifId(r.noteId, r.slot);
    await Notifications.cancel(id);

    final body = noteText.length > 120
        ? '${noteText.substring(0, 120)}…'
        : noteText;
    const actions = <AndroidNotificationAction>[
      AndroidNotificationAction('note_done', 'تمّ ✓',
          showsUserInterface: false, cancelNotification: true),
      AndroidNotificationAction('note_snooze', '⏰ أجّل ١٠ د',
          showsUserInterface: false, cancelNotification: true),
    ];

    switch (r.repeat) {
      case NoteRepeat.once:
        await Notifications.scheduleOnce(
          id: id,
          title: 'تذكير',
          body: body,
          when: t,
          payload: 'note|${r.noteId}|${r.slot}',
          actions: actions,
          noteAlarm: r.alarm,
          adhanUri: r.soundUri.isEmpty ? null : r.soundUri,
          adhanChannel: r.soundChannel.isEmpty ? null : r.soundChannel,
        );
      case NoteRepeat.daily:
        await Notifications.scheduleDaily(
          id: id,
          title: 'تذكير يومى',
          body: body,
          hour: t.hour,
          minute: t.minute,
          payload: 'note|${r.noteId}|${r.slot}',
          actions: actions,
          noteAlarm: r.alarm,
          adhanUri: r.soundUri.isEmpty ? null : r.soundUri,
          adhanChannel: r.soundChannel.isEmpty ? null : r.soundChannel,
        );
      case NoteRepeat.weekly:
        await Notifications.scheduleWeekly(
          id: id,
          title: 'تذكير أسبوعى',
          body: body,
          weekday: t.weekday,
          hour: t.hour,
          minute: t.minute,
          payload: 'note|${r.noteId}|${r.slot}',
          actions: actions,
          noteAlarm: r.alarm,
          adhanUri: r.soundUri.isEmpty ? null : r.soundUri,
          adhanChannel: r.soundChannel.isEmpty ? null : r.soundChannel,
        );
    }
  }
}
