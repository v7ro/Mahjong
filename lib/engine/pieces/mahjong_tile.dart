enum MahjongTile {
  CHARACTER_1, CHARACTER_2, CHARACTER_3, CHARACTER_4, CHARACTER_5,
  CHARACTER_6, CHARACTER_7, CHARACTER_8, CHARACTER_9,
  BAMBOO_1, BAMBOO_2, BAMBOO_3, BAMBOO_4, BAMBOO_5,
  BAMBOO_6, BAMBOO_7, BAMBOO_8, BAMBOO_9,
  ROD_1, ROD_2, ROD_3, ROD_4, ROD_5, ROD_6, ROD_7, ROD_8, ROD_9,
  SEASON_1, SEASON_2, SEASON_3, SEASON_4,
  FLOWER_1, FLOWER_2, FLOWER_3, FLOWER_4,
  WIND_1, WIND_2, WIND_3, WIND_4,
  DRAGON_1, DRAGON_2, DRAGON_3,
  EXTRA_1, EXTRA_2, EXTRA_3, EXTRA_4,
  EXTRA_5, EXTRA_6, EXTRA_7, EXTRA_8,
}

bool isFlower(MahjongTile t) =>
  t == MahjongTile.FLOWER_1 || t == MahjongTile.FLOWER_2 ||
  t == MahjongTile.FLOWER_3 || t == MahjongTile.FLOWER_4;

bool isSeason(MahjongTile t) =>
  t == MahjongTile.SEASON_1 || t == MahjongTile.SEASON_2 ||
  t == MahjongTile.SEASON_3 || t == MahjongTile.SEASON_4;

bool tilesMatch(MahjongTile a, MahjongTile b) => a == b;

const List<MahjongTile> DefaultTileSet = [
  MahjongTile.CHARACTER_1, MahjongTile.CHARACTER_1,
  MahjongTile.CHARACTER_2, MahjongTile.CHARACTER_2,
  MahjongTile.CHARACTER_3, MahjongTile.CHARACTER_3,
  MahjongTile.CHARACTER_4, MahjongTile.CHARACTER_4,
  MahjongTile.CHARACTER_5, MahjongTile.CHARACTER_5,
  MahjongTile.CHARACTER_6, MahjongTile.CHARACTER_6,
  MahjongTile.CHARACTER_7, MahjongTile.CHARACTER_7,
  MahjongTile.CHARACTER_8, MahjongTile.CHARACTER_8,
  MahjongTile.CHARACTER_9, MahjongTile.CHARACTER_9,
  MahjongTile.BAMBOO_1, MahjongTile.BAMBOO_1,
  MahjongTile.BAMBOO_2, MahjongTile.BAMBOO_2,
  MahjongTile.BAMBOO_3, MahjongTile.BAMBOO_3,
  MahjongTile.BAMBOO_4, MahjongTile.BAMBOO_4,
  MahjongTile.BAMBOO_5, MahjongTile.BAMBOO_5,
  MahjongTile.BAMBOO_6, MahjongTile.BAMBOO_6,
  MahjongTile.BAMBOO_7, MahjongTile.BAMBOO_7,
  MahjongTile.BAMBOO_8, MahjongTile.BAMBOO_8,
  MahjongTile.BAMBOO_9, MahjongTile.BAMBOO_9,
  MahjongTile.ROD_1, MahjongTile.ROD_1,
  MahjongTile.ROD_2, MahjongTile.ROD_2,
  MahjongTile.ROD_3, MahjongTile.ROD_3,
  MahjongTile.ROD_4, MahjongTile.ROD_4,
  MahjongTile.ROD_5, MahjongTile.ROD_5,
  MahjongTile.ROD_6, MahjongTile.ROD_6,
  MahjongTile.ROD_7, MahjongTile.ROD_7,
  MahjongTile.ROD_8, MahjongTile.ROD_8,
  MahjongTile.ROD_9, MahjongTile.ROD_9,
  MahjongTile.WIND_1, MahjongTile.WIND_1,
  MahjongTile.WIND_2, MahjongTile.WIND_2,
  MahjongTile.WIND_3, MahjongTile.WIND_3,
  MahjongTile.WIND_4, MahjongTile.WIND_4,
  MahjongTile.DRAGON_1, MahjongTile.DRAGON_1,
  MahjongTile.DRAGON_2, MahjongTile.DRAGON_2,
  MahjongTile.DRAGON_3, MahjongTile.DRAGON_3,
  MahjongTile.BAMBOO_1, MahjongTile.BAMBOO_1,
  MahjongTile.BAMBOO_2, MahjongTile.BAMBOO_2,
  MahjongTile.CHARACTER_1, MahjongTile.CHARACTER_1,
  MahjongTile.CHARACTER_2, MahjongTile.CHARACTER_2,
  MahjongTile.EXTRA_1, MahjongTile.EXTRA_1,
  MahjongTile.EXTRA_2, MahjongTile.EXTRA_2,
  MahjongTile.EXTRA_3, MahjongTile.EXTRA_3,
  MahjongTile.EXTRA_4, MahjongTile.EXTRA_4,
  MahjongTile.EXTRA_5, MahjongTile.EXTRA_5,
  MahjongTile.EXTRA_6, MahjongTile.EXTRA_6,
  MahjongTile.EXTRA_7, MahjongTile.EXTRA_7,
  MahjongTile.EXTRA_8, MahjongTile.EXTRA_8,
];

String tileToString(MahjongTile t) => t.name;
MahjongTile stringToTile(String s) =>
  MahjongTile.values.firstWhere((t) => t.name == s);