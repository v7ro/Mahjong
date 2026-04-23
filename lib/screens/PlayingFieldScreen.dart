import 'package:flutter/material.dart';
import 'package:mahjong/engine/layouts/layout.dart';
import 'package:mahjong/engine/layouts/top_down_generator.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/extensions/game_board_ext.dart';
import 'package:mahjong/widgets/board.dart';
import 'setting.dart';

class PlayingFieldScreen extends StatefulWidget {
  const PlayingFieldScreen({super.key});

  @override
  State<PlayingFieldScreen> createState() => _PlayingFieldScreenState();
}

class _PlayingFieldScreenState extends State<PlayingFieldScreen> {
  static const Color burgundy = Color(0xFF6B1F2B);
  late GameBoard _board;
  Coordinate? _selectedCoord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    try {
      // Простая форма пирамиды 3 слоя, 6x8 (можно изменить)
      final layout = Layout(_createPieces());
      final precalc = layout.getPrecalc();
      final board = makeBoard(layout, precalc);
      setState(() {
        _board = board;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка генерации: $e');
      setState(() => _isLoading = false);
    }
  }

  List<List<List<bool>>> _createPieces() {
    const layers = 3;
    const rows = 6;
    const cols = 8;
    final pieces = List.generate(
      layers,
      (z) => List.generate(rows, (y) => List.filled(cols, false)),
    );
    for (int z = 0; z < layers; z++) {
      for (int y = z; y < rows - z; y++) {
        for (int x = z; x < cols - z; x++) {
          pieces[z][y][x] = true;
        }
      }
    }
    return pieces;
  }

  void _onTileTap(Coordinate coord) {
    setState(() {
      if (_selectedCoord == null) {
        _selectedCoord = coord;
      } else {
        if (_board.tryRemovePair(_selectedCoord!, coord)) {
          if (_board.isWin()) {
            _showWinDialog();
          }
        }
        _selectedCoord = null;
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Победа!'),
        content: const Text('Вы прошли уровень'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initGame(); // новая игра
                _selectedCoord = null;
              });
            },
            child: const Text('Новая игра'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: burgundy),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/backgrounds/playing_field.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Board(
                  board: _board,
                  selectedCoord: _selectedCoord,
                  onTileTap: _onTileTap,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 44,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingScreen()),
                );
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/backgrounds/setting.PNG'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}