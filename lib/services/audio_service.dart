// lib/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  // Background music player
  final AudioPlayer _musicPlayer = AudioPlayer();

  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;

  bool _isBgmInitialized = false;

  Future<void> init() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          // Kategori kuralına uymak için playback yapıyoruz
          category: AVAudioSessionCategory.playback,
          options: {
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

  // ------------------------------------------------------------
  // BACKGROUND MUSIC
  // ------------------------------------------------------------

  Future<void> playBgm(String fileName) async {
    await _musicPlayer.play(
      AssetSource('audio/$fileName'),
    );
  }

  // ------------------------------------------------------------
  // SOUND EFFECTS
  // ------------------------------------------------------------

  Future<void> playSfx(String fileName) async {
    if (_sfxVolume <= 0) {
      return;
    }

    /*
     * Her SFX için tamamen bağımsız bir AudioPlayer oluşturuyoruz.
     *
     * Bunun sayesinde:
     *
     * click.mp3
     * click.mp3
     * click.mp3
     *
     * aynı anda çalabilir.
     *
     * Ayrıca:
     *
     * click.mp3
     * cash.mp3
     * click.mp3
     *
     * şeklinde arka arkaya gelirse hiçbirisi diğerini kesmez.
     */

    final player = AudioPlayer();

    try {
      await player.setReleaseMode(
        ReleaseMode.stop,
      );

      await player.setVolume(
        _sfxVolume,
      );

      // Ses bittiğinde player'ı temizle.
      player.onPlayerComplete.listen((_) async {
        await player.dispose();
      });

      await player.play(
        AssetSource('audio/$fileName'),
      );
    } catch (e) {
      // Oynatma sırasında hata olursa player'ı temizle.
      await player.dispose();
    }
  }

  // ------------------------------------------------------------
  // VOLUME
  // ------------------------------------------------------------

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