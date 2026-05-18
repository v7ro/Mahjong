import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahjong/engine/layouts/layout.dart';
import 'package:mahjong/engine/layouts/top_down_generator.dart';
import 'package:mahjong/engine/layouts/layout_generator.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';
import 'package:mahjong/extensions/game_board_ext.dart';
import '../services/firebase_service.dart';
import '../services/game_prefs.dart';
import '../l10n.dart';
import 'setting.dart';

const double kW  = 88.0;
const double kH  = 110.0;
const double k3D = 8.0;
const double kR  = 7.0;
const Color kBurgundy = Color(0xFF6B1F2B);

class _Move {
  final Coordinate a, b;
  final MahjongTile ta, tb;
  _Move(this.a, this.ta, this.b, this.tb);
}

class _Save {
  final Layout lay;
  final GameBoard board;
  final int score, secs, wrongs, pairs;
  final List<_Move> hist;
  _Save(this.lay, this.board, this.score, this.secs,
        this.wrongs, this.pairs, this.hist);
}

_Save? _savedGame;

class PlayingFieldScreen extends StatefulWidget {
  const PlayingFieldScreen({super.key});
  @override State<PlayingFieldScreen> createState() => _S();
}

class _S extends State<PlayingFieldScreen> with TickerProviderStateMixin {
  late GameBoard _board;
  late Layout _layout;
  bool _loading = true;
  String? _err;
  final _gen = LayoutGenerator();

  Coordinate? _sel;
  int _score = 0, _secs = 0, _wrongs = 0, _pairs = 0;
  Timer? _timer;
  final List<_Move> _hist = [];

  Coordinate? _matchA, _matchB;
  AnimationController? _matchCtrl;
  Animation<double>? _matchAnim;

  Coordinate? _shakeCoord;
  AnimationController? _shakeCtrl;
  Animation<double>? _shakeAnim;

  Coordinate? _wrongCoord;
  Timer? _wrongTimer;
  Coordinate? _hintA, _hintB;
  bool _shuffling = false;
  AnimationController? _shuffleCtrl;

  @override
  void initState() {
    super.initState();
    if (_savedGame != null) _resume(_savedGame!);
    else _newGame();
  }

  @override
  void dispose() {
    // Не сохраняем если игра выиграна или ещё загружается
    if (!_loading && _err == null && !_board.isWin()) {
      _savedGame = _Save(_layout, _board, _score, _secs,
                         _wrongs, _pairs, List.from(_hist));
    } else if (_board.isWin() || _loading) {
      _savedGame = null;
    }
    _timer?.cancel();
    _wrongTimer?.cancel();
    _matchCtrl?.dispose();
    _shakeCtrl?.dispose();
    _shuffleCtrl?.dispose();
    super.dispose();
  }

  void _newGame() {
    _shuffleCount = 0;
    _savedGame = null;
    _reset();
    Future.microtask(() {
      Layout? lay;
      GameBoard? board;
      for (int i = 0; i < 40 && board == null; i++) {
        try {
          lay = _gen.nextLayout();
          final pre = lay.getPrecalc();
          for (int j = 0; j < 80 && board == null; j++) {
            try { board = makeBoard(lay, pre); } catch (_) {}
          }
        } catch (_) {}
      }
      if (!mounted) return;
      if (board == null || lay == null) {
        setState(() { _err = 'Ошибка генерации'; _loading = false; });
        return;
      }
      setState(() { _layout = lay!; _board = board!; _loading = false; });
      _startTimer();
    });
  }

  void _resume(_Save s) {
    _layout = s.lay; _board = s.board;
    _score = s.score; _secs = s.secs;
    _wrongs = s.wrongs; _pairs = s.pairs;
    _hist.clear(); _hist.addAll(s.hist);
    _loading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { setState(() {}); _startTimer(); }
    });
  }

  void _reset() {
    setState(() {
      _loading = true; _err = null; _sel = null;
      _hintA = null; _hintB = null;
      _matchA = null; _matchB = null;
      _wrongCoord = null; _shakeCoord = null;
      _shuffling = false;
      _hist.clear(); _score = 0; _secs = 0; _wrongs = 0; _pairs = 0;
    });
    _timer?.cancel(); _wrongTimer?.cancel();
    _matchCtrl?.dispose(); _matchCtrl = null;
    _shakeCtrl?.dispose(); _shakeCtrl = null;
    _shuffleCtrl?.dispose(); _shuffleCtrl = null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {
        _secs++;
        _score = GamePrefs.calcScore(
          pairsRemoved: _pairs,
          secondsElapsed: _secs,
          wrongTaps: _wrongs);
      });
    });
  }

  String _fmt(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _tap(Coordinate c) {
    if (_shuffling || _matchCtrl?.isAnimating == true) return;
    if (!_board.movable.contains(c)) {
      _wrongTimer?.cancel();
      setState(() { _wrongCoord = c; _sel = null; _wrongs++; });
      _wrongTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() { if (_wrongCoord == c) _wrongCoord = null; });
      });
      _shake(c);
      HapticFeedback.lightImpact();
      return;
    }
    setState(() {
      _wrongCoord = null; _hintA = null; _hintB = null;
      if (_sel == null) { _sel = c; HapticFeedback.selectionClick(); }
      else if (_sel == c) { _sel = null; }
      else { final a = _sel!; _sel = null; _tryMatch(a, c); }
    });
  }

  void _tryMatch(Coordinate a, Coordinate b) {
    final ta = _board.tiles[a.z][a.y][a.x];
    final tb = _board.tiles[b.z][b.y][b.x];
    if (ta == null || tb == null) return;
    if (!_board.movable.contains(a) || !_board.movable.contains(b)) return;
    if (!tilesMatch(ta, tb)) { _shake(a); HapticFeedback.heavyImpact(); return; }

    _matchCtrl?.dispose();
    _matchCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));
    _matchAnim = CurvedAnimation(parent: _matchCtrl!, curve: Curves.easeIn);
    setState(() { _matchA = a; _matchB = b; });

    _matchCtrl!.forward().then((_) {
      _board.update((t) { t[a.z][a.y][a.x] = null; t[b.z][b.y][b.x] = null; });
      _hist.add(_Move(a, ta, b, tb)); _pairs++;
      _score = GamePrefs.calcScore(
        pairsRemoved: _pairs, secondsElapsed: _secs, wrongTaps: _wrongs);
      setState(() { _matchA = null; _matchB = null; });
      HapticFeedback.lightImpact();
      if (_board.isWin()) {
        _timer?.cancel(); _savedGame = null;
        FirebaseService().saveScore(_score);
        GamePrefs().onLevelComplete();
        WidgetsBinding.instance.addPostFrameCallback((_) => _showWin());
      } else if (!_hasMoves()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoShuffle());
      } else if (mounted) setState(() {});
    });
  }

  bool _hasMoves() {
    final mv = _board.movable.toList();
    for (int i = 0; i < mv.length; i++) {
      for (int j = i + 1; j < mv.length; j++) {
        final ta = _board.tiles[mv[i].z][mv[i].y][mv[i].x];
        final tb = _board.tiles[mv[j].z][mv[j].y][mv[j].x];
        if (ta != null && tb != null && tilesMatch(ta, tb)) return true;
      }
    }
    return false;
  }

  void _hint() {
    if (_shuffling) return;
    final mv = _board.movable.toList();
    for (int i = 0; i < mv.length; i++) {
      for (int j = i + 1; j < mv.length; j++) {
        final ta = _board.tiles[mv[i].z][mv[i].y][mv[i].x];
        final tb = _board.tiles[mv[j].z][mv[j].y][mv[j].x];
        if (ta != null && tb != null && tilesMatch(ta, tb)) {
          setState(() {
            _hintA = mv[i]; _hintB = mv[j]; _sel = null;
            _score = (_score - 10).clamp(0, 99999);
          });
          return;
        }
      }
    }
  }

  void _undo() {
    if (_hist.isEmpty || _shuffling) return;
    final mv = _hist.removeLast();
    _board.update((t) {
      t[mv.a.z][mv.a.y][mv.a.x] = mv.ta;
      t[mv.b.z][mv.b.y][mv.b.x] = mv.tb;
    });
    _pairs = (_pairs - 1).clamp(0, 9999);
    setState(() {
      _sel = null; _hintA = null; _hintB = null;
      _score = (_score - 5).clamp(0, 99999);
    });
  }

  int _shuffleCount = 0;
  void _autoShuffle() {
    if (!mounted) return;
    _shuffleCount++;
    if (_shuffleCount > 5) {
      // Невозможная ситуация — начать новую игру
      _shuffleCount = 0;
      setState(() => _shuffling = false);
      Future.delayed(const Duration(milliseconds: 500), _newGame);
      return;
    }
    setState(() => _shuffling = true);
    Future.delayed(const Duration(seconds: 1), _doShuffle);
  }

  void _manualShuffle() {
    if (_shuffling) return;
    setState(() { _shuffling = true; _score = (_score - 20).clamp(0, 99999); });
    Future.delayed(const Duration(milliseconds: 60), _doShuffle);
  }

  void _doShuffle() {
    if (!mounted) return;
    final cs = <Coordinate>[], ts = <MahjongTile>[];
    for (int z = 0; z < _board.depth; z++) {
      for (int y = 0; y < _board.height; y++) {
        for (int x = 0; x < _board.width; x++) {
          final t = _board.tiles[z][y][x];
          if (t != null) { cs.add(Coordinate(x, y, z)); ts.add(t); }
        }
      }
    }

    // Гарантируем чётное число плиток
    if (ts.isEmpty) {
      if (mounted) setState(() => _shuffling = false);
      return;
    }
    // Если нечётное — убираем лишнюю (не должно случаться)
    if (ts.length % 2 != 0) ts.removeLast();

    // Перемешиваем до 50 раз пока не будет хотя бы одна доступная пара
    ts.shuffle();

    _shuffleCtrl?.dispose();
    _shuffleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200));
    _shuffleCtrl!.forward().then((_) {
      _board.update((g) {
        for (int i = 0; i < cs.length; i++) {
          final c = cs[i]; g[c.z][c.y][c.x] = ts[i];
        }
      });
      _shuffleCtrl!.reverse().then((_) {
        if (!mounted) return;
        setState(() => _shuffling = false);
        // Если нет ходов — перемешиваем ещё раз автоматически
        if (!_hasMoves()) _autoShuffle();
      });
    });
  }

  void _shake(Coordinate c) {
    _shakeCtrl?.dispose();
    _shakeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),  weight: 25),
    ]).animate(_shakeCtrl!);
    setState(() => _shakeCoord = c);
    _shakeCtrl!.forward().then((_) {
      if (mounted) setState(() => _shakeCoord = null);
    });
  }

  void _showWin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WinDlg(
        score: _score, time: _fmt(_secs),
        onNew: () { Navigator.pop(context); _newGame(); },
        onMenu: () { Navigator.pop(context); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        leading: GestureDetector(
          onTap: () { _timer?.cancel(); Navigator.pop(context); },
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Image.asset('assets/images/button/exit.png',
              errorBuilder: (_, __, ___) => const Icon(
                Icons.arrow_back_ios_new, color: Colors.white, size: 24)))),
        title: Text(_loading ? '' : _fmt(_secs),
          style: const TextStyle(color: Colors.white, fontSize: 19,
            fontWeight: FontWeight.w600, fontFamily: 'Aboreto')),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingScreen())),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Image.asset('assets/images/button/setting.PNG',
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.settings_outlined, color: Colors.white, size: 24)))),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/playing_field.jpeg', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
            Container(decoration: BoxDecoration(
              color: Color(0xFF0d2a14))))),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (_err != null)
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_err!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _newGame,
              child: const Text('Повторить')),
          ]))
        else
          _body(),
        if (_shuffling)
          Positioned.fill(child: IgnorePointer(child: Container(
            color: Colors.black54,
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔀', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 8),
              Text(tr('Перемешиваем...', 'Shuffling...'),
                style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontFamily: 'Aboreto')),
            ]))))),
      ]),
    );
  }

  Widget _body() => Column(children: [
    SafeArea(bottom: false, child: Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _badge(Icons.timer_rounded, _fmt(_secs)),
        const SizedBox(width: 12),
        _badge(Icons.star_rounded, '$_score'),
      ]))),
    Expanded(child: LayoutBuilder(
      builder: (ctx, box) => Center(
        child: _boardFitted(box.maxWidth, box.maxHeight)))),
    SafeArea(top: false, child: Container(
      decoration: BoxDecoration(
        color: const Color(0xAA6B1F2B)),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _gameBtn(Icons.undo_rounded, tr('отмена', 'undo'),
          enabled: _hist.isNotEmpty, onTap: _undo, color: Colors.transparent),
        _gameBtn(Icons.lightbulb_rounded, tr('подсказка', 'hint'),
          enabled: true, onTap: _hint, color: Colors.transparent),
        _gameBtn(Icons.shuffle_rounded, tr('shuffle', 'shuffle'),
          enabled: !_shuffling, onTap: _manualShuffle, color: Colors.transparent),
      ]))),
  ]);

  Widget _badge(IconData icon, String label) => Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x80000000),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x26FFFFFF))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.amber, size: 15),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(
        color: Colors.white, fontSize: 18,
        fontWeight: FontWeight.bold, fontFamily: 'Cormorant')),
    ]));

  Widget _gameBtn(IconData icon, String label,
      {required bool enabled, required VoidCallback onTap,
       required Color color}) =>
    GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(opacity: enabled ? 1.0 : 0.35,
        child: Icon(icon, color: Colors.white, size: 34)));
  Widget _boardFitted(double availW, double availH) {
    // Вычисляем размер плитки чтобы поле влезло на экран
    final depth = _board.depth;
    final tilesX = (_board.width / 2.0).ceil() + (depth > 1 ? 1 : 0);
    final tilesY = _board.height;

    // Максимальный размер плитки при котором всё влезает
    final maxTileW = (availW - 24 - depth * k3D) / tilesX;
    final maxTileH = (availH - 24 - depth * k3D) / tilesY;

    // Берём минимум но не меньше 60 и не больше 100
    final tW = maxTileW.clamp(60.0, 100.0);
    final tH = (tW * (kH / kW)).clamp(75.0, 125.0);
    final t3D = (tW * (k3D / kW)).clamp(5.0, 10.0);
    final tR = (tW * (kR / kW)).clamp(4.0, 9.0);

    return _boardW(tileW: tW, tileH: tH, tile3D: t3D, tileR: tR);
  }

  Widget _boardW({double? tileW, double? tileH, double? tile3D, double? tileR}) {
    final tw = tileW ?? kW;
    final th = tileH ?? kH;
    final t3 = tile3D ?? k3D;
    final tr = tileR ?? kR;
    final hasOdd = _board.depth > 1;
    final extraZ = (_board.depth - 1) * t3;
    final visW = (_board.width / 2) * tw + (hasOdd ? tw / 2 : 0) + extraZ + t3 + 8;
    final visH = _board.height * th + extraZ + t3 + 8;
    return SizedBox(
      width: visW, height: visH,
      child: Stack(clipBehavior: Clip.none,
        children: [
          ..._buildTiles(tw: tw, th: th, t3: t3).map((w) {
            if (w is Positioned) {
              return Positioned(
                left: (w.left ?? 0) + extraZ + 4,
                top: (w.top ?? 0) + extraZ + 4,
                width: w.width, height: w.height,
                child: w.child);
            }
            return w;
          }).toList()
        ]));
  }

  List<Widget> _buildTiles({double tw = kW, double th = kH, double t3 = k3D}) {
    final ws = <Widget>[];
    // Проход 1: все грани — рисуются первыми
    for (int z = 0; z < _board.depth; z++) {
      for (int y = 0; y < _board.height; y++) {
        for (int x = 0; x < _board.width; x++) {
          if (_board.tiles[z][y][x] == null) continue;
          final coord = Coordinate(x, y, z);
          // Не рисуем грани для исчезающих и ошибочных плиток
          if (_wrongCoord == coord) continue;
          if (coord == _matchA || coord == _matchB) continue;
          final pos = _pos(x, y, z, tw: tw, th: th, t3: t3);
          // Правая грань: от top+k3D до top+kH (не выходит за нижнюю границу плитки)
          ws.add(Positioned(
            left: pos.dx + tw - 1,
            top: pos.dy + t3,
            child: Container(
              width: t3 + 1,
              height: th - t3,
              decoration: BoxDecoration(
                color: _sideRColor(z),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(3))))));
          // Нижняя грань: от left+k3D до left+kW
          ws.add(Positioned(
            left: pos.dx + t3,
            top: pos.dy + th - 1,
            child: Container(
              width: tw - t3,
              height: t3 + 1,
              decoration: BoxDecoration(
                color: _sideBColor(z),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3))))));
          // Угол
          ws.add(Positioned(
            left: pos.dx + tw - 1,
            top: pos.dy + th - 1,
            child: Container(
              width: t3 + 1, height: t3 + 1,
              color: const Color(0xFF4A2808))));
        }
      }
    }
    // Проход 2: лицевые части поверх всех граней
    for (int z = 0; z < _board.depth; z++) {
      for (int y = 0; y < _board.height; y++) {
        for (int x = 0; x < _board.width; x++) {
          final tile = _board.tiles[z][y][x];
          if (tile == null) continue;
          final coord = Coordinate(x, y, z);
          final pos = _pos(x, y, z, tw: tw, th: th, t3: t3);
          ws.add(Positioned(
            left: pos.dx, top: pos.dy,
            child: SizedBox(
              width: tw, height: th,
              child: GestureDetector(
                onTap: () => _tap(coord),
                behavior: HitTestBehavior.opaque,
                child: _tileWidget(tile, coord, z, tw: tw, th: th)))));
        }
      }
    }
    return ws;
  }

  Color _sideRColor(int z) {
    if (z == 0) return const Color(0xFF9A5520);
    if (z == 1) return const Color(0xFFAA6530);
    return const Color(0xFFBA7540);
  }

  Color _sideBColor(int z) {
    if (z == 0) return const Color(0xFF6A3810);
    if (z == 1) return const Color(0xFF7A4820);
    return const Color(0xFF8A5830);
  }
  Widget _tileWidget(MahjongTile tile, Coordinate coord, int z,
      {double tw = kW, double th = kH}) {
    final isSel   = _sel == coord;
    final isHint  = coord == _hintA || coord == _hintB;
    final isWrong = _wrongCoord == coord;
    final isMatch = coord == _matchA || coord == _matchB;
    final isShake = _shakeCoord == coord;

    return AnimatedBuilder(
      animation: Listenable.merge([
        if (_matchCtrl != null)   _matchCtrl!,
        if (_shuffleCtrl != null) _shuffleCtrl!,
        if (_shakeCtrl != null)   _shakeCtrl!,
      ]),
      builder: (_, __) {
        double fy = 0, alpha = 1;
        if (isMatch && _matchAnim != null) {
          final t = _matchAnim!.value;
          fy = (coord == _matchA ? -1 : 1) * 35 * t;
          alpha = 1.0 - t;
        }
        final sx = isShake && _shakeAnim != null ? _shakeAnim!.value : 0.0;
        double sa = 1.0;
        if (_shuffleCtrl != null && _shuffling) {
          sa = _shuffleCtrl!.status == AnimationStatus.forward
            ? 1 - _shuffleCtrl!.value : _shuffleCtrl!.value;
        }
        return Opacity(
          opacity: (alpha * sa).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(sx, fy),
            child: _Tile(
              tileW: tw, tileH: th,
              imgNum: tile.index + 1,
              isSel: isSel, isHint: isHint,
              isWrong: isWrong, z: z)));
      });
  }

  Offset _pos(int x, int y, int z,
      {double tw = kW, double th = kH, double t3 = k3D}) {
    final oddX = z.isOdd ? tw / 2 : 0.0;
    return Offset(
      (x / 2) * tw + oddX - z * t3,
      (_board.height - 1 - y) * th - z * t3);
  }
}

// ── ПЛИТКА ─────────────────────────────────────────────────
// 3D как у настоящих плиток маджонга:
// - Кремовый/бежевый цвет лица
// - Светлая рамка сверху-слева (блик) + тёмная снизу-справа (тень)
// - Внешняя тень снизу-справа создаёт объём
class _Tile extends StatelessWidget {
  final int imgNum;
  final bool isSel, isHint, isWrong;
  final int z;
  final double tileW, tileH;
  const _Tile({required this.imgNum, required this.isSel,
    required this.isHint, required this.isWrong, required this.z,
    this.tileW = kW, this.tileH = kH});

  @override
  Widget build(BuildContext context) {
    final b = (z * 6).clamp(0, 18);
    // Кремовый бежевый цвет как у настоящих маджонг плиток
    final face = isWrong
      ? const Color(0xFFCCCCCC)
      : isSel
        ? const Color(0xFFFFF3CC)
        : isHint
          ? const Color(0xFFDDFFDD)
          : Color.fromARGB(255, 245, (232+b).clamp(0,255), (200+b).clamp(0,255));

    // Тень снаружи — создаёт ощущение объёма
    final shadows = isWrong ? <BoxShadow>[] : <BoxShadow>[
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        offset: const Offset(3, 3),
        blurRadius: 4,
        spreadRadius: 0),
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        offset: const Offset(5, 5),
        blurRadius: 8,
        spreadRadius: 0),
    ];

    if (isSel) {
      shadows.add(BoxShadow(
        color: Colors.red.withOpacity(0.5),
        blurRadius: 10, spreadRadius: 1));
    } else if (isHint) {
      shadows.add(BoxShadow(
        color: Colors.green.withOpacity(0.5),
        blurRadius: 10, spreadRadius: 1));
    }

    // Цвет внешней рамки
    final outerBorder = isWrong
      ? const Color(0xFF888888)
      : isSel ? const Color(0xFFCC2200)
      : isHint ? Colors.green
      : const Color(0xFF8B6914);

    return Container(
      width: tileW, height: tileH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kR),
        boxShadow: shadows),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kR),
        child: Stack(children: [
          // Основной фон плитки
          Container(color: face),

          // Картинка
          Positioned.fill(child: Image.asset(
            'assets/tiles/tile_$imgNum.png',
            width: tileW, height: tileH,
            fit: BoxFit.fill, gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Center(child: Text(
              '$imgNum', style: TextStyle(
                fontSize: kH * 0.28, fontWeight: FontWeight.bold,
                color: Colors.brown.shade700))))),

          // 3D эффект — внутренняя рамка
          // Светлая сверху-слева
          Positioned.fill(child: CustomPaint(
            painter: _Bevel3D(
              wrong: isWrong, sel: isSel, hint: isHint))),

          // Внешняя рамка
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kR),
              border: Border.all(
                color: outerBorder,
                width: isSel || isHint ? 2.5 : 1.2)))),

          // Серый оверлей при ошибке
          if (isWrong)
            Positioned.fill(child: Container(
              color: Colors.grey.withOpacity(0.4))),
        ])));
  }
}

class _Bevel3D extends CustomPainter {
  final bool wrong, sel, hint;
  const _Bevel3D({required this.wrong, required this.sel, required this.hint});

  @override
  void paint(Canvas canvas, Size s) {
    if (wrong) return;

    final w = s.width, h = s.height;
    final t = w * 0.07; // толщина скоса

    // Светлая грань — сверху и слева (блик)
    final light = Paint()
      ..color = sel
        ? const Color(0xCCFFEEEE)
        : hint
          ? const Color(0xCCEEFFEE)
          : const Color(0xCCFFFFFF)
      ..style = PaintingStyle.fill;

    // Верхняя грань
    canvas.drawPath(Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - t, t)
      ..lineTo(t, t)
      ..close(), light);

    // Левая грань
    canvas.drawPath(Path()
      ..moveTo(0, 0)
      ..lineTo(t, t)
      ..lineTo(t, h - t)
      ..lineTo(0, h)
      ..close(), light);

    // Тёмная грань — снизу и справа (тень)
    final dark = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.fill;

    // Нижняя грань
    canvas.drawPath(Path()
      ..moveTo(0, h)
      ..lineTo(t, h - t)
      ..lineTo(w - t, h - t)
      ..lineTo(w, h)
      ..close(), dark);

    // Правая грань
    canvas.drawPath(Path()
      ..moveTo(w, 0)
      ..lineTo(w - t, t)
      ..lineTo(w - t, h - t)
      ..lineTo(w, h)
      ..close(), dark);
  }

  @override
  bool shouldRepaint(_Bevel3D o) => wrong != o.wrong || sel != o.sel || hint != o.hint;
}


// ── ДИАЛОГ ПОБЕДЫ ──────────────────────────────────────────
class _WinDlg extends StatelessWidget {
  final int score;
  final String time;
  final VoidCallback onNew, onMenu;
  const _WinDlg({required this.score, required this.time,
    required this.onNew, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: sz.width * 0.06, vertical: sz.height * 0.10),
      child: SizedBox(
        width: sz.width, height: sz.height * 0.78,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('assets/images/backgrounds/win_fielld.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(color: Color(0xFF1B3A2A)))),
            Container(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [const Color(0x33000000),
                         const Color(0xBF000000)]))),
            Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(children: [
                const Spacer(flex: 3),
                Text(tr('Победа!', 'You Win!'), style: TextStyle(
                  color: Colors.white, fontSize: 36,
                  fontWeight: FontWeight.bold, fontFamily: 'Aboreto',
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
                const Spacer(flex: 2),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0x73000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x26FFFFFF))),
                  child: Column(children: [
                    _row(Icons.timer_rounded, tr('Время', 'Time'), time),
                    const SizedBox(height: 12),
                    _row(Icons.star_rounded, tr('Очки', 'Score'), '$score'),
                  ])),
                const Spacer(flex: 2),
                _btn(tr('Новая игра', 'New Game'), kBurgundy, onNew),
                const SizedBox(height: 12),
                _btn(tr('В меню', 'Menu'),
                  const Color(0x33FFFFFF), onMenu),
                const Spacer(),
              ])),
          ]))));
  }

  Widget _row(IconData icon, String label, String val) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(icon, color: Colors.amber, size: 18),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          color: const Color(0xB3FFFFFF), fontSize: 17, fontFamily: 'Aboreto')),
      ]),
      Text(val, style: const TextStyle(
        color: Colors.white, fontSize: 19,
        fontWeight: FontWeight.bold, fontFamily: 'Aboreto')),
    ]);

  Widget _btn(String label, Color color, VoidCallback onTap) =>
    SizedBox(width: double.infinity, child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33FFFFFF))),
        child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, fontSize: 18,
            fontWeight: FontWeight.w600, fontFamily: 'Aboreto')))));
}