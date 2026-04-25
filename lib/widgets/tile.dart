import 'package:flutter/material.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';

class Tile extends StatelessWidget {
  final MahjongTile? tile;
  final bool isSelected;
  final bool isHint;
  final bool isBlocked;

  const Tile({
    super.key,
    this.tile,
    this.isSelected = false,
    this.isHint = false,
    this.isBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    // Пустая ячейка
    if (tile == null) {
      return const SizedBox(width: 54, height: 64);
    }

    final number = tile!.index + 1;
    final imagePath = 'assets/tiles/Прямоугольник $number.png';

    // Выбираем рамку/оверлей по состоянию
    Color? overlayColor;
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (isSelected) {
      borderColor = Colors.yellow;
      borderWidth = 3;
    } else if (isHint) {
      borderColor = Colors.greenAccent;
      borderWidth = 3;
    } else if (isBlocked) {
      overlayColor = Colors.black.withOpacity(0.35);
    }

    return Container(
      width: 50,
      height: 60,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.yellow.withOpacity(0.6), blurRadius: 8)]
            : isHint
                ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 8)]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            // Изображение плитки
            Image.asset(
              imagePath,
              width: 50,
              height: 60,
              fit: BoxFit.fill,
              errorBuilder: (_, __, ___) => _FallbackTile(number: number, isBlocked: isBlocked),
            ),
            // Затемнение для заблокированных
            if (overlayColor != null)
              Positioned.fill(
                child: Container(color: overlayColor),
              ),
          ],
        ),
      ),
    );
  }
}

/// Запасной виджет если картинка не найдена
class _FallbackTile extends StatelessWidget {
  final int number;
  final bool isBlocked;
  const _FallbackTile({required this.number, required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: isBlocked ? Colors.grey.shade400 : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isBlocked ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
