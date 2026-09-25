import 'log.dart';
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
import 'adhan_custom.dart';
import 'ar.dart';
import 'db.dart';
import 'prayers.dart';

/// نسخة احتياطية = ملف zip واحد فيه قاعدة البيانات + صور المستندات.
class BackupService {
  static Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'doc_images'));
  }

  /// اسم مجلّد المذكرات الصوتية جوّه ملف النسخة (ونفسه على القرص).
  static const String memosEntryDir = 'voice_memos';

  static Future<Directory> _memosDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, memosEntryDir));
  }

  /// اسم مجلّد أصوات الأذان/المنبّه المخصّصة جوّه ملف النسخة.
  static const String soundsEntryDir = 'custom_sounds';

  /// الأصوات المخصّصة بتتخزّن فى **مجلّد دعم التطبيق** (اللى الـFileProvider
  /// بيقدّمه للنظام)، مش فى مجلّد المستندات — فكانت برّه النسخة الاحتياطية
  /// تمامًا: استعادة على موبايل جديد كانت بترجّع التذكير من غير صوته.
  static Future<Directory> _soundsDir() async =>
      getApplicationSupportDirectory();

  /// مجلّد الدعم فيه ملفات تانية (السجل مثلاً)، فبناخد **ملفات الصوت بس**
  /// — اللى اتنسخت بأسماء `adhan_custom_*` / `alarm_custom_*`.
  ///
  /// مهم: الاسم لازم يفضل زى ما هو عند الاستعادة، لإن الـ`content://` URI
  /// المخزّن مشتقّ من المسار — نفس الاسم = نفس الـURI = التذكير بيلاقى صوته.
  static bool isCustomSoundFile(String name) =>
      name.startsWith('adhan_custom_') || name.startsWith('alarm_custom_');

  /// بيضيف ملفات [dir] للأرشيف تحت [entryDir] (بشرط [where] لو اتبعت).
  static Future<void> _addDirFiles(Archive archive, Directory dir,
      String entryDir, {bool Function(String name)? where}) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (where != null && !where(name)) continue;
      archive.addFile(
          ArchiveFile.bytes('$entryDir/$name', await entity.readAsBytes()));
    }
  }

  /// بيحطّ الملفات المرفقة (صور · مذكرات صوتية · أصوات مخصّصة) فى الأرشيف.
  /// بتستخدمها النسخة اليدوية والتلقائية سوا عشان الاتنين يفضلوا متطابقين.
  static Future<void> addExtrasTo(Archive archive, Directory docs) async {
    await _addDirFiles(
        archive, Directory(p.join(docs.path, 'doc_images')), 'doc_images');
    await _addDirFiles(
        archive, Directory(p.join(docs.path, memosEntryDir)), memosEntryDir);
    await _addDirFiles(archive, await _soundsDir(), soundsEntryDir,
        where: isCustomSoundFile);
  }

  /// يبني ملف النسخة ويفتح شاشة المشاركة (Drive / واتساب / الملفات...).
  static Future<void> exportBackup() async {
    final dbPath = await AppDb.dbPath();
    // نقفل الاتصال مؤقتًا عشان نضمن إن الملف على القرص كامل ومتسق.
    await AppDb.close();
    final archive = Archive();
    archive.addFile(ArchiveFile.bytes(
        'my_assistant.db', await File(dbPath).readAsBytes()));
    await addExtrasTo(archive, await getApplicationDocumentsDirectory());
    final bytes = ZipEncoder().encode(archive);
    final temp = await getTemporaryDirectory();
    final out = File(p.join(
        temp.path, 'my_assistant_backup_${dayKey(DateTime.now())}.zip'));
    await out.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(out.path)],
        text: 'نسخة احتياطية من My Assistant');
    // نسجّل إن المستخدم طلّع نسخة برّه الجهاز — التذكير بيعتمد عليها.
    await SettingsRepo().set('last_manual_export', DateTime.now().toIso8601String());
  }

  static const String lastExportKey = 'last_manual_export';

  /// كام يوم عدّى على آخر نسخة **طلّعها المستخدم برّه الجهاز** (تصدير/مشاركة).
  ///
  /// النسخة التلقائية بتفضل على الجهاز نفسه، فلو الموبايل ضاع بتروح معاه —
  /// عشان كده التذكير بيتبع التصدير اليدوى مش التلقائى. بيرجّع null لو
  /// المستخدم عمرّه مطلّعش نسخة (يتعامل معاها كـ«محتاج نسخة»).
  static Future<int?> daysSinceExport({DateTime? now}) async {
    final raw = await SettingsRepo().get(lastExportKey) ?? '';
    if (raw.isEmpty) return null;
    final last = DateTime.tryParse(raw);
    if (last == null) return null;
    return (now ?? DateTime.now()).difference(last).inDays;
  }

  /// محتاج نبّه المستخدم يعمل نسخة؟ (عمرّه مطلّعش، أو بقاله [threshold] يوم).
  static Future<bool> needsBackupReminder(
      {int threshold = 14, DateTime? now}) async {
    final days = await daysSinceExport(now: now);
    return days == null || days >= threshold;
  }

  /// اسم ملف قاعدة البيانات جوه ملف النسخة.
  static const String dbEntryName = 'my_assistant.db';

  /// امتداد نسخة الأمان اللى بتتاخد من القاعدة الحاليّة قبل أى استعادة.
  static const String safetyCopySuffix = '.before_restore';

  /// بيتأكد إن البايتات دى فعلاً قاعدة SQLite (التوقيع فى أول الملف).
  /// ملف مقصوص أو تالف مش هيعدّى — وده اللى بيحمى من استعادة بتخرّب البيانات.
  static bool looksLikeSqlite(List<int> bytes) {
    const magic = 'SQLite format 3';
    // أصغر قاعدة SQLite = صفحة واحدة (٥١٢ بايت على الأقل)؛ أقل من كده = مقصوص.
    if (bytes.length < 512) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic.codeUnitAt(i)) return false;
    }
    return bytes[magic.length] == 0;
  }

  /// بيطبّق نسخة احتياطية من بايتات zip — **من غير ما يلمس القاعدة الحيّة
  /// إلا فى آخر خطوة**:
  ///   ١. بيفكّ الضغط ويتأكد إن جواه قاعدة SQLite سليمة،
  ///   ٢. بيكتبها فى ملف مؤقت جنبها،
  ///   ٣. بياخد نسخة أمان من الحاليّة (`.before_restore`)،
  ///   ٤. وبعدين بس بيبدّل (rename ذرّى) وبيحطّ الصور.
  /// أى فشل قبل الخطوة ٤ = بياناتك زى ما هى بالظبط.
  ///
  /// بيرمى [FormatException] برسالة عربية لو الملف مش نسخة صحيحة.
  /// مفصول عن [restoreBackup] عشان يبقى قابل للاختبار (من غير منتقى ملفات).
  /// [memosDirPath] مجلّد المذكرات الصوتية — اختيارى عشان النداءات القديمة
  /// تفضل شغّالة؛ لو اتبعت بيترجّع من النسخة زى الصور.
  /// [soundsDirPath] مجلّد دعم التطبيق (أصوات الأذان/المنبّه المخصّصة) —
  /// **بيتكتب فيه من غير ما يتمسح**، لإن فيه ملفات تانية للتطبيق.
  static Future<void> applyBackupBytes(
    List<int> zipBytes, {
    required String dbPath,
    required String imagesDirPath,
    String? memosDirPath,
    String? soundsDirPath,
  }) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } on Exception {
      throw const FormatException('الملف ده مش نسخة احتياطية صحيحة');
    }
    final dbEntry = archive.findFile(dbEntryName);
    if (dbEntry == null) {
      throw const FormatException('الملف ده مش نسخة احتياطية من My Assistant');
    }
    final newBytes = dbEntry.content as List<int>;
    if (!looksLikeSqlite(newBytes)) {
      throw const FormatException(
          'قاعدة البيانات جوه النسخة تالفة — مالمستش بياناتك الحالية');
    }

    // (٢) ملف مؤقت جنب القاعدة (نفس القرص عشان النقل يبقى ذرّى).
    final tmp = File('$dbPath.restore_tmp');
    await tmp.writeAsBytes(newBytes, flush: true);
    try {
      // (٣) نسخة أمان من الحاليّة — لو الاستعادة طلعت غلط يبقى فيه رجعة.
      final live = File(dbPath);
      if (await live.exists()) {
        await live.copy('$dbPath$safetyCopySuffix');
      }
      // (٤) التبديل.
      await tmp.rename(dbPath);
    } on Exception {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }

    // الصور — بعد ما القاعدة بقت سليمة.
    final imagesDir = Directory(imagesDirPath);
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
    await imagesDir.create(recursive: true);
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('doc_images/')) {
        final dest = File(p.join(imagesDir.path, p.basename(f.name)));
        await dest.writeAsBytes(f.content as List<int>);
      }
    }

    // المذكرات الصوتية — نفس المعالجة. النسخ القديمة مافيهاش المجلّد ده،
    // فالحلقة ببساطة مابتلاقيش حاجة.
    if (memosDirPath != null) {
      final memosDir = Directory(memosDirPath);
      if (await memosDir.exists()) {
        await memosDir.delete(recursive: true);
      }
      await memosDir.create(recursive: true);
      for (final f in archive.files) {
        if (f.isFile && f.name.startsWith('$memosEntryDir/')) {
          final dest = File(p.join(memosDir.path, p.basename(f.name)));
          await dest.writeAsBytes(f.content as List<int>);
        }
      }
    }

    // أصوات الأذان/المنبّه — **مش زى الصور**: المجلّد ده مجلّد دعم التطبيق
    // وفيه ملفات تانية (السجل مثلاً)، فبنكتب الملفات المستعادة جوّاه من غير
    // ما نمسح حاجة. والاسم بيفضل زى ما هو عشان الـcontent:// URI المخزّن
    // يفضل صالح.
    if (soundsDirPath != null) {
      final soundsDir = Directory(soundsDirPath);
      await soundsDir.create(recursive: true);
      for (final f in archive.files) {
        if (!f.isFile || !f.name.startsWith('$soundsEntryDir/')) continue;
        final name = p.basename(f.name);
        // حارس: نسخة متلاعب فيها ماتكتبش ملف برّه الأسماء المعروفة.
        if (!isCustomSoundFile(name)) continue;
        await File(p.join(soundsDir.path, name))
            .writeAsBytes(f.content as List<int>);
      }
    }
  }

  /// يرجع true لو الاستعادة تمت، false لو المستخدم لغى الاختيار.
  /// يرمي [FormatException] برسالة عربية لو الملف مش نسخة صحيحة.
  static Future<bool> restoreBackup() async {
    final picked = await FilePicker.pickFiles(withData: false);
    final path = picked?.files.single.path;
    if (path == null) return false;

    final dbPath = await AppDb.dbPath();
    final imagesDir = await _imagesDir();
    final memosDir = await _memosDir();
    final soundsDir = await _soundsDir();
    await AppDb.close();
    await applyBackupBytes(
      await File(path).readAsBytes(),
      dbPath: dbPath,
      imagesDirPath: imagesDir.path,
      memosDirPath: memosDir.path,
      soundsDirPath: soundsDir.path,
    );

    // الملفات رجعت بأسمائها فالـURI المخزّن صالح، لكن **إذن القراءة للنظام**
    // مش موجود على الجهاز الجديد — من غيره الإشعار بيرن بالصوت الافتراضى
    // بالصمت. بنعيد منحه لكل ملف مستعاد.
    await AdhanCustom.regrantAll();

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
      // نفس محتوى النسخة اليدوية بالظبط — كانت بتاخد الصور بس، فالمذكرات
      // الصوتية والأصوات المخصّصة كانوا بيضيعوا لو الاستعادة من نسخة تلقائية.
      await BackupService.addExtrasTo(archive, docs);
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
      logInfo('نسخة تلقائية اتعملت: ${out.path}');
    } on Exception catch (e, st) {
      logError('فشلت النسخة التلقائية', e, st);
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
      logError('فشل قراءة النسخ التلقائية', e);
      return null;
    }
  }
}
