import 'package:flutter/material.dart';
import '../game_board.dart' as old; // алиас чтобы не конфликтовало с engine GameBoard

class GameBoardWidget extends StatelessWidget {
  final old.GameBoard board;
  final Function(old.Tile) onTileTap;
  final old.Tile? selectedTile;

  const GameBoardWidget({
    required this.board,
    required this.onTileTap,
    this.selectedTile,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth  = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double maxTileW = (screenWidth - 32) / old.GameBoard.cols;
    final double maxTileH =
        (screenHeight - 200) / (old.GameBoard.layers * old.GameBoard.rows);

    double tileSize = maxTileW < maxTileH ? maxTileW : maxTileH;
    if (tileSize > 70) tileSize = 70;
    final double tileHeight = tileSize / 0.85;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(old.GameBoard.layers, (z) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (z > 0) const SizedBox(height: 12),
            ...List.generate(old.GameBoard.rows, (y) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(old.GameBoard.cols, (x) {
                  final tile       = board.board[z][y][x];
                  final isSelected = selectedTile == tile;
                  final isFree     = tile != null && board.isTileFree(x, y, z);

                  return GestureDetector(
                    onTap: (tile != null && isFree) ? () => onTileTap(tile) : null,
                    child: Container(
                      width:  tileSize,
                      height: tileHeight,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        color: tile == null
                            ? Colors.transparent
                            : isFree
                                ? const Color(0xFFF5E5C0)
                                : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(color: Colors.yellow, width: 2.5)
                            : tile != null
                                ? Border.all(color: Colors.brown.shade300, width: 1)
                                : null,
                        boxShadow: tile != null && isFree
                            ? [BoxShadow(
                                color: Colors.black38,
                                blurRadius: 3,
                                offset: const Offset(1, 2))]
                            : null,
                      ),
                      child: tile != null
                          ? Center(
                              child: Text(
                                '${tile.number}',
                                style: TextStyle(
                                  color: isFree
                                      ? Colors.brown.shade800
                                      : Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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
