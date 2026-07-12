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

  static bool _continuous = false;
  static int _lastAyah = 0;
  static bool _wired = false;

  static void _wire() {
    if (_wired) return;
    _wired = true;
    _player.onPlayerComplete.listen((_) {
      final cur = playing.value;
      if (cur == null) return;
      if (_continuous && cur.ayah < _lastAyah) {
        _playOne(cur.surah, cur.ayah + 1);
      } else {
        playing.value = null;
      }
    });
  }

  static String _url(int s, int a) =>
      'https://everyayah.com/data/$reciter/'
      '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  static Future<void> _playOne(int s, int a) async {
    playing.value = (surah: s, ayah: a);
    await _player.stop();
    await _player.play(UrlSource(_url(s, a)));
  }

  static Future<void> playAyah(int s, int a) async {
    _wire();
    _continuous = false;
    await _playOne(s, a);
  }

  static Future<void> playSurah(int s, int fromAyah, int lastAyah) async {
    _wire();
    _continuous = true;
    _lastAyah = lastAyah;
    await _playOne(s, fromAyah);
  }

  static Future<void> stop() async {
    _continuous = false;
    await _player.stop();
    playing.value = null;
  }
}
