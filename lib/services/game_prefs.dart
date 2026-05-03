import 'package:shared_preferences/shared_preferences.dart';
class GamePrefs {
  static final GamePrefs _i = GamePrefs._();
  factory GamePrefs() => _i;
  GamePrefs._();

  static const _kHints       = 'hints_count';
  static const _kHintsDate   = 'hints_date';   // дата последнего сброса
  static const _kLevels      = 'levels_won';

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async => _prefs ??= await SharedPreferences.getInstance();

  Future<int> get hintsLeft async {
    final p = await _p;
    await _resetHintsIfNewDay(p);
    return p.getInt(_kHints) ?? 3;
  }

  Future<bool> useHint() async {
    final p = await _p;
    await _resetHintsIfNewDay(p);
    final current = p.getInt(_kHints) ?? 3;
    if (current <= 0) return false;
    await p.setInt(_kHints, current - 1);
    return true;
  }
  Future<void> addHint({int count = 1}) async {
    final p = await _p;
    final current = p.getInt(_kHints) ?? 3;
    await p.setInt(_kHints, current + count);
  }

  Future<void> _resetHintsIfNewDay(SharedPreferences p) async {
    final today = _dateKey(DateTime.now());
    final lastDate = p.getString(_kHintsDate) ?? '';
    if (lastDate != today) {
      await p.setInt(_kHints, 3);      
      await p.setString(_kHintsDate, today);
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<int> get levelsWon async {
    final p = await _p;
    return p.getInt(_kLevels) ?? 0;
  }

  Future<void> onLevelComplete() async {
    final p = await _p;
    final n = (p.getInt(_kLevels) ?? 0) + 1;
    await p.setInt(_kLevels, n);
    await addHint(); 
  }

  static int calcScore({
    required int pairsRemoved,
    required int secondsElapsed,
    required int wrongTaps,
  }) {
    int score = pairsRemoved * 10;
    score -= (secondsElapsed ~/ 30);
    score -= wrongTaps * 5;
    if (secondsElapsed < 60)       score += 50;
    else if (secondsElapsed < 120) score += 20;
    return score.clamp(0, 99999);
  }
}