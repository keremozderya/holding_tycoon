// lib/services/audio_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _musicPlayer = AudioPlayer();

  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;

  bool _isBgmInitialized = false;

  Future<void> init() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );

    final prefs = await SharedPreferences.getInstance();

    _musicVolume = prefs.getDouble('music_volume') ?? 0.8;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;

    await _musicPlayer.setVolume(_musicVolume);

    await _musicPlayer.setReleaseMode(
      ReleaseMode.loop,
    );

    if (!_isBgmInitialized) {
      await playBgm('bgm.mp3');
      _isBgmInitialized = true;
    }
  }

  Future<void> playBgm(String fileName) async {
    await _musicPlayer.play(
      AssetSource('audio/$fileName'),
    );
  }

  // YENİ EKLENEN: Müziği duraklatma fonksiyonu
  Future<void> pauseBgm() async {
    if (_isBgmInitialized) {
      await _musicPlayer.pause();
    }
  }

  // YENİ EKLENEN: Müziği devam ettirme fonksiyonu
  Future<void> resumeBgm() async {
    if (_isBgmInitialized && _musicVolume > 0) {
      await _musicPlayer.resume();
    }
  }

  Future<void> playSfx(String fileName) async {
    if (_sfxVolume <= 0) {
      return;
    }

    final player = AudioPlayer();

    try {
      await player.setReleaseMode(
        ReleaseMode.stop,
      );

      await player.setVolume(
        _sfxVolume,
      );

      player.onPlayerComplete.listen((_) async {
        await player.dispose();
      });

      await player.play(
        AssetSource('audio/$fileName'),
      );
    } catch (e) {
      await player.dispose();
    }
  }

  void setMusicVolume(double volume) {
    _musicVolume = volume;
    _musicPlayer.setVolume(
      volume,
    );
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume;
  }
}