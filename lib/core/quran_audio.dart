import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// قارئ للتلاوة (مجلد على everyayah).
class Reciter {
  final String id;
  final String name;
  const Reciter(this.id, this.name);
}

/// قرّاء معتمدون — التلاوة بث مباشر من everyayah.com (مش تخزين).
const List<Reciter> kReciters = [
  Reciter('Alafasy_128kbps', 'مشاري العفاسي'),
  Reciter('Husary_128kbps', 'محمود الحصري'),
  Reciter('Minshawy_Murattal_128kbps', 'محمد المنشاوي'),
  Reciter('Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد'),
  Reciter('Abdurrahmaan_As-Sudais_192kbps', 'عبد الرحمن السديس'),
];

String reciterName(String id) =>
    kReciters.firstWhere((r) => r.id == id, orElse: () => kReciters.first).name;

/// تشغيل تلاوة القرآن آية-آية مع إمكانية التتابع.
class QuranAudio {
  QuranAudio._();

  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<({int surah, int ayah})?> playing =
      ValueNotifier(null);
  static String reciter = 'Alafasy_128kbps';

  static List<List<int>> _queue = const []; // [[سورة، آية], …]
  static int _idx = 0;
  static bool _wired = false;

  static void _wire() {
    if (_wired) return;
    _wired = true;
    _player.onPlayerComplete.listen((_) {
      if (_idx + 1 < _queue.length) {
        _playAt(_idx + 1);
      } else {
        playing.value = null;
      }
    });
  }

  static String _url(int s, int a) =>
      'https://everyayah.com/data/$reciter/'
      '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  static Future<void> _playAt(int i) async {
    if (i < 0 || i >= _queue.length) {
      playing.value = null;
      return;
    }
    _idx = i;
    final s = _queue[i][0], a = _queue[i][1];
    playing.value = (surah: s, ayah: a);
    await _player.stop();
    await _player.play(UrlSource(_url(s, a)));
  }

  /// يشغّل آية واحدة.
  static Future<void> playAyah(int s, int a) async {
    _wire();
    _queue = [[s, a]];
    await _playAt(0);
  }

  /// يشغّل قائمة آيات بالتتابع (مثلاً آيات صفحة كاملة).
  static Future<void> playList(List<List<int>> refs) async {
    if (refs.isEmpty) return;
    _wire();
    _queue = refs;
    await _playAt(0);
  }

  static Future<void> stop() async {
    _queue = const [];
    await _player.stop();
    playing.value = null;
  }
}
