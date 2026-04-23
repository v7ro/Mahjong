import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';
import 'package:mahjong/engine/layouts/layout.dart';

extension GameBoardExt on GameBoard {
  bool tryRemovePair(Coordinate a, Coordinate b) {
    final tileA = tiles[a.z][a.y][a.x];
    final tileB = tiles[b.z][b.y][b.x];
    if (tileA == null || tileB == null) return false;
    if (!tilesMatch(tileA, tileB)) return false;
    // проверяем, доступны ли плитки (можно двигать)
    if (!movable.contains(a) || !movable.contains(b)) return false;
    update((tiles) {
      tiles[a.z][a.y][a.x] = null;
      tiles[b.z][b.y][b.x] = null;
    });
    return true;
  }

  bool isWin() {
    for (var layer in tiles) {
      for (var row in layer) {
        for (var tile in row) {
          if (tile != null) return false;
        }
      }
    }
    return true;
  }
}