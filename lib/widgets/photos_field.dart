// صور مرفقة بأى بند — اختيار من الكاميرا أو الاستوديو، عرض، وحذف.
//
// الكود ده كان **متكرّر خمس مرات** (الملف الطبى · المستندات · التقدّم
// البدنى · صيدلية البيت · الوصفات): نفس ورقة «كاميرا/استوديو»، نفس
// المربّعات ٨٠×٨٠، ونفس زرار الحذف. اتجمّع هنا عشان البند الجديد
// (صور التحاليل) مايكونش السادس — ولإن أى تحسين (زى العرض بالتكبير)
// يبقى لكلهم مرة واحدة بدل خمسة.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_images.dart';
import '../core/l10n.dart';

/// صفحة عرض صورة واحدة بالتكبير (قرصة أو دوسة مزدوجة).
class PhotoViewScreen extends StatelessWidget {
  final List<String> photos;
  final int index;
  const PhotoViewScreen({super.key, required this.photos, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: photos.length < 2
            ? null
            : Text(tr('${index + 1} من ${photos.length}',
                '${index + 1} of ${photos.length}')),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: index),
        itemCount: photos.length,
        itemBuilder: (_, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: AppImage(photos[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

/// صفّ صور: المضاف + زرار «➕».
///
/// الودجت دى **مابتحفظش** — بتدّى اللستة المتغيّرة لصاحب الشاشة عن طريق
/// [onChanged]، فالحفظ يفضل فى مكان واحد مع باقى حقول الفورم.
class PhotosField extends StatelessWidget {
  final List<String> photos;
  final ValueChanged<List<String>> onChanged;

  /// بادئة اسم الملف المحفوظ — بتفرّق صور كل بند عن التانى على القرص.
  final String namePrefix;

  /// عنوان فوق الصور (اختيارى).
  final String? label;

  /// مقاس المربّع.
  final double size;

  const PhotosField({
    super.key,
    required this.photos,
    required this.onChanged,
    this.namePrefix = 'img',
    this.label,
    this.size = 80,
  });

  Future<void> _addFromCamera(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.camera, maxWidth: 2200, imageQuality: 85);
    if (picked == null) return;
    final dest = await AppImages.storeXFile(picked, namePrefix: namePrefix);
    if (dest != null) onChanged([...photos, dest]);
  }

  Future<void> _addFromGallery(BuildContext context) async {
    final picked =
        await ImagePicker().pickMultiImage(maxWidth: 2200, imageQuality: 85);
    final added = <String>[];
    for (final x in picked) {
      final dest = await AppImages.storeXFile(x, namePrefix: namePrefix);
      if (dest != null) added.add(dest);
    }
    if (added.isNotEmpty) onChanged([...photos, ...added]);
  }

  Future<void> _sourceSheet(BuildContext context) async {
    final from = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(tr('صوّر دلوقتى', 'Take a photo')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(tr('من الاستوديو', 'From gallery')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || from == null) return;
    if (from == 'camera') {
      await _addFromCamera(context);
    } else {
      await _addFromGallery(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < photos.length; i++) _thumb(context, i),
            InkWell(
              onTap: () => _sourceSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(Icons.add_a_photo_outlined, color: scheme.outline),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _thumb(BuildContext context, int i) => Stack(
        children: [
          InkWell(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) =>
                        PhotoViewScreen(photos: photos, index: i))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppImage(photos[i],
                  width: size, height: size, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: IconButton(
              tooltip: tr('شيل الصورة', 'Remove'),
              icon: const Icon(Icons.cancel, size: 20),
              color: Colors.black54,
              onPressed: () =>
                  onChanged([...photos]..removeAt(i)),
            ),
          ),
        ],
      );
}
