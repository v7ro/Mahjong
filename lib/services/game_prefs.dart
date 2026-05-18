import 'package:shared_preferences/shared_preferences.dart';

class GamePrefs {
  static final GamePrefs _i = GamePrefs._();
  factory GamePrefs() => _i;
  GamePrefs._();

  static const _kHints = 'hints_count';
  static const _kDate  = 'hints_date';

  SharedPreferences? _p;
  Future<SharedPreferences> get _prefs async =>
    _p ??= await SharedPreferences.getInstance();

  Future<int> get hintsLeft async {
    final p = await _prefs;
    await _resetIfNewDay(p);
    return p.getInt(_kHints) ?? 3;
  }

  Future<bool> useHint() async {
    final p = await _prefs;
    await _resetIfNewDay(p);
    final n = p.getInt(_kHints) ?? 3;
    if (n <= 0) return false;
    await p.setInt(_kHints, n-1);
    return true;
  }

  Future<void> addHint({int count=1}) async {
    final p = await _prefs;
    await p.setInt(_kHints, (p.getInt(_kHints)??3)+count);
  }

  Future<void> _resetIfNewDay(SharedPreferences p) async {
    final today = _day(DateTime.now());
    if (p.getString(_kDate) != today) {
      await p.setInt(_kHints, 3);
      await p.setString(_kDate, today);
    }
  }

  String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> onLevelComplete() => addHint();

  static int calcScore({
    required int pairsRemoved,
    required int secondsElapsed,
    required int wrongTaps,
  }) {
    int s = pairsRemoved * 10 - secondsElapsed ~/ 30 - wrongTaps * 5;
    if (secondsElapsed < 60) s += 50;
    else if (secondsElapsed < 120) s += 20;
    return s.clamp(0, 99999);
  }
}
