import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicService {
  static final MusicService _i = MusicService._();
  factory MusicService() => _i;
  MusicService._();

  final _player = AudioPlayer();
  bool _musicOn = true;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _musicOn = p.getBool('music_on') ?? true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5);
    if (_musicOn) play();
  }

  Future<void> play() async {
    try {
      await _player.play(AssetSource('music/background.mp3'));
    } catch (_) {}
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.resume();

  bool get isOn => _musicOn;

  Future<void> toggle() async {
    _musicOn = !_musicOn;
    final p = await SharedPreferences.getInstance();
    await p.setBool('music_on', _musicOn);
    if (_musicOn) play(); else pause();
  }

  Future<void> setOn(bool on) async {
    _musicOn = on;
    final p = await SharedPreferences.getInstance();
    await p.setBool('music_on', on);
    if (on) play(); else pause();
  }
}