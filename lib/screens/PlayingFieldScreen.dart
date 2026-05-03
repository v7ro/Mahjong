import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mahjong/engine/layouts/layout.dart';
import 'package:mahjong/engine/layouts/top_down_generator.dart';
import 'package:mahjong/engine/pieces/game_board.dart';
import 'package:mahjong/engine/pieces/mahjong_tile.dart';
import 'package:mahjong/extensions/game_board_ext.dart';
import 'setting.dart';
import '../services/firebase_service.dart';
import '../services/game_prefs.dart';

// ─────────────────────────────────────────────────────────────
//  КОНСТАНТЫ РАЗМЕРОВ
//
//  Плитка визуально состоит из:
//  - Лицевая часть: kW × kH
//  - Правая 3D-грань: kD wide, рисуется ПОВЕРХ правого края
//  - Нижняя 3D-грань: kD tall, рисуется ПОВЕРХ нижнего края
//
//  Расположение плиток: шаг = kW по X, kH по Y
//  Верхние слои видны поверх нижних (Stack порядок)
// ─────────────────────────────────────────────────────────────
const double kW = 52.0;   // ширина лица
const double kH = 65.0;   // высота лица
const double kD = 5.0;    // глубина 3D грани
const double kR = 5.0;    // скругление
// Изо-сдвиг верхних слоёв: каждый слой левее и выше
const double kISO = kD + 1.0;

const Color kBurgundy = Color(0xFF6B1F2B);

// ─────────────────────────────────────────────────────────────
//  ЛЕЙАУТЫ (проверены: чётное кол-во плиток, ≥4 movable)
//  z чётный → x чётные (0,2,4...)
//  z нечётный → x нечётные (1,3,5...) — сидят между двумя нижними
// ─────────────────────────────────────────────────────────────
class _L {
  static List<bool> _e(int W, int ox, int ow) =>
    List.generate(W, (x) => x%2==0 && x>=ox && x<ox+ow);
  static List<bool> _o(int W, int ox, int ow) =>
    List.generate(W, (x) => x%2==1 && x>=ox && x<ox+ow);
  static List<List<bool>> _er(int W, int H, int ox, int ow, int oy, int oh) =>
    List.generate(H, (y) => y>=oy&&y<oy+oh ? _e(W,ox,ow) : List.filled(W,false));
  static List<List<bool>> _or(int W, int H, int ox, int ow, int oy, int oh) =>
    List.generate(H, (y) => y>=oy&&y<oy+oh ? _o(W,ox,ow) : List.filled(W,false));

  // Черепаха — 4 слоя, 40 плиток
  static List<List<List<bool>>> turtle() => [
    _er(12,6, 0,12, 1,4), _or(12,6, 1,10, 2,2),
    _er(12,6, 4, 4, 2,2), _or(12,6, 5, 2, 2,1),
  ];

  // Пагода — 4 слоя, 48 плиток
  static List<List<List<bool>>> pagoda() => [
    _er(14,6, 0,14, 1,4), _or(14,6, 1,12, 2,2),
    _er(14,6, 4, 6, 2,2), _or(14,6, 5, 2, 2,1),
  ];

  // Пирамида — 4 слоя
  static List<List<List<bool>>> pyramid() => [
    _er(14,8, 0,14, 0,8), _or(14,8, 1,12, 1,6),
    _er(14,8, 2,10, 2,4), _or(14,8, 3, 8, 3,2),
  ];

  // Крест с башней — 4 слоя
  static List<List<List<bool>>> cross() {
    const W=14,H=10;
    return [
      List.generate(H,(y)=>List.generate(W,(x)=>x%2==0&&((4<=y&&y<=5)||(3<=y&&y<=6&&4<=x&&x<=8)))),
      List.generate(H,(y)=>List.generate(W,(x)=>x%2==1&&3<=x&&x<=9&&4<=y&&y<=5)),
      List.generate(H,(y)=>List.generate(W,(x)=>x%2==0&&4<=x&&x<=8&&4<=y&&y<=5)),
      List.generate(H,(y)=>List.generate(W,(x)=>x%2==1&&5<=x&&x<=7&&y==4)),
    ];
  }

  // Спираль — 1 слой, 40 плиток
  static List<List<List<bool>>> spiral() => [
    List.generate(10,(y)=>List.generate(14,(x){
      if(x%2!=0) return false;
      return (y==1&&0<=x&&x<=12)||(y>=1&&y<=8&&x==12)||
             (y==8&&2<=x&&x<=12)||(y>=3&&y<=8&&x==2)||
             (y==3&&2<=x&&x<=10)||(y>=3&&y<=6&&x==10)||
             (y==6&&4<=x&&x<=10)||(y>=3&&y<=6&&x==4)||
             (y==4&&4<=x&&x<=8)||(y==5&&4<=x&&x<=8);
    })),
  ];

  // Бабочка — 1 слой, 44 плитки
  static List<List<List<bool>>> butterfly() => [
    List.generate(10,(y)=>List.generate(14,(x){
      if(x%2!=0) return false;
      final dx=(x-6).abs();
      return (y==1&&dx>=4)||(y==2&&dx>=2)||(y==3)||
             (y==4&&dx<=4)||(y==5&&dx<=4)||
             (y==6)||(y==7&&dx>=2)||(y==8&&dx>=4);
    })),
  ];

  // Два острова — 2 слоя
  static List<List<List<bool>>> islands() => [
    List.generate(8,(y)=>List.generate(16,(x)=>
      x%2==0&&((0<=x&&x<=4&&1<=y&&y<=6)||(10<=x&&x<=14&&1<=y&&y<=6)))),
    List.generate(8,(y)=>List.generate(16,(x)=>
      x%2==1&&((1<=x&&x<=3&&2<=y&&y<=5)||(11<=x&&x<=13&&2<=y&&y<=5)))),
  ];

  // Шахматка — 1 слой
  static List<List<List<bool>>> checker() => [
    List.generate(12,(y)=>List.generate(12,(x)=>x%2==0&&y%2==0)),
  ];

  static final _all = [turtle, pagoda, pyramid, cross, spiral, butterfly, islands, checker];
  static List<List<List<bool>>> random(Random rng) => _all[rng.nextInt(_all.length)]();
}

// ─────────────────────────────────────────────────────────────
//  Модели
// ─────────────────────────────────────────────────────────────
class _Move {
  final Coordinate a, b; final MahjongTile ta, tb;
  _Move(this.a, this.ta, this.b, this.tb);
}
class _Save {
  final Layout lay; final GameBoard board; final int score, secs; final List<_Move> hist;
  _Save(this.lay, this.board, this.score, this.secs, this.hist);
}
_Save? _save;

// ─────────────────────────────────────────────────────────────
//  ЭКРАН
// ─────────────────────────────────────────────────────────────
class PlayingFieldScreen extends StatefulWidget {
  const PlayingFieldScreen({super.key});
  @override State<PlayingFieldScreen> createState() => _State();
}

class _State extends State<PlayingFieldScreen> with TickerProviderStateMixin {
  late GameBoard _board; late Layout _layout;
  bool _loading = true; String? _err;

  Coordinate? _sel, _drag; Offset _dragOff = Offset.zero;

  // Серый при неверном тапе
  Coordinate? _wrong; Timer? _wrongT;

  // Анимации
  Coordinate? _matchA, _matchB;
  AnimationController? _matchCtrl; Animation<double>? _matchAnim;

  Coordinate? _shake; AnimationController? _shakeCtrl; Animation<double>? _shakeAnim;
  Coordinate? _mis;   AnimationController? _misCtrl;   Animation<double>? _misAnim;

  bool _shuffling=false, _shuffleOverlay=false;
  AnimationController? _shuffleCtrl;

  Coordinate? _hA, _hB;
  int _score=0, _secs=0, _wrongTaps=0, _pairsRemoved=0; Timer? _timer;
  int _hintsLeft=3;
  final List<_Move> _hist=[];
  final _key=GlobalKey();

  @override void initState() { super.initState(); if(_save!=null) _resume(_save!); else _newGame(); }

  @override
  void dispose(){
    if(!_loading&&_err==null) _save=_Save(_layout,_board,_score,_secs,List.from(_hist));
    _timer?.cancel(); _wrongT?.cancel();
    for(final c in [_matchCtrl,_shakeCtrl,_misCtrl,_shuffleCtrl]) c?.dispose();
    super.dispose();
  }

  // ── ГЕНЕРАЦИЯ ───────────────────────────────────────────
  void _newGame(){ _save=null; _reset(); _generate(() => _L.random(Random())); }
  void _restart(){ _save=null; final l=_layout; _reset(); _generate(()=>l.pieces); }

  void _generate(List<List<List<bool>>> Function() fn){
    Future.microtask((){
      try{
        GameBoard? b; Layout? l;
        for(int a=0;a<20&&b==null;a++){
          try{
            l=Layout(fn());
            final p=l.getPrecalc();
            for(int i=0;i<100&&b==null;i++) try{b=makeBoard(l,p);}catch(_){}
          }catch(_){}
        }
        if(b==null||l==null) throw Exception('Не удалось сгенерировать');
        if(!mounted) return;
        setState((){_layout=l!;_board=b!;_loading=false;});
        _startTimer();
      }catch(e){
        if(!mounted) return;
        setState((){_err='$e';_loading=false;});
      }
    });
  }

  void _resume(_Save s){
    _layout=s.lay; _board=s.board; _score=s.score; _secs=s.secs;
    _hist.clear(); _hist.addAll(s.hist); _loading=false;
    WidgetsBinding.instance.addPostFrameCallback((_){ if(mounted){setState((){});_startTimer();} });
  }

  void _reset(){
    setState((){
      _loading=true; _err=null; _sel=null; _drag=null;
      _hA=null; _hB=null; _matchA=null; _matchB=null;
      _wrong=null; _shake=null; _mis=null;
      _shuffling=false; _shuffleOverlay=false;
      _hist.clear(); _score=0; _secs=0; _wrongTaps=0; _pairsRemoved=0;
    });
    _timer?.cancel(); _wrongT?.cancel();
    for(final c in [_matchCtrl,_shakeCtrl,_misCtrl,_shuffleCtrl]){ c?.dispose(); }
    _matchCtrl=null; _shakeCtrl=null; _misCtrl=null; _shuffleCtrl=null;
  }

  Future<void> _loadHints() async {
    final h = await GamePrefs().hintsLeft;
    if (mounted) setState(() => _hintsLeft = h);
  }

  void _startTimer(){
    _timer?.cancel();
    _timer=Timer.periodic(const Duration(seconds:1),(_){ if(mounted) setState(()=>_secs++); });
  }
  String _fmt(int s)=>'${(s~/60).toString().padLeft(2,'0')}:${(s%60).toString().padLeft(2,'0')}';

  // ── ТАП ────────────────────────────────────────────────
  void _tap(Coordinate c){
    if(_shuffling||_matchCtrl?.isAnimating==true) return;
    if(!_board.movable.contains(c)){
      // Неверный тап → серый + шейк
      _wrongT?.cancel();
      setState((){_wrong=c; _sel=null;});
      HapticFeedback.lightImpact();
      _wrongT=Timer(const Duration(milliseconds:900),(){
        if(mounted) setState((){if(_wrong==c)_wrong=null;});
      });
      _animShake(c,true);
      return;
    }
    setState((){
      _wrong=null; _hA=null; _hB=null;
      if(_sel==null){_sel=c; HapticFeedback.selectionClick();}
      else if(_sel==c){_sel=null;}
      else{final a=_sel!; _sel=null; _tryMatch(a,c);}
    });
  }

  // ── DRAG ────────────────────────────────────────────────
  void _dragStart(Coordinate c, Offset g){
    if(_shuffling||_matchCtrl?.isAnimating==true) return;
    if(!_board.movable.contains(c)) return;
    final box=_key.currentContext?.findRenderObject() as RenderBox?;
    if(box==null) return;
    HapticFeedback.mediumImpact();
    setState((){_drag=c; _dragOff=box.globalToLocal(g); _sel=null; _hA=null; _hB=null; _wrong=null;});
  }
  void _dragUpdate(Offset g){
    if(_drag==null) return;
    final box=_key.currentContext?.findRenderObject() as RenderBox?;
    if(box==null) return;
    setState(()=>_dragOff=box.globalToLocal(g));
  }
  void _dragEnd(Offset g){
    if(_drag==null) return;
    final box=_key.currentContext?.findRenderObject() as RenderBox?;
    final dc=_drag!; setState(()=>_drag=null);
    if(box==null) return;
    final t=_at(box.globalToLocal(g));
    if(t!=null&&t!=dc&&_board.movable.contains(t)) _tryMatch(dc,t);
  }

  Coordinate? _at(Offset local){
    for(int z=_board.depth-1;z>=0;z--)
      for(int y=0;y<_board.height;y++)
        for(int x=0;x<_board.width;x++){
          if(_board.tiles[z][y][x]==null) continue;
          final p=_pos(x,y,z);
          if(Rect.fromLTWH(p.dx,p.dy,kW,kH).contains(local)) return Coordinate(x,y,z);
        }
    return null;
  }

  // Позиция плитки:
  // - шаг kW по x, kH по y
  // - нечётные слои сдвинуты на kW/2 (сидят между двумя нижними)
  // - каждый слой выше (меньший z) сдвинут влево-вверх на kISO
  Offset _pos(int x, int y, int z){
    final zOff=(_board.depth-1-z);
    final oddX=(z%2==1)?kW/2:0.0;
    return Offset((x/2)*kW+oddX+zOff*kISO, (_board.height-1-y)*kH+zOff*kISO);
  }

  // ── СОВПАДЕНИЕ ─────────────────────────────────────────
  void _tryMatch(Coordinate a, Coordinate b){
    final ta=_board.tiles[a.z][a.y][a.x]; final tb=_board.tiles[b.z][b.y][b.x];
    if(ta==null||tb==null) return;
    if(!_board.movable.contains(a)||!_board.movable.contains(b)) return;
    if(!tilesMatch(ta,tb)){ _animShake(a,false); HapticFeedback.heavyImpact(); return; }
    _animMatch(a,b,(){
      _board.update((t){t[a.z][a.y][a.x]=null;t[b.z][b.y][b.x]=null;});
      _hist.add(_Move(a,ta,b,tb));
      _pairsRemoved++;
      _score = GamePrefs.calcScore(
        pairsRemoved: _pairsRemoved,
        secondsElapsed: _secs,
        wrongTaps: _wrongTaps,
      );
      HapticFeedback.lightImpact();
      if(_board.isWin()){
        _timer?.cancel(); _save=null;
        FirebaseService().saveScore(_score);
        GamePrefs().onLevelComplete().then((_)=>_loadHints());
        WidgetsBinding.instance.addPostFrameCallback((_)=>_winDlg());
      }
      else if(!_hasMoves()) WidgetsBinding.instance.addPostFrameCallback((_)=>_autoShuffle());
      if(mounted) setState((){});
    });
  }

  bool _hasMoves(){
    final mv=_board.movable.toList();
    for(int i=0;i<mv.length;i++) for(int j=i+1;j<mv.length;j++){
      final ta=_board.tiles[mv[i].z][mv[i].y][mv[i].x];
      final tb=_board.tiles[mv[j].z][mv[j].y][mv[j].x];
      if(ta!=null&&tb!=null&&tilesMatch(ta,tb)) return true;
    }
    return false;
  }

  void _autoShuffle(){ if(!mounted) return; setState((){_shuffling=true;_shuffleOverlay=true;}); Future.delayed(const Duration(seconds:2),_doShuffle); }
  void _manualShuffle(){ if(_shuffling) return; setState((){_shuffling=true;_shuffleOverlay=false;}); Future.delayed(const Duration(milliseconds:60),_doShuffle); }

  void _doShuffle(){
    if(!mounted) return;
    final cs=<Coordinate>[]; final ts=<MahjongTile>[];
    for(int z=0;z<_board.depth;z++) for(int y=0;y<_board.height;y++) for(int x=0;x<_board.width;x++){
      final t=_board.tiles[z][y][x]; if(t!=null){cs.add(Coordinate(x,y,z));ts.add(t);}
    }
    ts.shuffle();
    _shuffleCtrl?.dispose();
    _shuffleCtrl=AnimationController(vsync:this,duration:const Duration(milliseconds:280));
    _shuffleCtrl!.forward().then((_){
      _board.update((g){ for(int i=0;i<cs.length;i++){final c=cs[i];g[c.z][c.y][c.x]=ts[i];} });
      _shuffleCtrl!.reverse().then((_){
        if(!mounted) return;
        setState((){_shuffling=false;_shuffleOverlay=false;});
        if(!_hasMoves()) _autoShuffle();
      });
    });
  }

  void _hint(){
    if(_shuffling) return;
    if(_hintsLeft<=0){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('Нет подсказок! Пройди уровень чтобы получить ещё.')));
      return;
    }
    GamePrefs().useHint().then((ok){
      if(ok&&mounted) setState(()=>_hintsLeft=(_hintsLeft-1).clamp(0,99));
    });
    final mv=_board.movable.toList();
    for(int i=0;i<mv.length;i++) for(int j=i+1;j<mv.length;j++){
      final ta=_board.tiles[mv[i].z][mv[i].y][mv[i].x];
      final tb=_board.tiles[mv[j].z][mv[j].y][mv[j].x];
      if(ta!=null&&tb!=null&&tilesMatch(ta,tb)){
        setState((){_hA=mv[i];_hB=mv[j];_sel=null;});
        return;
      }
    }
  }

  void _undo(){
    if(_hist.isEmpty||_shuffling) return;
    final mv=_hist.removeLast();
    _board.update((t){t[mv.a.z][mv.a.y][mv.a.x]=mv.ta;t[mv.b.z][mv.b.y][mv.b.x]=mv.tb;});
    _score=(_score-10).clamp(0,999999);
    setState((){_sel=null;_hA=null;_hB=null;});
  }

  // ── АНИМАЦИИ ───────────────────────────────────────────
  void _animShake(Coordinate c, bool blocked){
    final nc=AnimationController(vsync:this,duration:const Duration(milliseconds:350));
    final an=TweenSequence([
      TweenSequenceItem(tween:Tween(begin:0.0,end:-10.0),weight:20),
      TweenSequenceItem(tween:Tween(begin:-10.0,end:10.0),weight:35),
      TweenSequenceItem(tween:Tween(begin:10.0,end:-6.0),weight:25),
      TweenSequenceItem(tween:Tween(begin:-6.0,end:0.0),weight:20),
    ]).animate(nc);
    if(blocked){ _shakeCtrl?.dispose(); _shakeCtrl=nc; _shakeAnim=an; setState(()=>_shake=c); nc.forward().then((_){if(mounted) setState(()=>_shake=null);}); }
    else        { _misCtrl?.dispose();   _misCtrl=nc;   _misAnim=an;   setState((){_mis=c;_sel=null;}); nc.forward().then((_){if(mounted) setState(()=>_mis=null);}); }
  }

  void _animMatch(Coordinate a, Coordinate b, VoidCallback done){
    _matchCtrl?.dispose();
    _matchCtrl=AnimationController(vsync:this,duration:const Duration(milliseconds:320));
    _matchAnim=CurvedAnimation(parent:_matchCtrl!,curve:Curves.easeIn);
    setState((){_matchA=a;_matchB=b;});
    _matchCtrl!.forward().then((_){ setState((){_matchA=null;_matchB=null;}); done(); });
  }

  void _winDlg(){
    showDialog(context:context,barrierDismissible:false,builder:(_)=>_WinDlg(
      score:_score, time:_fmt(_secs),
      onNew:(){ Navigator.pop(context); _newGame(); },
      onMenu:(){ Navigator.pop(context); Navigator.pop(context); },
    ));
  }

  // ── BUILD ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context){
    return Scaffold(
      extendBodyBehindAppBar:true,
      appBar:AppBar(
        elevation:0, backgroundColor:Colors.transparent, toolbarHeight:64,
        leading:_AppBtn(asset:'assets/images/button/exit.png',fallback:Icons.arrow_back_ios_new,onTap:(){ _timer?.cancel(); Navigator.pop(context); }),
        actions:[
          _AppBtn(asset:'assets/images/button/setting.PNG',fallback:Icons.settings,
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingScreen()))),
          const SizedBox(width:4),
        ],
      ),
      body:Stack(children:[
        Positioned.fill(child:Image.asset('assets/images/backgrounds/playing_field.jpeg',fit:BoxFit.cover,
          errorBuilder:(_,__,___)=>Container(color:const Color(0xFF2a1a0a)))),
        Positioned.fill(child:Container(color:Colors.black.withOpacity(0.2))),
        if(_loading) const Center(child:CircularProgressIndicator(color:kBurgundy))
        else if(_err!=null)
          Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Padding(padding:const EdgeInsets.all(16),child:Text(_err!,style:const TextStyle(color:Colors.white),textAlign:TextAlign.center)),
            ElevatedButton(onPressed:_newGame,child:const Text('Повторить')),
          ]))
        else _gameUI(),
        if(_shuffleOverlay)
          Positioned.fill(child:IgnorePointer(child:Container(
            color:Colors.black.withOpacity(0.65),
            child:const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
              Text('🔀',style:TextStyle(fontSize:56)),
              SizedBox(height:12),
              Text('Нет ходов!',style:TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.bold),textAlign:TextAlign.center),
              SizedBox(height:6),
              Text('Перемешиваем...',style:TextStyle(color:Colors.white70,fontSize:18)),
            ])),
          ))),
      ]),
    );
  }

  Widget _gameUI()=>Column(children:[
    // Счёт + время — по центру
    SafeArea(bottom:false,child:Padding(
      padding:const EdgeInsets.only(top:4),
      child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        _Badge(icon:Icons.star_rounded,label:'$_score'),
        const SizedBox(width:16),
        _Badge(icon:Icons.timer_rounded,label:_fmt(_secs)),
      ]),
    )),
    // Игровое поле — заполняет оставшееся пространство, без скролла
    Expanded(child:LayoutBuilder(builder:(ctx,constraints)=>Center(
      child:FittedBox(
        fit:BoxFit.contain,
        child:_buildBoard(),
      ),
    ))),
    // Кнопки
    SafeArea(top:false,child:Container(
      color:Colors.black.withOpacity(0.55),
      padding:const EdgeInsets.symmetric(horizontal:8,vertical:8),
      child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
        _SimpleBtn(icon:Icons.undo_rounded,      label:'отмена',     enabled:_hist.isNotEmpty, onTap:_undo),
        _SimpleHintBtn(icon:Icons.lightbulb_outline, label:'подсказка', enabled:true, count:_hintsLeft, onTap:_hint),
        _SimpleBtn(icon:Icons.shuffle_rounded,   label:'перемешать', enabled:!_shuffling,      onTap:_manualShuffle),
      ]),
    )),
  ]);

  // ── ДОСКА ──────────────────────────────────────────────
  Widget _buildBoard(){
    // Размер доски с учётом всех слоёв
    // Нечётные слои сдвигаются на kW/2, поэтому +kW/2 к ширине если есть нечётные слои
    final hasOdd=_board.depth>1;
    final visW=(_board.width/2)*kW+(hasOdd?kW/2:0)+(_board.depth-1)*kISO+kD+1;
    final visH=_board.height*kH+(_board.depth-1)*kISO+kD+1;

    return SizedBox(
      key:_key, width:visW, height:visH,
      child:Listener(
        onPointerMove:(e)=>_dragUpdate(e.position),
        onPointerUp:(e)=>_dragEnd(e.position),
        onPointerCancel:(_){if(_drag!=null) setState(()=>_drag=null);},
        child:Stack(clipBehavior:Clip.none,children:_tiles()),
      ),
    );
  }

  List<Widget> _tiles(){
    final ws=<Widget>[];
    // Рисуем слой за слоем: z=0 первый (нижний), z=depth-1 последний (поверх)
    for(int z=0;z<_board.depth;z++)
      for(int y=0;y<_board.height;y++)
        for(int x=0;x<_board.width;x++){
          final tile=_board.tiles[z][y][x]; if(tile==null) continue;
          final coord=Coordinate(x,y,z);
          if(_drag==coord) continue;
          final p=_pos(x,y,z);

          ws.add(Positioned(
            left:p.dx, top:p.dy,
            child:GestureDetector(
              onTap:()=>_tap(coord),
              onLongPressStart:(d)=>_dragStart(coord,d.globalPosition),
              child:AnimatedBuilder(
                animation:Listenable.merge([
                  if(_matchCtrl!=null) _matchCtrl!,
                  if(_shuffleCtrl!=null) _shuffleCtrl!,
                  if(_shakeCtrl!=null) _shakeCtrl!,
                  if(_misCtrl!=null) _misCtrl!,
                ]),
                builder:(_,__){
                  double fy=0,fa=1;
                  if((coord==_matchA||coord==_matchB)&&_matchAnim!=null){
                    final t=_matchAnim!.value;
                    fy=(coord==_matchA?-1:1)*55*t; fa=1.0-t;
                  }
                  double sx=0;
                  if(coord==_shake&&_shakeAnim!=null) sx=_shakeAnim!.value;
                  if(coord==_mis&&_misAnim!=null)     sx=_misAnim!.value;
                  double sa=1.0;
                  if(_shuffleCtrl!=null&&_shuffling)
                    sa=_shuffleCtrl!.status==AnimationStatus.forward?1-_shuffleCtrl!.value:_shuffleCtrl!.value;
                  return Opacity(
                    opacity:(fa*sa).clamp(0.0,1.0),
                    child:Transform.translate(
                      offset:Offset(sx,fy),
                      child:_Tile(
                        imgNum:tile.index+1,
                        isSel:_sel==coord,
                        isHint:coord==_hA||coord==_hB,
                        isWrong:_wrong==coord,
                        z:z,
                        // Скрыть нижнюю грань если прямо под плиткой есть другая
                        hideBottom: y > 0 && _board.tiles[z][y-1][x] != null,
                        // Скрыть правую грань если прямо справа есть другая плитка
                        hideRight: (x+2 < _board.width) && _board.tiles[z][y][x+2] != null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ));
        }

    // Drag плитка поверх
    if(_drag!=null){
      final dc=_drag!; final tile=_board.tiles[dc.z][dc.y][dc.x];
      if(tile!=null) ws.add(Positioned(
        left:_dragOff.dx-kW/2, top:_dragOff.dy-kH/2,
        child:Transform.scale(scale:1.1,child:_Tile(imgNum:tile.index+1,isSel:true,isHint:false,isWrong:false,z:dc.z,isDrag:true)),
      ));
    }
    return ws;
  }
}

// ─────────────────────────────────────────────────────────────
//  ПЛИТКА
//  Ключевое решение:
//  - Виджет имеет размер kW×kH — плитки стоят вплотную
//  - 3D грани рисуются через Stack с overflow: правая грань
//    выходит за правый край (overflow clip убран), нижняя — за нижний
//  - Изображение через Image.asset — сразу отображается, без async загрузки
// ─────────────────────────────────────────────────────────────
class _Tile extends StatefulWidget {
  final int imgNum; final bool isSel,isHint,isWrong,isDrag; final int z;
  final bool hideBottom, hideRight;
  const _Tile({required this.imgNum,required this.isSel,required this.isHint,
    required this.isWrong,required this.z,this.isDrag=false,
    this.hideBottom=false,this.hideRight=false});
  @override State<_Tile> createState()=>_TileState();
}
class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  AnimationController? _p; Animation<double>? _pa;
  @override void initState(){super.initState();if(widget.isHint)_go();}
  @override void didUpdateWidget(old){
    super.didUpdateWidget(old);
    if(widget.isHint&&!old.isHint) _go();
    if(!widget.isHint&&old.isHint) _stop();
  }
  @override void dispose(){_p?.dispose();super.dispose();}
  void _go(){_p?.dispose();_p=AnimationController(vsync:this,duration:const Duration(milliseconds:650))..repeat(reverse:true);_pa=Tween(begin:1.0,end:1.08).animate(CurvedAnimation(parent:_p!,curve:Curves.easeInOut));setState((){});}
  void _stop(){_p?.dispose();_p=null;_pa=null;if(mounted)setState((){});}

  @override
  Widget build(BuildContext context){
    // Цвета
    Color face,sideR,sideB,border; double bw; bool glow=false; Color? glowC;
    if(widget.isWrong){
      face=const Color(0xFFBDBDBD); sideR=const Color(0xFF9E9E9E); sideB=const Color(0xFF757575);
      border=Colors.grey.shade600; bw=1.0;
    } else if(widget.isSel||widget.isDrag){
      face=const Color(0xFFFFFDE7); sideR=const Color(0xFFF57F17); sideB=const Color(0xFFE65100);
      border=Colors.red.shade600; bw=2.0; glow=true; glowC=Colors.red;
    } else if(widget.isHint){
      face=const Color(0xFFE8F5E9); sideR=const Color(0xFF388E3C); sideB=const Color(0xFF1B5E20);
      border=Colors.green.shade400; bw=2.0; glow=true; glowC=Colors.green;
    } else {
      final b=widget.z*5;
      face=Color.fromARGB(255,245,(229+b).clamp(0,255),(192+b).clamp(0,255));
      sideR=const Color(0xFF9E7040); sideB=const Color(0xFF7A5020);
      border=const Color(0xFFAD8060); bw=0.8;
    }

    // Виджет kW×kH — плитки вплотную
    // Грани рисуются через Stack с overflow (выходят за пределы)
    Widget tile = SizedBox(
      width:kW, height:kH,
      child:Stack(clipBehavior:Clip.none,children:[

        // Нижняя 3D-грань — скрыта если снизу есть плитка
        if(!widget.hideBottom) Positioned(
          left:kD, top:kH,
          child:Container(
            width:kW-kD, height:kD,
            decoration:BoxDecoration(color:sideB,
              borderRadius:const BorderRadius.only(bottomLeft:Radius.circular(kR),bottomRight:Radius.circular(kR))),
          ),
        ),

        // Правая 3D-грань — скрыта если справа есть плитка
        if(!widget.hideRight) Positioned(
          left:kW, top:kD,
          child:Container(
            width:kD, height:kH-kD,
            decoration:BoxDecoration(color:sideR,
              borderRadius:const BorderRadius.only(topRight:Radius.circular(kR),bottomRight:Radius.circular(kR))),
          ),
        ),

        // Уголок (стык граней) — только если обе грани видны
        if(!widget.hideBottom && !widget.hideRight) Positioned(left:kW,top:kH,
          child:Container(width:kD,height:kD,
            decoration:BoxDecoration(color:sideB,
              borderRadius:const BorderRadius.only(bottomRight:Radius.circular(kR))),
          ),
        ),

        // Акцент — только по видимым граням
        if(!widget.hideBottom) Positioned(left:kD,top:kH+kD-1,
          child:Container(width:kW,height:1,color:const Color(0xFF8B1A1A).withOpacity(0.6))),
        if(!widget.hideRight) Positioned(left:kW+kD-1,top:kD,
          child:Container(width:1,height:kH,color:const Color(0xFF8B1A1A).withOpacity(0.6))),

        // Лицевая часть
        Positioned.fill(child:Container(
          decoration:BoxDecoration(
            color:face,
            borderRadius:BorderRadius.circular(kR),
            border:Border.all(color:border,width:bw),
            boxShadow:glow?[BoxShadow(color:glowC!.withOpacity(0.4),blurRadius:8,spreadRadius:1)]:null,
          ),
          child:ClipRRect(
            borderRadius:BorderRadius.circular(kR),
            child:Stack(children:[
              // Изображение — Image.asset отображается сразу без async
              Image.asset(
                'assets/tiles/tile_${widget.imgNum}.png',
                width:kW, height:kH, fit:BoxFit.fill,
                gaplessPlayback:true,
                errorBuilder:(_,__,___)=>Center(
                  child:Text('${widget.imgNum}',style:TextStyle(
                    fontSize:kH*0.28,fontWeight:FontWeight.bold,
                    color:Colors.brown.shade700))),
              ),
              // Серый оверлей при ошибке
              if(widget.isWrong)
                Positioned.fill(child:Container(color:Colors.grey.withOpacity(0.48))),
              // Блик
              if(!widget.isWrong)
                Positioned(top:3,left:5,right:5,
                  child:Container(height:kH*0.16,
                    decoration:BoxDecoration(color:Colors.white.withOpacity(0.20),
                      borderRadius:BorderRadius.circular(3)))),
            ]),
          ),
        )),
      ]),
    );

    if(_p!=null&&_pa!=null) tile=ScaleTransition(scale:_pa!,child:tile);
    return tile;
  }
}

// ─────────────────────────────────────────────────────────────
//  Диалог победы
// ─────────────────────────────────────────────────────────────
class _WinDlg extends StatelessWidget {
  final int score; final String time; final VoidCallback onNew,onMenu;
  const _WinDlg({required this.score,required this.time,required this.onNew,required this.onMenu});

  @override
  Widget build(BuildContext context){
    final sz=MediaQuery.of(context).size;
    return Dialog(
      backgroundColor:Colors.transparent,
      insetPadding:EdgeInsets.symmetric(horizontal:sz.width*0.06,vertical:sz.height*0.08),
      child:SizedBox(width:sz.width,height:sz.height*0.84,child:ClipRRect(
        borderRadius:BorderRadius.circular(24),
        child:Stack(fit:StackFit.expand,children:[
          Image.asset('assets/images/backgrounds/win_field.png',fit:BoxFit.cover,
            errorBuilder:(_,__,___)=>Container(color:const Color(0xFF1B3A2A))),
          Container(decoration:BoxDecoration(gradient:LinearGradient(
            begin:Alignment.topCenter,end:Alignment.bottomCenter,
            colors:[Colors.black.withOpacity(0.2),Colors.black.withOpacity(0.7)]))),
          Padding(
            padding:const EdgeInsets.fromLTRB(28,0,28,36),
            child:Column(children:[
              const Spacer(flex:3),
              const Text('Победа!',style:TextStyle(color:Colors.white,fontSize:38,fontWeight:FontWeight.bold,
                shadows:[Shadow(color:Colors.black54,blurRadius:10,offset:Offset(0,3))])),
              const Spacer(flex:2),
              Container(
                width:double.infinity,
                padding:const EdgeInsets.symmetric(horizontal:28,vertical:20),
                decoration:BoxDecoration(color:Colors.black.withOpacity(0.42),
                  borderRadius:BorderRadius.circular(18),
                  border:Border.all(color:Colors.white.withOpacity(0.15),width:1)),
                child:Column(children:[
                  _row(Icons.timer_rounded,'Время',time),
                  const SizedBox(height:14),
                  _row(Icons.star_rounded,'Очки','$score'),
                ])),
              const Spacer(flex:2),
              _btn('Новая игра',kBurgundy,onNew),
              const SizedBox(height:12),
              _btn('В главное меню',Colors.white.withOpacity(0.18),onMenu),
              const Spacer(flex:1),
            ]),
          ),
        ]),
      )),
    );
  }
  Widget _row(IconData ic,String l,String v)=>Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
    Row(children:[Icon(ic,color:Colors.amber,size:22),const SizedBox(width:10),Text(l,style:const TextStyle(color:Colors.white70,fontSize:17))]),
    Text(v,style:const TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.bold)),
  ]);
  Widget _btn(String l,Color c,VoidCallback f)=>SizedBox(width:double.infinity,child:GestureDetector(onTap:f,
    child:Container(padding:const EdgeInsets.symmetric(vertical:16),
      decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(14),
        border:Border.all(color:Colors.white.withOpacity(0.25),width:1)),
      child:Text(l,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w600)))));
}

// ─────────────────────────────────────────────────────────────
//  Вспомогательные виджеты
// ─────────────────────────────────────────────────────────────
class _AppBtn extends StatelessWidget {
  final String asset; final IconData fallback; final VoidCallback onTap;
  const _AppBtn({required this.asset,required this.fallback,required this.onTap});
  @override Widget build(BuildContext c)=>GestureDetector(onTap:onTap,behavior:HitTestBehavior.opaque,
    child:Container(width:56,height:56,alignment:Alignment.center,
      child:Image.asset(asset,width:38,height:38,errorBuilder:(_,__,___)=>Icon(fallback,color:Colors.white,size:32))));
}
class _Btn extends StatelessWidget {
  final String asset; final IconData fallback; final bool enabled; final VoidCallback onTap;
  const _Btn({required this.asset,required this.fallback,required this.enabled,required this.onTap});
  @override Widget build(BuildContext c)=>GestureDetector(
    onTap:enabled?onTap:null,behavior:HitTestBehavior.opaque,
    child:Opacity(opacity:enabled?1.0:0.35,
      child:AspectRatio(aspectRatio:1.0,child:Container(
        decoration:BoxDecoration(
          color:Colors.black.withOpacity(0.15),
          borderRadius:BorderRadius.circular(16),
          border:Border.all(color:kBurgundy,width:4.0),
        ),
        child:Center(child:Image.asset(asset,width:46,height:46,
          errorBuilder:(_,__,___)=>Icon(fallback,color:Colors.white,size:38)))))));
}
class _BtnHint extends StatelessWidget {
  final String asset; final IconData fallback; final bool enabled;
  final int count; final VoidCallback onTap;
  const _BtnHint({required this.asset,required this.fallback,required this.enabled,
    required this.count,required this.onTap});
  @override Widget build(BuildContext c)=>GestureDetector(
    onTap:enabled?onTap:null,behavior:HitTestBehavior.opaque,
    child:Opacity(opacity:enabled?1.0:0.35,
      child:Stack(clipBehavior:Clip.none,children:[
        AspectRatio(aspectRatio:1.0,child:Container(
          decoration:BoxDecoration(
            color:Colors.black.withOpacity(0.15),
            borderRadius:BorderRadius.circular(16),
            border:Border.all(color:kBurgundy,width:4.0)),
          child:Center(child:Image.asset(asset,width:46,height:46,
            errorBuilder:(_,__,___)=>Icon(fallback,color:Colors.white,size:38))))),
        Positioned(top:-4,right:-4,child:Container(
          padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),
          decoration:BoxDecoration(color:kBurgundy,borderRadius:BorderRadius.circular(10)),
          child:Text('$count',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold)))),
      ])));
}

// Простая кнопка: иконка + подпись
class _SimpleBtn extends StatelessWidget {
  final IconData icon; final String label;
  final bool enabled; final VoidCallback onTap;
  const _SimpleBtn({required this.icon,required this.label,
    required this.enabled,required this.onTap});
  @override Widget build(BuildContext ctx) => GestureDetector(
    onTap: enabled ? onTap : null,
    behavior: HitTestBehavior.opaque,
    child: Opacity(opacity: enabled ? 1.0 : 0.35,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height:3),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 11, letterSpacing: 0.3)),
        ]))));
}

// Кнопка подсказки со счётчиком
class _SimpleHintBtn extends StatelessWidget {
  final IconData icon; final String label;
  final bool enabled; final int count; final VoidCallback onTap;
  const _SimpleHintBtn({required this.icon,required this.label,
    required this.enabled,required this.count,required this.onTap});
  @override Widget build(BuildContext ctx) => GestureDetector(
    onTap: enabled ? onTap : null,
    behavior: HitTestBehavior.opaque,
    child: Opacity(opacity: enabled ? 1.0 : 0.35,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal:8,vertical:4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon, color: Colors.white, size: 28),
            Positioned(top:-4,right:-8,child: Container(
              padding: const EdgeInsets.symmetric(horizontal:5,vertical:1),
              decoration: BoxDecoration(
                color: kBurgundy, borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
          ]),
          const SizedBox(height:3),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 11, letterSpacing: 0.3)),
        ]))));
}


class _Badge extends StatelessWidget {
  final IconData icon; final String label;
  const _Badge({required this.icon,required this.label});
  @override Widget build(BuildContext c)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),
    decoration:BoxDecoration(color:kBurgundy.withOpacity(0.85),borderRadius:BorderRadius.circular(22),
      boxShadow:const[BoxShadow(color:Colors.black38,blurRadius:6,offset:Offset(0,2))]),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:Colors.amber,size:20),const SizedBox(width:6),
      Text(label,style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w700)),
    ]));
}