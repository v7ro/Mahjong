import 'dart:math';

// Класс для хранения информации об одной плитке
class Tile {
  final int id;         // Уникальный ID
  final int number;     // Номер (тип) плитки
  final int x, y, z;    // Координаты на поле
  bool isRemoved = false;

  Tile({required this.id, required this.number, required this.x, required this.y, required this.z});
}

class GameBoard {
  // Конфигурация поля: количество слоёв, строк и столбцов
  static const int layers = 3;
  static const int rows = 6;
  static const int cols = 6;

  late List<List<List<Tile?>>> board;
  final Random random = Random();

  GameBoard() {
    generateBoard();
  }

  // --- Генерация уровня (алгоритм обратного хода) ---
  void generateBoard() {
    // 1. Инициализация пустого поля
    board = List.generate(layers, (z) => List.generate(rows, (y) => List.generate(cols, (x) => null)));

    // 2. Определяем все возможные позиции для плиток.
    //    В классической пирамиде каждый следующий слой меньше предыдущего.
    List<(int x, int y, int z)> availableSpots = [];
    for (int z = 0; z < layers; z++) {
      for (int y = z; y < rows - z; y++) {
        for (int x = z; x < cols - z; x++) {
          availableSpots.add((x, y, z));
        }
      }
    }
    availableSpots.shuffle(random);

    // 3. Расставляем пары плиток на доступные места.
    int tileId = 0;
    int currentNumber = 1;

    // Проходим по списку доступных мест и расставляем плитки парами
    for (int i = 0; i < availableSpots.length - 1; i += 2) {
      if (i + 1 >= availableSpots.length) break;

      var pos1 = availableSpots[i];
      var pos2 = availableSpots[i + 1];

      // Создаём две плитки с одинаковым номером (типом)
      Tile tile1 = Tile(id: tileId++, number: currentNumber, x: pos1.$1, y: pos1.$2, z: pos1.$3);
      Tile tile2 = Tile(id: tileId++, number: currentNumber, x: pos2.$1, y: pos2.$2, z: pos2.$3);

      // Размещаем их на поле
      board[pos1.$3][pos1.$2][pos1.$1] = tile1;
      board[pos2.$3][pos2.$2][pos2.$1] = tile2;

      currentNumber++;
    }
  }

  // --- Логика блокировки плиток ---
  bool isTileFree(int x, int y, int z) {
    // Если на этом месте нет плитки, то и говорить не о чем.
    if (board[z][y][x] == null) return false;

    // 1. Проверяем, нет ли плитки сверху (на следующем слое)
    if (z + 1 < layers && board[z + 1][y][x] != null) return false;

    // 2. Проверяем, свободна ли левая ИЛИ правая сторона
    bool leftFree = (x == 0) || (board[z][y][x - 1] == null);
    bool rightFree = (x == cols - 1) || (board[z][y][x + 1] == null);

    // Плитка доступна, если выполнены оба условия
    return leftFree || rightFree;
  }

  // --- Логика удаления пары ---
  bool tryRemovePair(Tile a, Tile b) {
    // 1. Проверяем, совпадают ли номера плиток
    if (a.number != b.number) return false;
    // 2. Это не одна и та же плитка
    if (a == b) return false;
    // 3. Проверяем, доступны ли обе плитки для взятия по правилам
    if (!isTileFree(a.x, a.y, a.z) || !isTileFree(b.x, b.y, b.z)) return false;

    // Если все проверки пройдены, удаляем плитки с поля
    board[a.z][a.y][a.x] = null;
    board[b.z][b.y][b.x] = null;
    return true;
  }

  // --- Проверка победы ---
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