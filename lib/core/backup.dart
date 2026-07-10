import 'dart:developer' as dev;
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../data/appointments_repo.dart';
import '../data/docs_repo.dart';
import '../data/meds_repo.dart';
import '../data/settings_repo.dart';
import 'ar.dart';
import 'db.dart';
import 'prayers.dart';

/// نسخة احتياطية = ملف zip واحد فيه قاعدة البيانات + صور المستندات.
class BackupService {
  static Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'doc_images'));
  }

  /// يبني ملف النسخة ويفتح شاشة المشاركة (Drive / واتساب / الملفات...).
  static Future<void> exportBackup() async {
    final dbPath = await AppDb.dbPath();
    // نقفل الاتصال مؤقتًا عشان نضمن إن الملف على القرص كامل ومتسق.
    await AppDb.close();
    final archive = Archive();
    archive.addFile(ArchiveFile.bytes(
        'my_assistant.db', await File(dbPath).readAsBytes()));
    final imagesDir = await _imagesDir();
    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          archive.addFile(ArchiveFile.bytes(
              'doc_images/${p.basename(entity.path)}',
              await entity.readAsBytes()));
        }
      }
    }
    final bytes = ZipEncoder().encode(archive);
    final temp = await getTemporaryDirectory();
    final out = File(p.join(
        temp.path, 'my_assistant_backup_${dayKey(DateTime.now())}.zip'));
    await out.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(out.path)],
        text: 'نسخة احتياطية من My Assistant');
  }

  /// يرجع true لو الاستعادة تمت، false لو المستخدم لغى الاختيار.
  /// يرمي [FormatException] برسالة عربية لو الملف مش نسخة صحيحة.
  static Future<bool> restoreBackup() async {
    final picked = await FilePicker.pickFiles(withData: false);
    final path = picked?.files.single.path;
    if (path == null) return false;

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await File(path).readAsBytes());
    } on Exception {
      throw const FormatException('الملف ده مش نسخة احتياطية صحيحة');
    }
    final dbEntry = archive.findFile('my_assistant.db');
    if (dbEntry == null) {
      throw const FormatException(
          'الملف ده مش نسخة احتياطية من My Assistant');
    }

    // استبدال قاعدة البيانات.
    final dbPath = await AppDb.dbPath();
    await AppDb.close();
    await File(dbPath).writeAsBytes(dbEntry.content, flush: true);

    // استبدال صور المستندات.
    final imagesDir = await _imagesDir();
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
    await imagesDir.create(recursive: true);
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('doc_images/')) {
        final dest = File(p.join(imagesDir.path, p.basename(f.name)));
        await dest.writeAsBytes(f.content);
      }
    }

    // مسارات الصور في النسخة جاية من جهاز/تثبيت مختلف — نعيد كتابتها.
    final db = await AppDb.instance;
    await _rewriteImagePaths(db, imagesDir.path);

    // كل التنبيهات المجدولة بقت قديمة — نعيد جدولتها من البيانات الجديدة.
    await AppointmentsRepo().rescheduleAll();
    await MedsRepo().rescheduleAll();
    await DocsRepo().rescheduleAll();
    await PrayerScheduler.ensureScheduled();
    return true;
  }

  static Future<void> _rewriteImagePaths(Database db, String newDir) async {
    final rows = await db.query('documents',
        columns: ['id', 'image_path'], where: "image_path != ''");
    for (final r in rows) {
      final newPath = rewrittenImagePath(r['image_path'] as String, newDir);
      await db.update('documents', {'image_path': newPath},
          where: 'id = ?', whereArgs: [r['id']]);
    }
  }
}

/// يحول مسار صورة قديم (من جهاز تاني) لمسار جوه مجلد الصور الحالي.
String rewrittenImagePath(String oldPath, String newDir) =>
    p.join(newDir, p.basename(oldPath));

/// نسخة احتياطية تلقائية أسبوعية — من غير أي تدخل، بيحتفظ بآخر ٤ نسخ.
/// بيستخدم VACUUM INTO عشان ياخد لقطة متسقة من غير ما يقفل الاتصال.
class AutoBackup {
  static const int keepCount = 4;
  static const int intervalDays = 7;

  static Future<void> ensure() async {
    try {
      final settings = SettingsRepo();
      final last = await settings.get('last_auto_backup') ?? '';
      final now = DateTime.now();
      if (last.isNotEmpty) {
        final lastDate = DateTime.tryParse(last);
        if (lastDate != null &&
            now.difference(lastDate).inDays < intervalDays) {
          return;
        }
      }
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'auto_backups'));
      await dir.create(recursive: true);

      final db = await AppDb.instance;
      final snapshotPath = p.join(dir.path, '_snapshot.db');
      final snapshot = File(snapshotPath);
      if (await snapshot.exists()) await snapshot.delete();
      await db.execute(
          "VACUUM INTO '${snapshotPath.replaceAll("'", "''")}'");

      final archive = Archive();
      archive.addFile(ArchiveFile.bytes(
          'my_assistant.db', await snapshot.readAsBytes()));
      final imagesDir = Directory(p.join(docs.path, 'doc_images'));
      if (await imagesDir.exists()) {
        await for (final entity in imagesDir.list()) {
          if (entity is File) {
            archive.addFile(ArchiveFile.bytes(
                'doc_images/${p.basename(entity.path)}',
                await entity.readAsBytes()));
          }
        }
      }
      final out = File(p.join(dir.path, 'auto_${dayKey(now)}.zip'));
      await out.writeAsBytes(ZipEncoder().encode(archive));
      await snapshot.delete();

      final zips = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      while (zips.length > keepCount) {
        await zips.removeAt(0).delete();
      }
      await settings.set('last_auto_backup', now.toIso8601String());
      dev.log('نسخة تلقائية اتعملت: ${out.path}');
    } on Exception catch (e, st) {
      dev.log('فشلت النسخة التلقائية', error: e, stackTrace: st);
    }
  }

  /// أحدث نسخة تلقائية — للمشاركة من الإعدادات.
  static Future<File?> latest() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'auto_backups'));
      if (!await dir.exists()) return null;
      final zips = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      return zips.isEmpty ? null : zips.first;
    } on Exception catch (e) {
      dev.log('فشل قراءة النسخ التلقائية', error: e);
      return null;
    }
  }
}
