import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns all game audio and keeps sound effects independent from one another.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _musicPlayer = AudioPlayer();
  final Set<AudioPlayer> _activeSfxPlayers = <AudioPlayer>{};
  final Set<String> _pauseReasons = <String>{};

  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;
  bool _initialized = false;
  bool _initializing = false;
  Future<void>? _initialization;
  bool _disposed = false;

  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() {
    if (_initialized) return Future<void>.value();
    if (_initializing) return _initialization!;
    _initializing = true;
    _initialization = _initialize();
    return _initialization!;
  }

  Future<void> _initialize() async {
    try {
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
            options: const <AVAudioSessionOptions>{
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      _musicVolume = (prefs.getDouble('music_volume') ?? 0.8).clamp(0.0, 1.0);
      _sfxVolume = (prefs.getDouble('sfx_volume') ?? 0.8).clamp(0.0, 1.0);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(AssetSource('audio/bgm.mp3'));
      if (_musicVolume == 0 || _pauseReasons.isNotEmpty) {
        await _musicPlayer.pause();
      }
      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Audio initialization failed: $error\n$stackTrace');
    } finally {
      _initializing = false;
    }
  }

  Future<void> playBgm(String fileName) async {
    if (_disposed) return;
    await _musicPlayer.stop();
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_musicVolume);
    await _musicPlayer.play(AssetSource('audio/$fileName'));
    if (_musicVolume == 0 || _pauseReasons.isNotEmpty) await _musicPlayer.pause();
    _initialized = true;
  }

  Future<void> pauseBgm({String reason = 'general'}) async {
    _pauseReasons.add(reason);
    if (_initialized && !_disposed) await _musicPlayer.pause();
  }

  Future<void> resumeBgm({String reason = 'general'}) async {
    _pauseReasons.remove(reason);
    if (_initialized && !_disposed && _pauseReasons.isEmpty && _musicVolume > 0) {
      await _musicPlayer.resume();
    }
  }

  Future<void> playSfx(String fileName) async {
    if (_disposed || _sfxVolume <= 0) return;
    final player = AudioPlayer();
    _activeSfxPlayers.add(player);
    StreamSubscription<void>? completion;

    Future<void> cleanUp() async {
      await completion?.cancel();
      _activeSfxPlayers.remove(player);
      await player.dispose();
    }

    try {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(_sfxVolume);
      completion = player.onPlayerComplete.listen((_) => unawaited(cleanUp()));
      await player.play(AssetSource('audio/$fileName'));
    } catch (error) {
      debugPrint('SFX playback failed for $fileName: $error');
      await cleanUp();
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_disposed) return;
    await _musicPlayer.setVolume(_musicVolume);
    if (_musicVolume == 0) {
      await _musicPlayer.pause();
    } else if (_initialized && _pauseReasons.isEmpty) {
      await _musicPlayer.resume();
    }
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final players = List<AudioPlayer>.of(_activeSfxPlayers);
    _activeSfxPlayers.clear();
    await Future.wait(players.map((player) => player.dispose()));
    await _musicPlayer.dispose();
  }
}
