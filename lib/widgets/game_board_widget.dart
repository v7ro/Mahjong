import 'package:flutter/material.dart';
import '../game_board.dart';

class GameBoardWidget extends StatelessWidget {
  final GameBoard board;
  final Function(Tile) onTileTap;
  final Tile? selectedTile;

  const GameBoardWidget({
    required this.board,
    required this.onTileTap,
    this.selectedTile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем размеры экрана
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Рассчитываем максимально возможный размер плитки
    double maxTileWidth = (screenWidth - 32) / GameBoard.cols; // 32 на отступы по бокам
    double maxTileHeight = (screenHeight - 200) / (GameBoard.layers * GameBoard.rows); // 200 на AppBar и отступы

    // Берем минимальное значение, чтобы поле точно влезло
    double tileSize = maxTileWidth < maxTileHeight ? maxTileWidth : maxTileHeight;
    if (tileSize > 70) tileSize = 70; // ограничим максимум, чтобы не было гигантских плиток
    double tileHeight = tileSize / 0.85; // прямоугольные плитки

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(GameBoard.layers, (z) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (z > 0) const SizedBox(height: 12), // отступ между слоями
            ...List.generate(GameBoard.rows, (y) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(GameBoard.cols, (x) {
                  final tile = board.board[z][y][x];
                  final isSelected = selectedTile == tile;
                  return GestureDetector(
                    onTap: tile != null ? () => onTileTap(tile) : null,
                    child: Container(
                      width: tileSize,
                      height: tileHeight,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: tile == null ? Colors.transparent : Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(color: Colors.yellow, width: 2)
                            : null,
                      ),
                      child: tile != null
                          ? Center(
                              child: Text(
                                '${tile.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              );
            }),
          ],
        );
      }),
    );
  }
}