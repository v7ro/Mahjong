import 'package:flutter/material.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/layouts/layout.dart';
import 'tile.dart';

class Board extends StatelessWidget {
  final GameBoard board;
  final Coordinate? selectedCoord;
  final void Function(Coordinate) onTileTap;
  final Coordinate? hintCoordA;
  final Coordinate? hintCoordB;

  const Board({
    super.key,
    required this.board,
    required this.onTileTap,
    this.selectedCoord,
    this.hintCoordA,
    this.hintCoordB,
  });

  @override
  Widget build(BuildContext context) {
    // Изометрическое отображение: каждый следующий слой сдвигается вверх и влево
    const double tileW = 50.0;
    const double tileH = 60.0;
    const double tileMargin = 2.0;
    const double isoOffsetX = -4.0; // сдвиг слоя влево
    const double isoOffsetY = -8.0; // сдвиг слоя вверх

    final depth = board.depth;
    final height = board.height;
    final width = board.width;

    // Вычислим суммарный размер поля с учётом изометрии
    final totalW = width * (tileW + tileMargin * 2) + depth.abs() * isoOffsetX.abs();
    final totalH = height * (tileH + tileMargin * 2) + depth.abs() * isoOffsetY.abs();

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        children: [
          for (int z = 0; z < depth; z++)
            for (int y = 0; y < height; y++)
              for (int x = 0; x < width; x++)
                _buildTileAt(z, y, x, tileW, tileH, tileMargin, isoOffsetX, isoOffsetY, totalH),
        ],
      ),
    );
  }

  Widget _buildTileAt(
    int z, int y, int x,
    double tileW, double tileH, double margin,
    double isoX, double isoY,
    double totalH,
  ) {
    final tile = board.tiles[z][y][x];
    final coord = Coordinate(x, y, z);

    // Позиция с учётом изометрического сдвига слоя
    final left = x * (tileW + margin * 2) + z * isoX.abs();
    // Нижние слои рисуем ниже, верхние — выше (изо)
    final top = (board.height - 1 - y) * (tileH + margin * 2) +
        (board.depth - 1 - z) * isoY.abs() +
        z * isoY.abs();

    // Состояние плитки
    final isSelected = selectedCoord == coord;
    final isHint = (hintCoordA == coord || hintCoordB == coord);
    final isMovable = tile != null && board.movable.contains(coord);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: (tile != null && isMovable) ? () => onTileTap(coord) : null,
        child: Tile(
          tile: tile,
          isSelected: isSelected,
          isHint: isHint,
          isBlocked: tile != null && !isMovable,
        ),
      ),
    );
  }
}
