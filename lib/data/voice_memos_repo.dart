import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/log.dart';
import 'settings_repo.dart';

/// مذكرة صوتية مرفقة بملاحظة.
class VoiceMemo {
  final int noteId;

  /// اسم الملف جوّه مجلّد `voice_memos` (مش مسار كامل — عشان يفضل صالح بعد
  /// الاستعادة على جهاز تانى).
  final String file;

  /// طول التسجيل بالثوانى.
  final int seconds;
  final String createdAt;

  const VoiceMemo({
    required this.noteId,
    required this.file,
    required this.seconds,
    required this.createdAt,
  });

  Map<String, Object?> toJson() =>
      {'n': noteId, 'f': file, 's': seconds, 'c': createdAt};

  factory VoiceMemo.fromJson(Map<String, dynamic> m) => VoiceMemo(
        noteId: (m['n'] as num?)?.toInt() ?? 0,
        file: m['f'] as String? ?? '',
        seconds: (m['s'] as num?)?.toInt() ?? 0,
        createdAt: m['c'] as String? ?? '',
      );

  /// صيغة العرض م:ث.
  String get durationLabel {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// المذكرات الصوتية للملاحظات — الملفات فى `<documents>/voice_memos` (نفس
/// مكان صور المستندات، فبتدخل النسخة الاحتياطية)، والبيانات JSON فى الإعدادات
/// (**بلا هجرة قاعدة بيانات**).
class VoiceMemosRepo {
  final _s = SettingsRepo();
  static const _key = 'note_voice_memos';
  static const dirName = 'voice_memos';

  /// مجلّد المذكرات (بيتعمل لو مش موجود). على الويب مفيش نظام ملفات.
  static Future<Directory> dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, dirName));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// المسار الكامل لملف مذكرة.
  static Future<String> pathOf(String file) async =>
      p.join((await dir()).path, file);

  Future<List<VoiceMemo>> all() async {
    final raw = await _s.get(_key) ?? '';
    if (raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => VoiceMemo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<Map<int, VoiceMemo>> byNote() async =>
      {for (final m in await all()) m.noteId: m};

  Future<VoiceMemo?> forNote(int noteId) async {
    for (final m in await all()) {
      if (m.noteId == noteId) return m;
    }
    return null;
  }

  Future<void> _save(List<VoiceMemo> list) async =>
      _s.set(_key, jsonEncode([for (final m in list) m.toJson()]));

  /// يربط تسجيلًا بملاحظة (وبيمسح تسجيلها القديم لو موجود).
  Future<void> setFor(VoiceMemo memo) async {
    await _deleteFile(await forNote(memo.noteId));
    final list = await all()..removeWhere((e) => e.noteId == memo.noteId);
    list.add(memo);
    await _save(list);
  }

  /// يشيل مذكرة ملاحظة (والملف بتاعها).
  Future<void> removeFor(int noteId) async {
    await _deleteFile(await forNote(noteId));
    final list = await all()..removeWhere((e) => e.noteId == noteId);
    await _save(list);
  }

  /// ينضّف مذكرات الملاحظات اللى اتمسحت + السجلات اللى ملفها ضاع.
  /// [noteIds] = أرقام الملاحظات الموجودة حاليًا.
  Future<void> prune(Set<int> noteIds) async {
    if (kIsWeb) return;
    final list = await all();
    final kept = <VoiceMemo>[];
    for (final m in list) {
      if (!noteIds.contains(m.noteId)) {
        await _deleteFile(m);
        continue;
      }
      // الملف ضاع (استعادة ناقصة مثلًا) → نشيل السجل عشان الواجهة ماتوعدش
      // بحاجة مش موجودة.
      if (!await File(await pathOf(m.file)).exists()) continue;
      kept.add(m);
    }
    if (kept.length != list.length) await _save(kept);
  }

  Future<void> _deleteFile(VoiceMemo? m) async {
    if (m == null || kIsWeb) return;
    try {
      final f = File(await pathOf(m.file));
      if (await f.exists()) await f.delete();
    } on FileSystemException catch (e) {
      logError('فشل حذف ملف المذكرة الصوتية «${m.file}»', e);
    } on MissingPluginException catch (e) {
      // منصّة من غير path_provider (تست/سطح مكتب) — البيانات بتتشال عادى
      // والملف مش موجود أصلاً هناك.
      logError('مافيش نظام ملفات لحذف «${m.file}»', e);
    }
  }
}
