import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahjong/engine/layouts/layout.dart';
import 'package:mahjong/engine/layouts/top_down_generator.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';
import 'package:mahjong/extensions/game_board_ext.dart';
import 'setting.dart';

// ─────────────────────────────────────────────────────────────
//  Константы отображения
// ─────────────────────────────────────────────────────────────
const double kTileW   = 52.0;
const double kTileH   = 64.0;
const double kTileGap = 3.0;
const double kIsoX    = 6.0;
const double kIsoY    = 7.0;
const Color  kBurgundy = Color(0xFF6B1F2B);

// ─────────────────────────────────────────────────────────────
//  Модель хода
// ─────────────────────────────────────────────────────────────
class _Move {
  final Coordinate coordA;
  final MahjongTile tileA;
  final Coordinate coordB;
  final MahjongTile tileB;
  _Move(this.coordA, this.tileA, this.coordB, this.tileB);
}

// ─────────────────────────────────────────────────────────────
//  Экран игры
// ─────────────────────────────────────────────────────────────
class PlayingFieldScreen extends StatefulWidget {
  const PlayingFieldScreen({super.key});
  @override
  State<PlayingFieldScreen> createState() => _PlayingFieldScreenState();
}

class _PlayingFieldScreenState extends State<PlayingFieldScreen>
    with TickerProviderStateMixin {

  // ── Игровое состояние ──────────────────────────────────────
  late GameBoard _board;
  bool _isLoading = true;
  String? _errorMessage;

  // ── Выбор / drag ──────────────────────────────────────────
  Coordinate? _selectedCoord;
  Coordinate? _dragCoord;
  Offset      _dragOffset = Offset.zero;

  // ── Анимация совпадения (сближение + вспышка) ─────────────
  Coordinate? _matchA;
  Coordinate? _matchB;
  AnimationController? _matchMoveCtrl;   // сближение двух плиток
  AnimationController? _matchFlashCtrl;  // вспышка после удара
  Animation<double>? _matchMoveAnim;
  Animation<double>? _matchFlashAnim;

  // ── Анимация перемешивания ─────────────────────────────────
  bool _isShuffling = false;
  AnimationController? _shuffleCtrl;
  Animation<double>? _shuffleAnim;

  // ── Анимация "нет хода" (дёргаем плитку) ──────────────────
  Coordinate? _noMatchCoord;
  AnimationController? _noMatchCtrl;
  Animation<double>? _noMatchAnim;

  // ── Подсказка ──────────────────────────────────────────────
  Coordinate? _hintA;
  Coordinate? _hintB;

  // ── Очки и таймер ─────────────────────────────────────────
  int _score = 0;
  int _secondsElapsed = 0;
  Timer? _timer;

  // ── История для Undo ───────────────────────────────────────
  final List<_Move> _history = [];

  // ── GlobalKey для drag-координат ──────────────────────────
  final _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _matchMoveCtrl?.dispose();
    _matchFlashCtrl?.dispose();
    _shuffleCtrl?.dispose();
    _noMatchCtrl?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  ГЕНЕРАЦИЯ ИГРЫ
  // ─────────────────────────────────────────────────────────────
  void _initGame() {
    setState(() {
      _isLoading     = true;
      _errorMessage  = null;
      _selectedCoord = null;
      _dragCoord     = null;
      _hintA = _hintB = null;
      _matchA = _matchB = null;
      _noMatchCoord  = null;
      _history.clear();
      _score         = 0;
      _secondsElapsed = 0;
      _isShuffling   = false;
    });
    _timer?.cancel();
    _matchMoveCtrl?.dispose();
    _matchMoveCtrl = null;
    _matchFlashCtrl?.dispose();
    _matchFlashCtrl = null;
    _noMatchCtrl?.dispose();
    _noMatchCtrl = null;
    _shuffleCtrl?.dispose();
    _shuffleCtrl = null;

    Future.microtask(() {
      try {
        final board = _generateBoard();
        if (!mounted) return;
        setState(() { _board = board; _isLoading = false; });
        _startTimer();
      } catch (e) {
        if (!mounted) return;
        setState(() { _errorMessage = 'Ошибка генерации: $e'; _isLoading = false; });
      }
    });
  }

  GameBoard _generateBoard() {
    // 3 случайных формы доски — каждый раз новая
    final layouts = [_layoutTurtle(), _layoutPyramid(), _layoutFlat()];
    final choice  = layouts[Random().nextInt(layouts.length)];
    final layout  = Layout(choice);
    final precalc = layout.getPrecalc();

    for (int i = 0; i < 128; i++) {
      try { return makeBoard(layout, precalc); } catch (_) {}
    }
    throw Exception('Не удалось сгенерировать доску');
  }

  // Классическая "черепаха" маджонга — 5 слоёв
  List<List<List<bool>>> _layoutTurtle() {
    // слой 0: 8×14, слой 1: 6×12, слой 2: 4×10, слой 3: 2×8, слой 4: 1 плитка в центре
    final configs = [
      (rows: 8, cols: 14, pad: 0),
      (rows: 6, cols: 12, pad: 1),
      (rows: 4, cols: 10, pad: 2),
      (rows: 2, cols:  8, pad: 3),
      (rows: 1, cols:  2, pad: 6),
    ];
    const maxRows = 8, maxCols = 14;
    return List.generate(configs.length, (z) {
      final cfg = configs[z];
      return List.generate(maxRows, (y) {
        return List.generate(maxCols, (x) {
          final rowOk = y >= (maxRows - cfg.rows) ~/ 2 &&
                        y <  (maxRows + cfg.rows) ~/ 2;
          final colOk = x >= cfg.pad && x < maxCols - cfg.pad;
          return rowOk && colOk;
        });
      });
    });
  }

  // Простая 3-слойная пирамида
  List<List<List<bool>>> _layoutPyramid() {
    const layers = 3, rows = 6, cols = 10;
    return List.generate(layers, (z) =>
      List.generate(rows, (y) =>
        List.generate(cols, (x) =>
          y >= z && y < rows - z && x >= z && x < cols - z)));
  }

  // Плоское поле 1×8×12
  List<List<List<bool>>> _layoutFlat() {
    const rows = 8, cols = 12;
    return [List.generate(rows, (_) => List.filled(cols, true))];
  }

  // ─────────────────────────────────────────────────────────────
  //  ТАЙМЕР
  // ─────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _fmt(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ─────────────────────────────────────────────────────────────
  //  ЛОГИКА: ТАП
  // ─────────────────────────────────────────────────────────────
  void _onTileTap(Coordinate coord) {
    if (_isShuffling || _matchMoveCtrl?.isAnimating == true) return;
    if (!_board.movable.contains(coord)) {
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _hintA = _hintB = null;
      if (_selectedCoord == null) {
        _selectedCoord = coord;
        HapticFeedback.selectionClick();
      } else if (_selectedCoord == coord) {
        _selectedCoord = null;
      } else {
        final a = _selectedCoord!;
        _selectedCoord = null;
        _tryMatch(a, coord);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  ЛОГИКА: DRAG
  // ─────────────────────────────────────────────────────────────
  void _onDragStart(Coordinate coord, Offset globalPos) {
    if (_isShuffling || _matchMoveCtrl?.isAnimating == true) return;
    if (!_board.movable.contains(coord)) return;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _dragCoord  = coord;
      _dragOffset = box.globalToLocal(globalPos);
      _selectedCoord = null;
      _hintA = _hintB = null;
    });
  }

  void _onDragUpdate(Offset globalPos) {
    if (_dragCoord == null) return;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    setState(() => _dragOffset = box.globalToLocal(globalPos));
  }

  void _onDragEnd(Offset globalPos) {
    if (_dragCoord == null) return;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final dc = _dragCoord!;
    setState(() => _dragCoord = null);
    if (box == null) return;

    final local  = box.globalToLocal(globalPos);
    final target = _coordFromOffset(local);
    if (target != null && target != dc && _board.movable.contains(target)) {
      _tryMatch(dc, target);
    }
  }

  Coordinate? _coordFromOffset(Offset local) {
    // Верхние слои проверяем первыми (они перекрывают нижние)
    for (int z = _board.depth - 1; z >= 0; z--) {
      for (int y = 0; y < _board.height; y++) {
        for (int x = 0; x < _board.width; x++) {
          if (_board.tiles[z][y][x] == null) continue;
          final pos  = _tileOffset(x, y, z);
          final rect = Rect.fromLTWH(pos.dx, pos.dy, kTileW, kTileH);
          if (rect.contains(local)) return Coordinate(x, y, z);
        }
      }
    }
    return null;
  }

  Offset _tileOffset(int x, int y, int z) {
    final left = x * (kTileW + kTileGap) + z * kIsoX;
    final top  = (_board.height - 1 - y) * (kTileH + kTileGap)
                 + (_board.depth - 1 - z) * kIsoY;
    return Offset(left, top);
  }

  // ─────────────────────────────────────────────────────────────
  //  СОВПАДЕНИЕ ПАР
  // ─────────────────────────────────────────────────────────────
  void _tryMatch(Coordinate a, Coordinate b) {
    final tileA = _board.tiles[a.z][a.y][a.x];
    final tileB = _board.tiles[b.z][b.y][b.x];
    if (tileA == null || tileB == null) return;
    if (!_board.movable.contains(a) || !_board.movable.contains(b)) return;

    if (!tilesMatch(tileA, tileB)) {
      _animateNoMatch(a);
      HapticFeedback.heavyImpact();
      return;
    }

    // ✅ Совпадение — анимируем сближение → вспышку → удаляем
    _animateMatch(a, b, () {
      _board.update((t) {
        t[a.z][a.y][a.x] = null;
        t[b.z][b.y][b.x] = null;
      });
      _history.add(_Move(a, tileA, b, tileB));
      _score += 10;
      HapticFeedback.lightImpact();

      if (_board.isWin()) {
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) => _showWinDialog());
      } else if (!_hasAnyMoves()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleNoMoves());
      }
      if (mounted) setState(() {});
    });
  }

  bool _hasAnyMoves() {
    final movable = _board.movable.toList();
    for (int i = 0; i < movable.length; i++) {
      for (int j = i + 1; j < movable.length; j++) {
        final ta = _board.tiles[movable[i].z][movable[i].y][movable[i].x];
        final tb = _board.tiles[movable[j].z][movable[j].y][movable[j].x];
        if (ta != null && tb != null && tilesMatch(ta, tb)) return true;
      }
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────
  //  НЕТ ХОДОВ → 2 СЕКУНДЫ → ПЕРЕМЕШИВАНИЕ
  // ─────────────────────────────────────────────────────────────
  void _handleNoMoves() {
    if (!mounted) return;
    setState(() => _isShuffling = true);
    Future.delayed(const Duration(seconds: 2), _shuffleTiles);
  }

  void _shuffleTiles() {
    if (!mounted) return;

    // Собираем все плитки
    final List<Coordinate> coords = [];
    final List<MahjongTile> tiles = [];
    for (int z = 0; z < _board.depth; z++)
      for (int y = 0; y < _board.height; y++)
        for (int x = 0; x < _board.width; x++) {
          final t = _board.tiles[z][y][x];
          if (t != null) { coords.add(Coordinate(x, y, z)); tiles.add(t); }
        }
    tiles.shuffle();

    // Анимация "взрыва" — плитки мигают
    _shuffleCtrl?.dispose();
    _shuffleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shuffleAnim = Tween(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _shuffleCtrl!, curve: Curves.easeIn));

    _shuffleCtrl!.forward().then((_) {
      _board.update((grid) {
        for (int i = 0; i < coords.length; i++) {
          final c = coords[i];
          grid[c.z][c.y][c.x] = tiles[i];
        }
      });

      _shuffleCtrl!.reverse().then((_) {
        if (!mounted) return;
        setState(() => _isShuffling = false);
        if (!_hasAnyMoves()) _handleNoMoves();
      });
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  ПОДСКАЗКА
  // ─────────────────────────────────────────────────────────────
  void _showHint() {
    if (_isShuffling) return;
    final movable = _board.movable.toList();
    for (int i = 0; i < movable.length; i++) {
      for (int j = i + 1; j < movable.length; j++) {
        final ta = _board.tiles[movable[i].z][movable[i].y][movable[i].x];
        final tb = _board.tiles[movable[j].z][movable[j].y][movable[j].x];
        if (ta != null && tb != null && tilesMatch(ta, tb)) {
          setState(() { _hintA = movable[i]; _hintB = movable[j]; _selectedCoord = null; });
          return;
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  ОТМЕНА ХОДА
  // ─────────────────────────────────────────────────────────────
  void _undo() {
    if (_history.isEmpty || _isShuffling) return;
    final mv = _history.removeLast();
    _board.update((t) {
      t[mv.coordA.z][mv.coordA.y][mv.coordA.x] = mv.tileA;
      t[mv.coordB.z][mv.coordB.y][mv.coordB.x] = mv.tileB;
    });
    _score = (_score - 10).clamp(0, 999999);
    setState(() { _selectedCoord = null; _hintA = _hintB = null; });
  }

  // ─────────────────────────────────────────────────────────────
  //  АНИМАЦИИ
  // ─────────────────────────────────────────────────────────────

  // Анимация совпадения: плитки сближаются, потом вспышка
  void _animateMatch(Coordinate a, Coordinate b, VoidCallback onDone) {
    _matchMoveCtrl?.dispose();
    _matchFlashCtrl?.dispose();

    _matchMoveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _matchFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));

    // 0 → 1: плитки сдвигаются навстречу друг другу
    _matchMoveAnim = CurvedAnimation(
        parent: _matchMoveCtrl!, curve: Curves.easeIn);

    // 0 → 1 → 0: яркая вспышка
    _matchFlashAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(_matchFlashCtrl!);

    setState(() { _matchA = a; _matchB = b; });

    _matchMoveCtrl!.forward().then((_) {
      _matchFlashCtrl!.forward().then((_) {
        setState(() { _matchA = null; _matchB = null; });
        onDone();
      });
    });
  }

  // Анимация "нет совпадения": плитка дёргается влево-вправо
  void _animateNoMatch(Coordinate coord) {
    _noMatchCtrl?.dispose();
    _noMatchCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _noMatchAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end:  8.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin:  8.0, end: -5.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -5.0, end:  0.0), weight: 25),
    ]).animate(_noMatchCtrl!);

    setState(() { _noMatchCoord = coord; _selectedCoord = null; });
    _noMatchCtrl!.forward().then((_) {
      if (mounted) setState(() => _noMatchCoord = null);
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  ДИАЛОГИ
  // ─────────────────────────────────────────────────────────────
  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6C8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Победа!', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Время: ${_fmt(_secondsElapsed)}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: kBurgundy.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('⭐ $_score очков',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: kBurgundy)),
          ),
        ]),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); _initGame(); },
            child: const Text('Ещё раз', style: TextStyle(color: kBurgundy, fontSize: 16)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('В меню', style: TextStyle(color: kBurgundy, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: kBurgundy),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () { _timer?.cancel(); Navigator.pop(context); },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: kBurgundy),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Фон
          Positioned.fill(
            child: Opacity(
              opacity: 0.72,
              child: Image.asset('assets/images/backgrounds/playing_field.jpeg',
                  fit: BoxFit.cover),
            ),
          ),

          // Контент
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: kBurgundy))
          else if (_errorMessage != null)
            Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _initGame, child: const Text('Повторить')),
            ]))
          else
            _buildGameUI(),

          // Оверлей "Нет ходов! Перемешиваем..."
          if (_isShuffling)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🔀', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('Нет ходов!',
                          style: TextStyle(color: Colors.white, fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Перемешиваем...',
                          style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameUI() {
    return Column(
      children: [
        // Верхняя панель: очки + таймер
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 80, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Badge(icon: Icons.star_rounded, label: '$_score'),
                const SizedBox(width: 16),
                _Badge(icon: Icons.timer_rounded, label: _fmt(_secondsElapsed)),
              ],
            ),
          ),
        ),

        // Игровое поле с масштабированием
        Expanded(
          child: Center(
            child: InteractiveViewer(
              minScale: 0.4,
              maxScale: 3.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildBoard(),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Нижняя панель кнопок
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: kBurgundy.withOpacity(0.90),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToolBtn(icon: Icons.undo_rounded,         label: 'Отмена',
                    enabled: _history.isNotEmpty, onTap: _undo),
                _ToolBtn(icon: Icons.lightbulb_rounded,    label: 'Подсказка',
                    enabled: true, onTap: _showHint),
                _ToolBtn(icon: Icons.shuffle_rounded,      label: 'Shuffle',
                    enabled: !_isShuffling,
                    onTap: () {
                      setState(() => _isShuffling = true);
                      Future.delayed(const Duration(milliseconds: 50), _shuffleTiles);
                    }),
                _ToolBtn(icon: Icons.refresh_rounded,      label: 'Заново',
                    enabled: true, onTap: _initGame),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  ДОСКА — Stack с плитками
  // ─────────────────────────────────────────────────────────────
  Widget _buildBoard() {
    final totalW = _board.width  * (kTileW + kTileGap) + (_board.depth - 1) * kIsoX + kTileW;
    final totalH = _board.height * (kTileH + kTileGap) + (_board.depth - 1) * kIsoY + kTileH;

    return SizedBox(
      key: _boardKey,
      width:  totalW,
      height: totalH,
      child: Listener(
        onPointerMove:   (e) => _onDragUpdate(e.position),
        onPointerUp:     (e) => _onDragEnd(e.position),
        onPointerCancel: (_) { if (_dragCoord != null) setState(() => _dragCoord = null); },
        child: Stack(
          clipBehavior: Clip.none,
          children: _buildTileWidgets(),
        ),
      ),
    );
  }

  List<Widget> _buildTileWidgets() {
    final widgets = <Widget>[];

    // Рисуем слоями снизу вверх (z=0 первый, z=depth-1 последний)
    for (int z = 0; z < _board.depth; z++) {
      for (int y = 0; y < _board.height; y++) {
        for (int x = 0; x < _board.width; x++) {
          final tile = _board.tiles[z][y][x];
          if (tile == null) continue;

          final coord     = Coordinate(x, y, z);
          final pos       = _tileOffset(x, y, z);
          final movable   = _board.movable.contains(coord);
          final isDragged = _dragCoord == coord;
          final isSelected = _selectedCoord == coord;
          final isHint    = coord == _hintA || coord == _hintB;
          final isMatch   = coord == _matchA || coord == _matchB;
          final isNoMatch = coord == _noMatchCoord;

          // Вычисляем сдвиг при анимации совпадения (сближение)
          Offset matchShift = Offset.zero;
          if (isMatch && _matchMoveAnim != null && _matchA != null && _matchB != null) {
            final progress = _matchMoveAnim!.value;
            final posA = _tileOffset(_matchA!.x, _matchA!.y, _matchA!.z);
            final posB = _tileOffset(_matchB!.x, _matchB!.y, _matchB!.z);
            final center = Offset((posA.dx + posB.dx) / 2, (posA.dy + posB.dy) / 2);
            final myPos = coord == _matchA ? posA : posB;
            matchShift = (center - myPos) * progress * 0.6;
          }

          Widget tileW = AnimatedBuilder(
            animation: Listenable.merge([
              if (_matchMoveCtrl != null) _matchMoveCtrl!,
              if (_matchFlashCtrl != null) _matchFlashCtrl!,
              if (_shuffleCtrl != null) _shuffleCtrl!,
              if (_noMatchCtrl != null) _noMatchCtrl!,
            ]),
            builder: (_, child) {
              double shakeX = 0;
              if (isNoMatch && _noMatchAnim != null) shakeX = _noMatchAnim!.value;

              double opacity = 1.0;
              if (_shuffleAnim != null && _isShuffling) opacity = _shuffleAnim!.value;

              double flashOpacity = 0;
              if (isMatch && _matchFlashAnim != null) flashOpacity = _matchFlashAnim!.value;

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(shakeX, 0) + matchShift,
                  child: Stack(
                    children: [
                      _TileWidget(
                        tile: tile,
                        isMovable: movable,
                        isSelected: isSelected,
                        isHint: isHint,
                        z: z,
                      ),
                      // Вспышка при совпадении
                      if (isMatch && flashOpacity > 0)
                        Positioned.fill(
                          child: Opacity(
                            opacity: flashOpacity,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.yellowAccent.withOpacity(0.9),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );

          if (!isDragged) {
            widgets.add(Positioned(
              left: pos.dx,
              top:  pos.dy,
              child: GestureDetector(
                onTap: () => _onTileTap(coord),
                onLongPressStart: (d) => _onDragStart(coord, d.globalPosition),
                child: tileW,
              ),
            ));
          }
        }
      }
    }

    // Перетаскиваемая плитка — поверх всего
    if (_dragCoord != null) {
      final dc   = _dragCoord!;
      final tile = _board.tiles[dc.z][dc.y][dc.x];
      if (tile != null) {
        widgets.add(Positioned(
          left: _dragOffset.dx - kTileW / 2,
          top:  _dragOffset.dy - kTileH / 2,
          child: Transform.scale(
            scale: 1.18,
            child: _TileWidget(
              tile: tile,
              isMovable: true,
              isSelected: true,
              isHint: false,
              z: dc.z,
              isDragging: true,
            ),
          ),
        ));
      }
    }

    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────
//  Виджет плитки
// ─────────────────────────────────────────────────────────────
class _TileWidget extends StatefulWidget {
  final MahjongTile tile;
  final bool isMovable;
  final bool isSelected;
  final bool isHint;
  final bool isDragging;
  final int z;

  const _TileWidget({
    required this.tile,
    required this.isMovable,
    required this.isSelected,
    required this.isHint,
    required this.z,
    this.isDragging = false,
  });

  @override
  State<_TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<_TileWidget>
    with SingleTickerProviderStateMixin {
  // Пульсация подсказки
  AnimationController? _pulseCtrl;
  Animation<double>?   _pulseAnim;

  @override
  void didUpdateWidget(_TileWidget old) {
    super.didUpdateWidget(old);
    if (widget.isHint && !old.isHint) _startPulse();
    if (!widget.isHint && old.isHint) _stopPulse();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isHint) _startPulse();
  }

  void _startPulse() {
    _pulseCtrl?.dispose();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut));
    setState(() {});
  }

  void _stopPulse() {
    _pulseCtrl?.dispose();
    _pulseCtrl = null;
    _pulseAnim = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final number    = widget.tile.index + 1;
    final imagePath = 'assets/tiles/Прямоугольник $number.png';

    // Цвет тени / рамки
    Color? glowColor;
    Color  borderColor = Colors.transparent;
    double borderWidth = 0;

    if (widget.isSelected || widget.isDragging) {
      borderColor = Colors.yellowAccent;
      borderWidth = 3;
      glowColor   = Colors.yellowAccent;
    } else if (widget.isHint) {
      borderColor = Colors.greenAccent;
      borderWidth = 3;
      glowColor   = Colors.greenAccent;
    }

    // 3D эффект: слои выше — светлее фон
    final depthShade = (widget.z * 12).clamp(0, 40);

    Widget tile = Container(
      width:  kTileW,
      height: kTileH,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor.withOpacity(0.75), blurRadius: 14, spreadRadius: 2)]
            : widget.isMovable
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.5),
                        blurRadius: 4, offset: const Offset(2, 3)),
                  ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Image.asset(imagePath,
                width: kTileW, height: kTileH, fit: BoxFit.fill,
                errorBuilder: (_, __, ___) => _Fallback(
                    number: number, isMovable: widget.isMovable, shade: depthShade)),
            // Затемнение заблокированных плиток
            if (!widget.isMovable && !widget.isDragging)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            // Лёгкий блеск на верхних слоях
            if (widget.z > 0 && widget.isMovable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.08 * widget.z),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Пульсация для подсказки
    if (_pulseCtrl != null && _pulseAnim != null) {
      tile = ScaleTransition(scale: _pulseAnim!, child: tile);
    }

    return tile;
  }
}

// Fallback если картинка не найдена
class _Fallback extends StatelessWidget {
  final int number;
  final bool isMovable;
  final int shade;
  const _Fallback({required this.number, required this.isMovable, required this.shade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kTileW, height: kTileH,
      decoration: BoxDecoration(
        color: isMovable
            ? Color(0xFFF5E5C0 + shade)
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.brown.shade300, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$number',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: isMovable ? Colors.brown.shade800 : Colors.grey)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Вспомогательные виджеты UI
// ─────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: kBurgundy.withOpacity(0.82),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.amber, size: 18),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 16,
              fontWeight: FontWeight.w700)),
    ]),
  );
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label,
    required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11,
            fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
