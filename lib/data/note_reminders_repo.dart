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
        'at': at,
        'r': noteRepeatKey(repeat),
        'a': alarm,
        'u': soundUri,
        'c': soundChannel,
        'l': soundLabel,
      };

  factory NoteReminder.fromJson(Map<String, dynamic> m) => NoteReminder(
        noteId: (m['n'] as num?)?.toInt() ?? 0,
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

  Future<Map<int, NoteReminder>> byNote() async =>
      {for (final r in await all()) r.noteId: r};

  Future<NoteReminder?> forNote(int noteId) async {
    for (final r in await all()) {
      if (r.noteId == noteId) return r;
    }
    return null;
  }

  Future<void> _save(List<NoteReminder> list) async =>
      _s.set(_key, jsonEncode([for (final r in list) r.toJson()]));

  /// يحفظ (أو يستبدل) تذكير ملاحظة ويجدوله.
  Future<void> setFor(NoteReminder r, String noteText) async {
    final list = await all()
      ..removeWhere((e) => e.noteId == r.noteId);
    list.add(r);
    await _save(list);
    await _schedule(r, noteText);
  }

  /// يشيل التذكير ويلغى إشعاره.
  Future<void> removeFor(int noteId) async {
    final list = await all()..removeWhere((e) => e.noteId == noteId);
    await _save(list);
    await Notifications.cancel(Notifications.noteNotifId(noteId));
  }

  /// يعيد جدولة كل التذكيرات (عند فتح التطبيق) + ينضّف اللى ملاحظته اتمسحت
  /// أو اللى فات ميعاده ومش متكرر.
  Future<void> rescheduleAll(Map<int, String> noteTexts) async {
    final list = await all();
    final kept = <NoteReminder>[];
    final now = DateTime.now();
    for (final r in list) {
      final text = noteTexts[r.noteId];
      // الملاحظة اتمسحت → التذكير ملوش لازمة.
      if (text == null) {
        await Notifications.cancel(Notifications.noteNotifId(r.noteId));
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
    final id = Notifications.noteNotifId(r.noteId);
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
          payload: 'note|${r.noteId}',
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
          payload: 'note|${r.noteId}',
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
          payload: 'note|${r.noteId}',
          actions: actions,
          noteAlarm: r.alarm,
          adhanUri: r.soundUri.isEmpty ? null : r.soundUri,
          adhanChannel: r.soundChannel.isEmpty ? null : r.soundChannel,
        );
    }
  }
}
