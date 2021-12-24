import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'background.dart';
import 'box.dart';
import 'fruit.dart';
import 'game_object.dart';
import 'snake.dart';
import 'wall.dart';
import '../settings.dart';
import '../utils.dart';




Field setupGame(
  Settings settings, 
  Listenable repaint, 
  TickerProvider tickerProvider, {
    void Function()? onGameEnded,
    void Function(int)? onFruitEaten
  }) {
  
  Field field = Field(
    settings.fieldWidth, 
    settings.fieldHeight,
    repaint:  repaint,
    tickerProvider: tickerProvider, 
    onGameEnded: onGameEnded,
    onFruitEaten: onFruitEaten);

  Snake snake = Snake(
    field, 
    snakeColor1: settings.theme.snakeColor1,
    snakeColor2: settings.theme.snakeColor2,
    speed: settings.snakeSpeed.value);

  field.addItem(BackgroundItem(
    field, 
    bgColor1:settings.theme.fieldColor1,
    bgColor2:settings.theme.fieldColor2,));

  field.addItem(snake);

  // field.addItem(Wall(field, 0, 0, field.width.toDouble(), 1, color:settings.theme.wallColor));  // top wall
  // field.addItem(Wall(field, 0, field.height-1, field.width.toDouble(), 1, color:settings.theme.wallColor)); // bottom wall
  // field.addItem(Wall(field, 0, 1, 1, field.height-2, color:settings.theme.wallColor)); // left wall
  // field.addItem(Wall(field, field.width-1, 1, 1, field.height-2, color:settings.theme.wallColor)); // right wall

  const wallColor = Colors.transparent;
  field.addItem(Wall(field, 0, -0.1, field.width.toDouble(), 0.1, color:wallColor));  // top wall
  field.addItem(Wall(field, 0, field.height+0, field.width.toDouble(), 0.1, color:wallColor)); // bottom wall
  field.addItem(Wall(field, 0-0.1, 0, 0.1, field.height-0, color:wallColor)); // left wall
  field.addItem(Wall(field, field.width+0, 0, 0.1, field.height-0, color:wallColor)); // right wall

  for (final cell in field.randomEmptyCells(settings.fruitAmount)){
    final fruit = Fruit(field, cell.dx+0.5, cell.dy+0.5, FruitImage.getOrLoad(settings.fruitName));
    field.addItem(fruit);
  }


  field.addCollisionHandler(field.onSnakeFruitCollision);
  field.addCollisionHandler(field.onSnakeWallCollision);
  field.addCollisionHandler(field.onSnakeBoxCollision);
  field.addCollisionHandler(field.onSnakeSnakeCollision);

  field.fruitName = settings.fruitName;

  return field;
}





typedef CollisionCallback<T1 extends GameObject, T2 extends GameObject> = 
  void Function(T1 item1, Shape cell1, T2 item2, Shape cell2, Collision) ;


class _CollisionListener{
  _CollisionListener._();

  static _CollisionListener create<T1 extends GameObject, T2 extends GameObject>(
    CollisionCallback<T1,T2> callback) {
      final res = _CollisionListener._();
      res._t1 = T1;
      res._t2 = T2;
      res._cb = callback;
      return res;
  }

  late Type _t1;
  late Type _t2;
  late Function _cb;

  void call(Collision c) {
    final type1 = c.o1.runtimeType;
    final type2 = c.o2.runtimeType;
    assert((type1 == _t1 && type2 == _t2) ||
           (type1 == _t2 && type2 == _t1));

    if (type1 == _t1 && type2 == _t2) {
      _cb(c.o1, c.shape1, c.o2, c.shape2, c);
    } else if (type1 == _t2 && type2 == _t1) {
      _cb(c.o2, c.shape2, c.o1, c.shape1, c);
    } else {
      throw Exception('Invalid field item type');
    }
  }

}


class _CollisionListeners {

  final Map<UnifiedPair, List<_CollisionListener>> _listeners = {};

  UnifiedPair _id(Type t1, Type t2) => UnifiedPair<Type, Type>(t1, t2);

  void add<T1 extends GameObject, T2 extends GameObject>(
      CollisionCallback<T1, T2> cb) {
    
    final id = _id(T1, T2);
    final l = _listeners[id];
    if (l != null) {
      l.add(_CollisionListener.create(cb));
    }
    else {
      _listeners[id] = [_CollisionListener.create(cb)];
    }
  }

  void remove<T1 extends GameObject, T2 extends GameObject>(
    CollisionCallback<T1, T2> cb) {
    
    final id = _id(T1, T2);
    final l = _listeners[id];
    if (l != null) {
      l.remove(cb);
    }
  }

  void notify<T1 extends GameObject, T2 extends GameObject>(Collision c) {
    final item1Type = c.o1.runtimeType;
    final item2Type = c.o2.runtimeType;

    // final id = _id(T1, T2);
    final id = _id(item1Type, item2Type);
    final l = _listeners[id];
    if (l != null) {
      for (var cb in l) {
        cb.call(c);
      }
    }
  }

}



class Field extends CustomPainter {

  Field(this.width, this.height, {
    required Listenable? repaint,
    this.tickerProvider,
    this.onFruitEaten,
    this.onGameEnded,
    this.gamePaused = true})
      : assert(width > 0),
        assert(height > 0),
        super(repaint: repaint) {

    loadAssetImage('ui/swipe-256.png').then((value) => _swipeImage = value);
    if (!isMobile) {
      loadAssetImage('ui/keyboard-256.png').then((value) => _keyboardImage = value);
    }
  }


  void onKeyDown(RawKeyEvent event) {
    for (var item in _items) {
      item.onKeyDown(event);
    }
  }


  void onPanStart(DragStartDetails details) {
    for(var i in _items) {
      i.onPanStart(details);
    }
  }

  void onPanEnd(DragEndDetails details) {
    for(var i in _items) {
      i.onPanEnd(details);
    }
  }

  void onDoubleTap() {
    for(var i in _items) {
      i.onDoubleTap();
    }
  }


  void onPanUpdate(DragUpdateDetails details){
    for(var i in _items) {
      i.onPanUpdate(details);
    }
  }


  final void Function(int fruits)? onFruitEaten;
  final void Function()? onGameEnded;
  

  final List<GameObject> _items = [];
  int width = 0;
  int height = 0;
  bool gamePaused = true;
  ui.Size? _worldSize;
  TickerProvider? tickerProvider;

  final _CollisionListeners _collisionListeners = _CollisionListeners();

  int _prevMoveTime = 0;

  ui.Image? _keyboardImage;
  ui.Image? _swipeImage;

  
  Iterable<GameObject> get items => _items;

  String fruitName = 'random';
  
  
  ui.Size get worldSize => _worldSize ?? Size.zero;


  void addCollisionHandler<T1 extends GameObject, T2 extends GameObject>(
      CollisionCallback<T1, T2> callback) {
    _collisionListeners.add(callback);
  }

  void removeCollisionHandler<T1 extends GameObject, T2 extends GameObject>(
      CollisionCallback<T1, T2> callback) {
    _collisionListeners.remove(callback);
  }


  void addItem(GameObject item) {
    _items.add(item);
    item.onMounted();
  }


  void removeItem(GameObject item) {
    _items.remove(item);
    item.onDismounted();
  }


  double get cellWidth => worldSize.width / width;


  double get cellHeight => worldSize.height / height;


  bool isCellEmpty(int x, int y) {
    assert(x >= 0 && x < width);
    assert(y >= 0 && y < height);
    RectShape cellRect = RectShape(x.toDouble(), y.toDouble(), 1, 1);
    for (var item in _items) {
      for (var shape in item.shapes) {
        if (shape.toRect.overlaps(cellRect) ?? false) return false;
      }
    }

    return true;
  }


  List<Offset> get emptyCells {
    final cellsOccupied = List<bool>.filled(width*height, false);

    for(final item in _items) {
      for (final shape in item.shapes) {
        final rs = shape.toRect;
        if (rs.width == 0.0  ||  rs.height == 0.0) continue;

        for(int x = rs.left.floor(); x < rs.right.ceil(); x++){
          for(int y = rs.top.floor(); y < rs.bottom.ceil(); y++) {
            if (x >= 0 && x < width && y >= 0 && y < height){
              final cellIndex = y * width + x;
              cellsOccupied[cellIndex] = true;
            }
          }
        }
      }
    }

    List<Offset> res = [];
    for (int i=0; i<cellsOccupied.length; i++) {
      if (cellsOccupied[i] == false) {
        final c = Offset((i % width).toDouble(), (i ~/ width).toDouble());
        res.add(c);
      }
    }

    return res;
  }


  Iterable<Offset> randomEmptyCells(int maxAmount) {
    final emptyCells = this.emptyCells;
    if (emptyCells.length <= maxAmount) {
      return emptyCells;
    }
    
    emptyCells.shuffle();
    return emptyCells.take(maxAmount);
  }


  Offset? get randomEmptyCell {
    final emptyCells = this.emptyCells;
    return emptyCells.isNotEmpty 
      ? emptyCells[Random().nextInt(emptyCells.length)] 
      : null;
  }


  Rect rectToWorld(RectShape rs, [Size? worldSize]) {
    worldSize ??= this.worldSize;
    final cellWorldWidth = worldSize.width / width;
    final cellWorldHeight = worldSize.height / height;
    return Rect.fromLTWH(
      rs.x * cellWorldWidth, 
      rs.y * cellWorldHeight, 
      rs.width * cellWorldWidth, 
      rs.height * cellWorldHeight);
  }


  Rect uiRectToWorld(Rect rs, [Size? worldSize]) {
    worldSize ??= this.worldSize;
    final cellWorldWidth = worldSize.width / width;
    final cellWorldHeight = worldSize.height / height;
    return Rect.fromLTWH(
      rs.left * cellWorldWidth, 
      rs.top * cellWorldHeight, 
      rs.width * cellWorldWidth, 
      rs.height * cellWorldHeight);
  }


  Rect cellToWorld(double cellX, double cellY, [Size? worldSize]) {
    worldSize ??= this.worldSize;
    final cellWorldWidth = worldSize.width / width;
    final cellWorldHeight = worldSize.height / height;
    return Rect.fromLTWH(
      cellX * cellWorldWidth, 
      cellY * cellWorldHeight, 
      cellWorldWidth, 
      cellWorldHeight);
  }


  
  void update() {
    final curTime = DateTime.now().millisecondsSinceEpoch;
    if (_prevMoveTime == 0) _prevMoveTime = curTime;
    int dTime = curTime - _prevMoveTime;

    // check if we are debugging
    if(dTime > 500) {
      dTime = 16;
    }

    for (var item in _items) {
      item.update(dTime);
    }

    _prevMoveTime = curTime;
  }


  void processCollisions(Size worldSize, [Canvas? canvas]) {

    List<Collision> cl = [];
    Snake? snake;
    for (int i = 0; i < _items.length-1; i++) {
      final o1 = _items[i];
      if (o1 is Snake) {
        snake = o1;
      }
      for (int j = i + 1; j < _items.length; j++) {
        final o2 = _items[j];
        if (o1.collide(o2)) {
          cl.addAll(o1.collisions(o2));
        }
      }
    }

    if (snake != null) {
      final head = snake.headLink;
      var l = snake.links.lastEntry();
      while(l != null && l.element != head) {
        if (head.overlaps(l.element) ?? false) {
          cl.add(Collision(snake, head, snake, l.element));
        }
        l = l.previousEntry();
      }
    }

    for (int i=0; i<cl.length; i++) {
      _collisionListeners.notify(cl[i]);
    }
  }


  void onSnakeFruitCollision(Snake snake, Shape snakeLink, Fruit fruit, Shape fruitCell, Collision c) {
    if (snakeLink == snake.headLink) {
      if (snake.headLink.t < 0.5) return;
      snake.digestFruit();
      fruit.field.removeItem(fruit);
      onFruitEaten?.call(snake.fruitsEaten);
      
      final emptyCell = randomEmptyCell;
      if (emptyCell != null) {
        addItem(Fruit(this, emptyCell.dx+0.5, emptyCell.dy+0.5, FruitImage.getOrLoad(fruitName), velocity: null));
      }
    }
  }


  void onSnakeWallCollision(Snake snake, Shape snakeLink, Wall fruit, Shape wallCell, Collision c) {
    if(snakeLink == snake.headLink) {
      snake.moveBackward(snake.headLink.t);
      snake.speed = 0.0;
      snake.animateCollision();
      Future.delayed(const Duration(milliseconds: 300)).then((value){
        snake.speed = -0.5;
        Future.delayed(const Duration(milliseconds: 2000)).then((value){
          snake.speed = 0.0;
          onGameEnded?.call();
        });
      });
    }
    else if (snakeLink == snake.tailLink) {
      // snake.speed = 0.0;
    }
  }


  void onSnakeSnakeCollision(Snake snake, Shape link, Snake snake2, Shape link2, Collision c) {
    snake.moveBackward(snake.headLink.t);
    snake.speed = 0.0;
    snake.animateCollision();
    Future.delayed(const Duration(milliseconds: 300)).then((value){
      snake.speed = -0.5;
      Future.delayed(const Duration(milliseconds: 2000)).then((value){
        snake.speed = 0.0;
        onGameEnded?.call();
      });
    });
  }



  void onSnakeBoxCollision(Snake snake, Shape snakeLink, MovableBox2 box, Shape boxCell, Collision c) {  
    box.moveBox(box.x+snake.headLink.dir.prevVec.x, box.y+snake.headLink.dir.prevVec.y, snake.speed+0.1);
  }


  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    _worldSize = size;
    update();
    processCollisions(size, canvas);

    for (var item in _items) {
      item.paint(canvas, size);
    }

    // final ec = emptyCells;
    // for (final c in ec) {
    //   final r = cellToWorld(c.dx, c.dy);
    //   canvas.drawRect(r, Paint()..color=Colors.red.withAlpha(100));
    // }

    if (gamePaused && _swipeImage != null)  {
      final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
      final swipeImgWidth = _swipeImage!.width.toDouble();
      final swipeImgHeight = _swipeImage!.height.toDouble();
      double factor = (size.height*0.25) / swipeImgHeight;


      Offset swipeImgOffset = Offset.zero;

      if (_keyboardImage != null) {
        final kbImgWidth = _keyboardImage!.width.toDouble();
        final kbImgHeight = _keyboardImage!.height.toDouble();

        final kbDestRect = Rect.fromCenter(
          center: Offset.lerp(canvasRect.center, canvasRect.topCenter, 0.5)! - Offset(kbImgWidth*factor/2, 0), 
          width: kbImgWidth * factor,  
          height: kbImgHeight * factor);
        
        canvas.drawImageRect(
          _keyboardImage!, 
          Rect.fromLTWH(0, 0, kbImgWidth, kbImgHeight),
          kbDestRect, 
          Paint()..filterQuality=ui.FilterQuality.medium);

          swipeImgOffset = Offset(swipeImgWidth*factor/2, 0);
      }

      
      final swipeDestRect = Rect.fromCenter(
        center: Offset.lerp(canvasRect.center, canvasRect.topCenter, 0.5)!+swipeImgOffset, 
        width: swipeImgWidth * factor,  
        height: swipeImgHeight * factor);
      
      canvas.drawImageRect(
        _swipeImage!, 
        Rect.fromLTWH(0, 0, swipeImgWidth, swipeImgHeight),
        swipeDestRect, 
        Paint()..filterQuality=ui.FilterQuality.medium);
    }
    
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}


