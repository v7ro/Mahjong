import 'dart:math';

class Tile {
  final int id;
  final int number;
  final int x, y, z;
  bool isRemoved = false;

  Tile({required this.id, required this.number, required this.x, required this.y, required this.z});
}

class GameBoard {
  // Размеры поля — подбери под свой дизайн
  static const int layers = 3;
  static const int rows = 6;
  static const int cols = 6;

  late List<List<List<Tile?>>> board;
  final Random random = Random();

  GameBoard() {
    generateBoard();
  }

  // Генерация гарантированно решаемого поля (метод обратного хода)
  void generateBoard() {
    // 1. Пустая структура
    board = List.generate(layers, (z) => List.generate(rows, (y) => List.generate(cols, (x) => null)));

    // 2. Список всех возможных позиций (учитываем пирамиду)
    List<(int x, int y, int z)> positions = [];
    for (int z = 0; z < layers; z++) {
      for (int y = z; y < rows - z; y++) {
        for (int x = z; x < cols - z; x++) {
          positions.add((x, y, z));
        }
      }
    }
    positions.shuffle(random);

    // 3. Расставляем пары с одинаковыми номерами
    int tileId = 0;
    int currentNumber = 1;
    for (int i = 0; i < positions.length - 1; i += 2) {
      if (i + 1 >= positions.length) break;
      var p1 = positions[i];
      var p2 = positions[i + 1];
      Tile t1 = Tile(id: tileId++, number: currentNumber, x: p1.$1, y: p1.$2, z: p1.$3);
      Tile t2 = Tile(id: tileId++, number: currentNumber, x: p2.$1, y: p2.$2, z: p2.$3);
      board[p1.$3][p1.$2][p1.$1] = t1;
      board[p2.$3][p2.$2][p2.$1] = t2;
      currentNumber++;
    }
  }

  // Проверка, можно ли взять плитку
  bool isTileFree(int x, int y, int z) {
    if (board[z][y][x] == null) return false;
    // сверху ничего не должно быть
    if (z + 1 < layers && board[z + 1][y][x] != null) return false;
    // слева или справа свободно
    bool leftFree = (x == 0) || (board[z][y][x - 1] == null);
    bool rightFree = (x == cols - 1) || (board[z][y][x + 1] == null);
    return leftFree || rightFree;
  }

  // Попытка удалить пару
  bool tryRemovePair(Tile a, Tile b) {
    if (a.number != b.number) return false;
    if (a == b) return false;
    if (!isTileFree(a.x, a.y, a.z) || !isTileFree(b.x, b.y, b.z)) return false;
    board[a.z][a.y][a.x] = null;
    board[b.z][b.y][b.x] = null;
    return true;
  }

  // Проверка победы
  bool isWin() {
    for (int z = 0; z < layers; z++) {
      for (int y = 0; y < rows; y++) {
        for (int x = 0; x < cols; x++) {
          if (board[z][y][x] != null) return false;
        }
      }
    }
    return true;
  }
}