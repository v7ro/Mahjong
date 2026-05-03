enum MahjongTile {
  CHARACTER_1, CHARACTER_2, CHARACTER_3, CHARACTER_4, CHARACTER_5,
  CHARACTER_6, CHARACTER_7, CHARACTER_8, CHARACTER_9,
  BAMBOO_1, BAMBOO_2, BAMBOO_3, BAMBOO_4, BAMBOO_5,
  BAMBOO_6, BAMBOO_7, BAMBOO_8, BAMBOO_9,
  ROD_1, ROD_2, ROD_3, ROD_4, ROD_5,
  ROD_6, ROD_7, ROD_8, ROD_9,
  SEASON_1, SEASON_2, SEASON_3, SEASON_4,
  FLOWER_1, FLOWER_2, FLOWER_3, FLOWER_4,
  WIND_1, WIND_2, WIND_3, WIND_4,
  DRAGON_1, DRAGON_2, DRAGON_3,
  // Новые типы — используют картинки tile_43 .. tile_50
  EXTRA_1, EXTRA_2, EXTRA_3, EXTRA_4,
  EXTRA_5, EXTRA_6, EXTRA_7, EXTRA_8,
}

const CharacterTiles = [
  MahjongTile.CHARACTER_1, MahjongTile.CHARACTER_2, MahjongTile.CHARACTER_3,
  MahjongTile.CHARACTER_4, MahjongTile.CHARACTER_5, MahjongTile.CHARACTER_6,
  MahjongTile.CHARACTER_7, MahjongTile.CHARACTER_8, MahjongTile.CHARACTER_9,
];
const BambooTiles = [
  MahjongTile.BAMBOO_1, MahjongTile.BAMBOO_2, MahjongTile.BAMBOO_3,
  MahjongTile.BAMBOO_4, MahjongTile.BAMBOO_5, MahjongTile.BAMBOO_6,
  MahjongTile.BAMBOO_7, MahjongTile.BAMBOO_8, MahjongTile.BAMBOO_9,
];
const RodTiles = [
  MahjongTile.ROD_1, MahjongTile.ROD_2, MahjongTile.ROD_3,
  MahjongTile.ROD_4, MahjongTile.ROD_5, MahjongTile.ROD_6,
  MahjongTile.ROD_7, MahjongTile.ROD_8, MahjongTile.ROD_9,
];
const WindTiles = [
  MahjongTile.WIND_1, MahjongTile.WIND_2, MahjongTile.WIND_3, MahjongTile.WIND_4,
];
const DragonTiles = [
  MahjongTile.DRAGON_1, MahjongTile.DRAGON_2, MahjongTile.DRAGON_3,
];
const FlowerTiles = [
  MahjongTile.FLOWER_1, MahjongTile.FLOWER_2, MahjongTile.FLOWER_3, MahjongTile.FLOWER_4,
];
const SeasonTiles = [
  MahjongTile.SEASON_1, MahjongTile.SEASON_2, MahjongTile.SEASON_3, MahjongTile.SEASON_4,
];
const ExtraTiles = [
  MahjongTile.EXTRA_1, MahjongTile.EXTRA_2, MahjongTile.EXTRA_3, MahjongTile.EXTRA_4,
  MahjongTile.EXTRA_5, MahjongTile.EXTRA_6, MahjongTile.EXTRA_7, MahjongTile.EXTRA_8,
];

// DefaultTileSet — 50 уникальных типов × 2 = 100 штук
// Каждый тип встречается ровно 2 раза (генератор сам раскладывает пары)
const DefaultTileSet = [
  ...CharacterTiles, ...CharacterTiles,
  ...BambooTiles,    ...BambooTiles,
  ...RodTiles,       ...RodTiles,
  ...WindTiles,      ...WindTiles,
  ...DragonTiles,    ...DragonTiles,
  MahjongTile.FLOWER_1, MahjongTile.FLOWER_2, MahjongTile.FLOWER_3, MahjongTile.FLOWER_4,
  MahjongTile.SEASON_1, MahjongTile.SEASON_2, MahjongTile.SEASON_3, MahjongTile.SEASON_4,
  ...ExtraTiles,     ...ExtraTiles,
];

bool isFlower(MahjongTile tile) =>
  tile == MahjongTile.FLOWER_1 || tile == MahjongTile.FLOWER_2 ||
  tile == MahjongTile.FLOWER_3 || tile == MahjongTile.FLOWER_4;

bool isSeason(MahjongTile tile) =>
  tile == MahjongTile.SEASON_1 || tile == MahjongTile.SEASON_2 ||
  tile == MahjongTile.SEASON_3 || tile == MahjongTile.SEASON_4;

const _EnumName = "MahjongTile";
const _EnumNameLength = _EnumName.length;

final _tileToString = Map.fromEntries(MahjongTile.values.map((tile) =>
    MapEntry(tile, tile.toString().substring(_EnumNameLength + 1).toUpperCase())));

final _stringToTile = Map.fromEntries(
    _tileToString.entries.map((pair) => MapEntry(pair.value, pair.key)));

String tileToString(MahjongTile tile) => _tileToString[tile]!;
MahjongTile stringToTile(String str) => _stringToTile[str]!;

bool tilesMatch(MahjongTile a, MahjongTile b) {
  if (a == b) return true;
  if (isFlower(a) && isFlower(b)) return true;
  if (isSeason(a) && isSeason(b)) return true;
  return false;
}

int tileNumber(MahjongTile tile) => tile.index + 1;