import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';

const _kTutorialDone = 'tutorial_done';

Future<bool> isTutorialDone() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(_kTutorialDone) ?? false;
}

Future<void> markTutorialDone() async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kTutorialDone, true);
}

class TutorialScreen extends StatefulWidget {
  final VoidCallback onDone;
  const TutorialScreen({super.key, required this.onDone});
  @override State<TutorialScreen> createState() => _TutorialState();
}

class _TutorialState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin {
  static const kBurgundy = Color(0xFF6B1F2B);

  // 4 плитки: 2 пары, квадратом 2x2
  static const _tiles = [
    MahjongTile.CHARACTER_1, MahjongTile.BAMBOO_1,
    MahjongTile.CHARACTER_1, MahjongTile.BAMBOO_1,
  ];

  late List<MahjongTile?> _board;
  int? _selected;
  int _step = 0;
  bool _done = false;

  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  static const _hints = [
    'Нажми на выделенную плитку',
    'Теперь нажми на такую же — они исчезнут!',
    'Убери последнюю пару!',
    'Ты прошёл обучение 🎉\nТеперь попробуй настоящую игру!',
  ];

  // Индексы плиток для подсветки на каждом шаге
  static const _highlight = [
    [0], [0, 2], [1], <int>[],
  ];

  @override
  void initState() {
    super.initState();
    _board = List.from(_tiles);
    _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.08)
      .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override void dispose() { _pulse.dispose(); super.dispose(); }

  void _tap(int idx) {
    if (_board[idx] == null || _done) return;
    HapticFeedback.selectionClick();

    if (_selected == null) {
      setState(() {
        _selected = idx;
        if (_step == 0) _step = 1;
      });
    } else if (_selected == idx) {
      setState(() => _selected = null);
    } else {
      if (_board[_selected!] == _board[idx]) {
        final selIdx = _selected!;
        setState(() {
          _board[selIdx] = null;
          _board[idx] = null;
          _selected = null;
          final removed = _board.where((t) => t == null).length;
          if (removed >= 4) {
            _step = 3;
            _done = true;
          } else if (removed == 2) {
            _step = 2;
          }
        });
        HapticFeedback.lightImpact();
      } else {
        setState(() => _selected = null);
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: Image.asset(
          'assets/images/backgrounds/playing_field.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFF0d2a14)))),
        Positioned.fill(child: Container(color: const Color(0x66000000))),

        SafeArea(child: Column(children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('обучение',
              style: const TextStyle(
                fontSize: 26, color: Colors.white,
                fontFamily: 'Cormorant',
                fontWeight: FontWeight.w600, letterSpacing: 2))),

          // Доска 2x2
          Expanded(child: Center(child: _buildBoard())),

          // Подсказка
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_step),
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xCC1a0a05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x44FFFFFF))),
              child: Text(_hints[_step],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white, fontSize: 19,
                  fontFamily: 'Cormorant',
                  fontWeight: FontWeight.w600, height: 1.4)))),

          // Кнопка — только после прохождения
          if (_done)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    markTutorialDone();
                    widget.onDone();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBurgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
                  child: const Text('начать игру',
                    style: TextStyle(
                      color: Colors.white, fontSize: 22,
                      fontFamily: 'Cormorant',
                      fontWeight: FontWeight.bold)))))
          else
            const SizedBox(height: 32),
        ])),
      ]));
  }

  Widget _buildBoard() {
    const double tW = 90.0, tH = 110.0, tD = 7.0, tR = 8.0;
    final highlight = _step < _highlight.length ? _highlight[_step] : <int>[];

    // 2x2 сетка
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          _tileWidget(0, highlight, tW, tH, tD, tR),
          const SizedBox(width: 8),
          _tileWidget(1, highlight, tW, tH, tD, tR),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _tileWidget(2, highlight, tW, tH, tD, tR),
          const SizedBox(width: 8),
          _tileWidget(3, highlight, tW, tH, tD, tR),
        ]),
      ]);
  }

  Widget _tileWidget(int i, List<int> highlight,
      double tW, double tH, double tD, double tR) {
    if (_board[i] == null) {
      return SizedBox(
        width: tW + tD, height: tH + tD,
        child: Container(
          margin: EdgeInsets.only(right: tD, bottom: tD),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x22FFFFFF)),
            borderRadius: BorderRadius.circular(tR))));
    }

    final imgNum = _tiles[i].index + 1;
    final isSel  = _selected == i;
    final isHint = highlight.contains(i);

    Color face, borderC; double borderW;
    List<BoxShadow> glow = [];

    if (isSel) {
      face = const Color(0xFFFFFAE6);
      borderC = const Color(0xFFCC2200); borderW = 2.5;
      glow = [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 12)];
    } else if (isHint) {
      face = const Color(0xFFF0FFF4);
      borderC = Colors.green; borderW = 2.5;
      glow = [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12)];
    } else {
      face = const Color(0xFFF5E8C0);
      borderC = const Color(0xFF6B3A10); borderW = 1.2;
    }

    Widget tile = SizedBox(
      width: tW + tD, height: tH + tD,
      child: Stack(children: [
        // Правая грань
        Positioned(left: tW, top: tD, width: tD, height: tH,
          child: Container(decoration: BoxDecoration(
            color: const Color(0xFF9A5520),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3))))),
        // Нижняя грань
        Positioned(left: tD, top: tH, width: tW, height: tD,
          child: Container(decoration: BoxDecoration(
            color: const Color(0xFF6A3810),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(3),
              bottomRight: Radius.circular(3))))),
        // Угол
        Positioned(left: tW, top: tH, width: tD, height: tD,
          child: Container(decoration: const BoxDecoration(
            color: Color(0xFF4A2808),
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(3))))),
        // Лицо
        Positioned(left: 0, top: 0, width: tW, height: tH,
          child: Container(
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(tR),
              border: Border.all(color: borderC, width: borderW),
              boxShadow: glow),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tR),
              child: Image.asset(
                'assets/tiles/tile_$imgNum.png',
                fit: BoxFit.fill, gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Center(
                  child: Text('$imgNum',
                    style: TextStyle(
                      fontSize: tH * 0.3,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade700, fontFamily: 'Cormorant'))))))),
      ]));

    if (isHint) {
      tile = AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) =>
          Transform.scale(scale: _pulseAnim.value, child: child),
        child: tile);
    }

    return GestureDetector(onTap: () => _tap(i), child: tile);
  }
}