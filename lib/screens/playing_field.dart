import 'package:flutter/material.dart';
import 'setting.dart';
import '../game_board.dart';
import '../widgets/game_board_widget.dart';

class PlayingFieldScreen extends StatefulWidget {
  const PlayingFieldScreen({super.key});

  @override
  State<PlayingFieldScreen> createState() => _PlayingFieldScreenState();
}

class _PlayingFieldScreenState extends State<PlayingFieldScreen> {
  static const Color burgundy = Color(0xFF6B1F2B);
  late GameBoard gameBoard;
  Tile? selectedTile;

  @override
  void initState() {
    super.initState();
    gameBoard = GameBoard();
  }

  void onTileTap(Tile tile) {
    setState(() {
      if (selectedTile == null) {
        selectedTile = tile;
      } else {
        if (gameBoard.tryRemovePair(selectedTile!, tile)) {
          if (gameBoard.isWin()) {
            _showWinDialog();
          }
        }
        selectedTile = null;
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
                gameBoard = GameBoard();
                selectedTile = null;
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
          // ФОН
          Positioned.fill(
            child: Opacity(
              opacity: 0.7,
              child: Image.asset(
                'assets/images/backgrounds/playing_field.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ИГРОВОЕ ПОЛЕ (адаптивно)
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GameBoardWidget(
                  board: gameBoard,
                  onTileTap: onTileTap,
                  selectedTile: selectedTile,
                ),
              ),
            ),
          ),
          // КНОПКА НАСТРОЕК
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