import 'package:flutter/material.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';
import 'package:mahjong/widgets/board.dart';
import 'package:mahjong/engine/layouts/layout.dart'; // для Coordinate

class PlayingFieldScreen extends StatefulWidget {
  const PlayingFieldScreen({super.key});

  @override
  State<PlayingFieldScreen> createState() => _PlayingFieldScreenState();
}

class _PlayingFieldScreenState extends State<PlayingFieldScreen> {
  late GameBoard _board;
  Coordinate? _selectedCoord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createManualBoard();
  }

  void _createManualBoard() {
    final List<List<List<MahjongTile?>>> tiles = List.generate(
      2,
      (_) => List.generate(2, (_) => List.filled(2, null)),
    );

    tiles[0][0][0] = MahjongTile.CHARACTER_1;
    tiles[0][0][1] = MahjongTile.CHARACTER_1;
    tiles[0][1][0] = MahjongTile.BAMBOO_1;
    tiles[0][1][1] = MahjongTile.BAMBOO_1;
    tiles[1][0][0] = MahjongTile.ROD_1;
    tiles[1][0][1] = MahjongTile.ROD_1;
    tiles[1][1][0] = MahjongTile.WIND_1;
    tiles[1][1][1] = MahjongTile.WIND_1;

    _board = GameBoard(tiles);
    setState(() => _isLoading = false);
  }

  void _onTileTap(Coordinate coord) {
    setState(() {
      if (_selectedCoord == null) {
        _selectedCoord = coord;
      } else {
        final tile1 = _board.tiles[_selectedCoord!.z][_selectedCoord!.y][_selectedCoord!.x];
        final tile2 = _board.tiles[coord.z][coord.y][coord.x];
        if (tile1 != null && tile2 != null && tile1 == tile2) {
          _board.update((tiles) {
            tiles[_selectedCoord!.z][_selectedCoord!.y][_selectedCoord!.x] = null;
            tiles[coord.z][coord.y][coord.x] = null;
          });
        }
        _selectedCoord = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Маджонг (тест)')),
      body: Center(
        child: Board(
          board: _board,
          selectedCoord: _selectedCoord,
          onTileTap: _onTileTap,
        ),
      ),
    );
  }
}