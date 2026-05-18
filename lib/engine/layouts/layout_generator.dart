import 'dart:math';
import 'package:mahjong/engine/layouts/layout.dart';

/// Процедурная генерация лейаутов — бесконечное число уникальных форм.
/// 8 алгоритмов, каждый с рандомными параметрами.
class LayoutGenerator {
  final Random _rng;
  LayoutGenerator([Random? rng]) : _rng = rng ?? Random();

  Layout nextLayout() {
    for (int attempt = 0; attempt < 100; attempt++) {
      try {
        final pieces = _generate();
        final count = _countTiles(pieces);
        if (count < 16 || count % 2 != 0) continue;
        if (_countMovable(pieces) < 4) continue;
        return Layout(pieces);
      } catch (_) {}
    }
    return Layout(_classic());
  }

  List<List<List<bool>>> _generate() {
    switch (_rng.nextInt(8)) {
      case 0: return _layered();
      case 1: return _symmetric();
      case 2: return _islands();
      case 3: return _spiral();
      case 4: return _cross();
      case 5: return _diamond();
      case 6: return _noisy();
      default: return _classic();
    }
  }

  // Пирамида — случайные размеры и количество слоёв
  List<List<List<bool>>> _layered() {
    final layers = 2 + _rng.nextInt(3); // 2-4 слоя
    final bW = 6 + _rng.nextInt(2) * 2; // 6-8 ширина — умещается на экране
    final bH = 4 + _rng.nextInt(4);
    final result = <List<List<bool>>>[];
    for (int z = 0; z < layers; z++) {
      final s = z * 2;
      result.add(List.generate(bH + 2, (y) =>
        List.generate(bW + 2, (x) {
          if (z.isEven ? x.isOdd : x.isEven) return false;
          return x >= s && x < bW - s + 2 && y >= z && y < bH - z + 2;
        })));
    }
    return result;
  }

  // Симметричная — левая половина зеркалится
  List<List<List<bool>>> _symmetric() {
    final W = 8 + _rng.nextInt(2) * 2; // 8-10 = 4-5 tiles wide
    final H = 6 + _rng.nextInt(4);
    final layers = 1 + _rng.nextInt(3);
    final result = <List<List<bool>>>[];
    for (int z = 0; z < layers; z++) {
      final g = List.generate(H, (_) => List.filled(W, false));
      final cx = W ~/ 2;
      for (int y = 0; y < H; y++) {
        for (int x = 0; x <= cx; x += 2) {
          if (_rng.nextDouble() < 0.65) {
            final lx = z.isEven ? x : (x+1 < W ? x+1 : x);
            final rx = z.isEven
              ? (W-1-x) % 2 == 0 ? W-1-x : W-2-x
              : (W-1-x) % 2 == 1 ? W-1-x : W-2-x;
            if (lx >= 0 && lx < W) g[y][lx] = true;
            if (rx >= 0 && rx < W && rx != lx) g[y][rx] = true;
          }
        }
      }
      result.add(g);
    }
    return result;
  }

  // Острова — 2-4 отдельных блока
  List<List<List<bool>>> _islands() {
    final n = 2 + _rng.nextInt(3);
    final W = n * 6; // narrower
    final H = 8 + _rng.nextInt(4);
    final g = List.generate(H, (_) => List.filled(W, false));
    for (int i = 0; i < n; i++) {
      final ox = i * (W ~/ n) + _rng.nextInt(2) * 2;
      final ow = 4 + _rng.nextInt(3) * 2;
      final oh = 3 + _rng.nextInt(3);
      final oy = _rng.nextInt((H - oh).clamp(1, H));
      for (int y = oy; y < oy + oh && y < H; y++)
        for (int x = ox; x < ox + ow && x < W; x += 2)
          g[y][x] = true;
    }
    final layers = [g];
    if (_rng.nextBool()) {
      final t = List.generate(H, (_) => List.filled(W, false));
      for (int i = 0; i < n; i++) {
        final ox = i * (W ~/ n) + 1;
        final oy = 2 + _rng.nextInt((H - 4).clamp(1, H - 2));
        if (ox + 2 < W && oy + 2 < H) {
          t[oy][ox] = true; t[oy+1][ox] = true;
        }
      }
      layers.add(t);
    }
    return layers;
  }

  // Спираль
  List<List<List<bool>>> _spiral() {
    final sz = 6 + _rng.nextInt(4);
    final W = (sz * 2).clamp(0, 10); final H = sz;
    final g = List.generate(H, (_) => List.filled(W, false));
    bool right = true; int x = 0, y = 0;
    int minX = 0, maxX = W - 2, minY = 0, maxY = H - 1;
    int steps = (W * H ~/ 2).clamp(1, 500);
    for (int s = 0; s < steps; s++) {
      if (x.isEven && x >= 0 && x < W && y >= 0 && y < H) g[y][x] = true;
      if (right) { x += 2; if (x > maxX) { x = maxX; right = false; y++; minY++; } }
      else       { x -= 2; if (x < minX) { x = minX; right = true;  y--; maxY--; } }
      if (y < minY || y > maxY) break;
    }
    // Чётное
    final cnt = g.expand((r)=>r).where((v)=>v).length;
    if (cnt.isOdd) {
      for (int yy = 0; yy < H; yy++) {
        for (int xx = 0; xx < W; xx += 2) {
          if (g[yy][xx]) { g[yy][xx] = false; break; }
        }
        break;
      }
    }
    return [g];
  }

  // Крест/T/L
  List<List<List<bool>>> _cross() {
    final W = 8; final H = 8 + _rng.nextInt(3);
    final layers = 1 + _rng.nextInt(3);
    final result = <List<List<bool>>>[];
    for (int z = 0; z < layers; z++) {
      final s = z;
      result.add(List.generate(H, (y) => List.generate(W, (x) {
        if (z.isEven ? x.isOdd : x.isEven) return false;
        final hBar = y>=H~/2-1 && y<=H~/2 && x>=s*2 && x<W-s*2;
        final vBar = x>=W~/2-2 && x<=W~/2 && y>=s && y<H-s;
        return hBar || vBar;
      })));
    }
    return result;
  }

  // Ромб
  List<List<List<bool>>> _diamond() {
    final r = 3 + _rng.nextInt(3);
    final W = (r * 4 + 4).clamp(0, 10); final H = r * 2 + 4;
    final cx = W ~/ 2; final cy = H ~/ 2;
    final layers = 1 + _rng.nextInt(3);
    final result = <List<List<bool>>>[];
    for (int z = 0; z < layers; z++) {
      final sr = r - z; if (sr <= 0) break;
      result.add(List.generate(H, (y) => List.generate(W, (x) {
        if (z.isEven ? x.isOdd : x.isEven) return false;
        return (x~/ 2 - cx~/2).abs() + (y - cy).abs() <= sr;
      })));
    }
    return result;
  }

  // Шум с зачисткой изолированных
  List<List<List<bool>>> _noisy() {
    final W = 8 + _rng.nextInt(2) * 2;
    final H = 6 + _rng.nextInt(4);
    final d = 0.4 + _rng.nextDouble() * 0.3;
    final g = List.generate(H, (y) => List.generate(W, (x) =>
      x.isEven && _rng.nextDouble() < d));
    for (int y = 0; y < H; y++) for (int x = 0; x < W; x += 2) {
      if (!g[y][x]) continue;
      final nb = [if(x-2>=0) g[y][x-2], if(x+2<W) g[y][x+2],
                  if(y-1>=0) g[y-1][x], if(y+1<H) g[y+1][x]]
        .where((v)=>v).length;
      if (nb == 0) g[y][x] = false;
    }
    final cnt = g.expand((r)=>r).where((v)=>v).length;
    if (cnt.isOdd && cnt > 0) {
      outer: for (int y = 0; y < H; y++)
        for (int x = 0; x < W; x += 2)
          if (g[y][x]) { g[y][x] = false; break outer; }
    }
    return [g];
  }

  // Классика
  List<List<List<bool>>> _classic() => [
    List.generate(7, (y) => List.generate(8, (x) => x.isEven && 1<=y&&y<=5)),
    List.generate(7, (y) => List.generate(8, (x) => x.isOdd  && 2<=y&&y<=4)),
    List.generate(7, (y) => List.generate(8, (x) => x.isEven && x>=2&&x<=4&&y==3)),
  ];

  int _countTiles(List<List<List<bool>>> p) =>
    p.expand((l)=>l).expand((r)=>r).where((v)=>v).length;

  int _countMovable(List<List<List<bool>>> pieces) {
    final tiles = <String>{};
    for (int z=0;z<pieces.length;z++)
      for (int y=0;y<pieces[z].length;y++)
        for (int x=0;x<pieces[z][y].length;x++)
          if (pieces[z][y][x]) tiles.add('$x,$y,$z');
    int m = 0;
    for (final k in tiles) {
      final p=k.split(',');
      final x=int.parse(p[0]),y=int.parse(p[1]),z=int.parse(p[2]);
      if (tiles.contains('${x-1},$y,${z+1}')||tiles.contains('$x,$y,${z+1}')||
          tiles.contains('${x+1},$y,${z+1}')) continue;
      if (!tiles.contains('${x-2},$y,$z')||!tiles.contains('${x+2},$y,$z')) m++;
    }
    return m;
  }
}