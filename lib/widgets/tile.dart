import 'package:flutter/material.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';

class Tile extends StatelessWidget {
  final MahjongTile? tile;
  final bool isSelected;

  const Tile({super.key, this.tile, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    if (tile == null) return const SizedBox(width: 50, height: 60);
    // Функция, которая возвращает номер картинки (1..42)
    final number = _tileNumber(tile!);
    final imagePath = 'assets/tiles/Прямоугольник $number.png';
    return Container(
      width: 50,
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: isSelected ? Border.all(color: Colors.yellow, width: 3) : null,
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Center(child: Text('$number')),
      ),
    );
  }

  int _tileNumber(MahjongTile tile) {
    // маппинг MahjongTile -> номер (1..42) по порядку enum
    return tile.index + 1;
  }
}