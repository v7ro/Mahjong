import 'package:flutter/material.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';
import 'package:mahjong/extensions/game_board_ext.dart';
import 'tile.dart'; 
import 'package:mahjong/engine/layouts/layout.dart';

class Board extends StatelessWidget {
  final GameBoard board;
  final Coordinate? selectedCoord;
  final void Function(Coordinate) onTileTap;

  const Board({
    super.key,
    required this.board,
    required this.onTileTap,
    this.selectedCoord,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: List.generate(board.depth, (z) {
          return Column(
            children: [
              if (z > 0) const SizedBox(height: 8),
              ...List.generate(board.height, (y) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(board.width, (x) {
                    final tile = board.tiles[z][y][x];
                    final coord = Coordinate(x, y, z);
                    final isSelected = selectedCoord == coord;
                    return GestureDetector(
                      onTap: tile != null ? () => onTileTap(coord) : null,
                      child: Tile(
                        tile: tile,
                        isSelected: isSelected,
                      ),
                    );
                  }),
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}