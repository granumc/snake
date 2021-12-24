
import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

import 'field.dart';
import '../particles.dart';
import 'fruit.dart';
import 'game_object.dart';



class _ArcInterpolation {
  _ArcInterpolation(SnakeDir dir, Rect r, double t) 
    : assert(t >= 0  &&  t <= 2) {
    
    final a = _map[dir];
    if (a == null) {
      throw Exception('Invalid snake direction');
    }

    rotationPointOffset = a.rotationPointOffset;
    if (t <= 1.0) {
      startAngle = a.startAngle;
      sweepAngle = a.sweepAngle * t;
    }
    else /* if ((t > 1) && (t <= 2)) */ {
      t = t - 1;
      startAngle = a.startAngle + a.sweepAngle * t;
      sweepAngle = a.startAngle + a.sweepAngle - startAngle;
    }

    rect = Rect.fromLTWH(
      r.left + (r.width / 2) * a.rotationPointOffset.dx, 
      r.top + (r.height / 2) * a.rotationPointOffset.dy, 
      r.width, 
      r.height);
  }

  _ArcInterpolation._(this.startAngle, this.sweepAngle, this.rotationPointOffset);

  late final Offset rotationPointOffset;
  late final double startAngle;
  late final double sweepAngle;
  late final Rect rect;


  static Offset point(SnakeDir dir, Rect rect, double t) {
    assert(t >= 0  &&  t <= 2);

    final hw = rect.width / 2.0;
    final hh = rect.height / 2.0;

    final a = _ArcInterpolation(dir, rect, t);

    final angle = (t <= 1.0) ? a.startAngle + a.sweepAngle : a.startAngle;

    return Offset(
      a.rect.center.dx +  hw * cos(angle),
      a.rect.center.dy +  hh * sin(angle));

  }

  static const hPi = pi / 2;

  static final Map<SnakeDir, _ArcInterpolation> _map = {
    SnakeDir.two(SnakeDir.south, SnakeDir.west): _ArcInterpolation._(0.0,  hPi, const Offset(-1.0, -1.0)),
    SnakeDir.two(SnakeDir.west, SnakeDir.north): _ArcInterpolation._(hPi,  hPi, const Offset(1.0, -1.0)),
    SnakeDir.two(SnakeDir.north, SnakeDir.east): _ArcInterpolation._(pi,   hPi, const Offset(1.0, 1.0)),
    SnakeDir.two(SnakeDir.east, SnakeDir.south): _ArcInterpolation._(-hPi, hPi, const Offset(-1.0, 1.0)),

    SnakeDir.two(SnakeDir.north, SnakeDir.west): _ArcInterpolation._(0.0,  -hPi, const Offset(-1.0, 1.0)),
    SnakeDir.two(SnakeDir.west, SnakeDir.south): _ArcInterpolation._(-hPi, -hPi, const Offset(1.0, 1.0)),
    SnakeDir.two(SnakeDir.south, SnakeDir.east): _ArcInterpolation._(pi,   -hPi, const Offset(1.0, -1.0)),
    SnakeDir.two(SnakeDir.east, SnakeDir.north): _ArcInterpolation._(hPi, -hPi, const Offset(-1.0, -1.0)),
  };

  // static final map = UnmodifiableMapView<SnakeDir, _ArcInterpolation>(_map);
}



class _LineInterpolation{
  _LineInterpolation(SnakeDir dir, Rect r, double t)     
    : assert(t >= 0  &&  t <= 2) {

    final c = r.center;
    final hw = r.width / 2;
    final hh = r.height / 2;

    if (t <= 1.0) {
      p1 = Offset(
        c.dx - hw * dir.prevVec.x,
        c.dy - hh * dir.prevVec.y);

      p2 = Offset(
        p1.dx + r.width * dir.prevVec.x * t,
        p1.dy + r.height * dir.prevVec.y * t);

    }
    else /* if (t > 1.0 && t <= 2) */ {
      t = t - 1;

      p2 = Offset(
        c.dx + hw * dir.prevVec.x,
        c.dy + hh * dir.prevVec.y);

      p1 = Offset(
        p2.dx - r.width * dir.prevVec.x * (1-t),
        p2.dy - r.height * dir.prevVec.y * (1-t));
    }
  }

  late Offset p1, p2;


  static Offset point(SnakeDir dir, Rect r, double t) {
    assert(t >= 0.0  &&  t <= 2.0);
    final a = _LineInterpolation(dir, r, t);
    if (t <= 1.0) {
      return a.p2;
    }
    else {
      return a.p1;
    }
  }
}


// Represents composite direction of the snake
// Contains current direction and previous direction if turn was made
class SnakeDir {

  SnakeDir(Vector2 currentVector)
      : _vec = currentVector.clone(),
        _prevVec = currentVector.clone();

  SnakeDir.two(Vector2 prevVector, Vector2 currentVector)
      : _vec = currentVector.clone(),
        _prevVec = prevVector.clone();

  Vector2 _vec;
  Vector2 _prevVec;


  Vector2 get vec => _vec;

  Vector2 get prevVec => _prevVec;

  bool get canChangeVector =>  _vec == _prevVec;

  void changeVec(Vector2 v) {
    assert(_prevVec == _vec, 'Direction vector has already been changed');
    assert(_vec != -v, 'Direction cannot be changed to the opposed one');
    _prevVec = _vec.clone();
    _vec = v.clone();
  }


  static vectorToString (Vector2 v) {
    if (v == east) return 'east';
    if (v == west) return 'west';
    if (v == north) return 'north';
    if (v == south) return 'south';
    return v.toString();
  }


  @override
  String toString() {
    return vectorToString(_prevVec) + ' -> ' + vectorToString(_vec);
  }


  Offset interpolateLine(Rect r, double t) {
    assert(t >= 0  &&  t <= 2);
    final pt1 = _LineInterpolation.point(this, r, t);
    return pt1;
  }


  Offset interpolateArc(Rect r, double t) {
    assert(t >= 0  &&  t <= 2);
    final pt1 = _ArcInterpolation.point(this, r, t);
    return pt1;
  }


  Offset interpolate(Rect r, double t) {
    assert(t >= 0  &&  t <= 2);
    if (_vec == _prevVec) {
      return interpolateLine(r, t);
    } 
    else {
      return interpolateArc(r, t);
    }
  }

 
  SnakeDir get inverted => SnakeDir.two(-_vec, -_prevVec);


  bool get isVertical => (_prevVec == _vec) && (_vec == north  ||  _vec == south);


  bool get isHorizontal => (_prevVec == _vec) && (_vec == east  ||  _vec == west);


  @override
  bool operator==(Object other){
    return (other is SnakeDir) &&
      (_prevVec == other._prevVec) &&
      (_vec == other._vec);
  }


  @override
  int get hashCode => Object.hash(_prevVec, _vec);


  static final Vector2 east = Vector2(1, 0);
  static final Vector2 west = Vector2(-1, 0);
  static final Vector2 north = Vector2(0, -1);
  static final Vector2 south = Vector2(0, 1);

  static final angles = <Vector2, double> {
    east: 0.0,
    west: pi,
    north: -pi / 2,
    south: pi / 2
  };

}


// Represents a single snake link which contains information
// about occupied cell of the field and direction of the snake in the cell
class SnakeLink extends RectShape {
  SnakeLink(double x, double y, Vector2 vec)
    : dir = SnakeDir(vec),
      _t = 1.0,
      super(x, y, 1.0, 1.0);

  SnakeLink.t(double x, double y, Vector2 vec, double t)
    : assert(t >= 0 && t <= 2),
      dir = SnakeDir(vec),
      super(x, y, 1.0, 1.0) {
    
    this.t = t;
  }


  // movement direction
  SnakeDir dir;

  // occupation of a cell by the link
  double _t = 0.0;

  double get t => _t;
  
  set t(double val) {
    assert(val >= 0 && val <= 2);
    _t = val;
    double cx = cellx;
    double cy = celly;
    if (val <= 1.0) {
      if (dir.prevVec == SnakeDir.east){
        set(cx, cy, val, 1.0);
      }
      else if (dir.prevVec == SnakeDir.west){
        set(cx + 1 - val, cy, val, 1.0);
      }
      else if (dir.prevVec == SnakeDir.south){
        set(cx, cy, 1.0, val);
      }
      else if (dir.prevVec == SnakeDir.north){
        set(cx, cy + 1.0 - val, 1.0, val);
      }
    }
    else {
      val = val - 1;
      if (dir.prevVec == SnakeDir.east){
        set(cx + val, cy, 1 - val, 1.0);
      }
      else if (dir.prevVec == SnakeDir.west){
        set(cx, cy, 1 - val, 1.0);
      }
      else if (dir.prevVec == SnakeDir.south){
        set(cx, cy + val, 1.0, 1 - val);
      }
      else if (dir.prevVec == SnakeDir.north){
        set(cx, cy, 1.0, 1 - val);
      }
    }
  }

  double get cellx => x.floorToDouble();
  double get celly => y.floorToDouble();

  @override
  double get bottom => super.bottom.clamp(celly, celly+1.0);

  @override
  double get right => super.right.clamp(cellx, cellx+1.0);


  @override
  String toString(){
    const d = 3;
    return '(${left.toStringAsFixed(d)}, ${top.toStringAsFixed(d)}, ${right.toStringAsFixed(d)}, ${bottom.toStringAsFixed(d)}) $dir';
  }
}


// Field item
class Snake extends GameObject {

  Snake(this.field, {
    this.snakeColor1 = const Color.fromARGB(255, 77, 94, 189),
    this.snakeColor2 = const Color.fromARGB(255, 17, 35, 150),
    this.speed = 5.0,

  }) {
    if (field.width >= field.height) {
      final y = (field.height ~/ 2).toDouble();
      links.addAll([
        // SnakeLink(5, y, SnakeDir.east),
        SnakeLink(4, y, SnakeDir.east),
        SnakeLink(3, y, SnakeDir.east),
        SnakeLink(2, y, SnakeDir.east),
        SnakeLink(1, y, SnakeDir.east),
      ]);
    }
    else {
      final x = (field.width ~/ 2).toDouble();
      links.addAll([
        // SnakeLink(x, field.height - 5, SnakeDir.north),
        SnakeLink(x, field.height - 5, SnakeDir.north),
        SnakeLink(x, field.height - 4, SnakeDir.north),
        SnakeLink(x, field.height - 3, SnakeDir.north),
        SnakeLink(x, field.height - 2, SnakeDir.north),
      ]);
    }

    _snakePainter = SnakePainter(this);
  }

  final Field field;
  late final SnakePainter _snakePainter;
  final Color snakeColor1;
  final Color snakeColor2;
  double speed; // cells per seconds
  
  double _fruitsToDigest = 0;
  int _fruitsEaten = 0;
  final _futureTurns = Queue<Vector2>();

  Vector2? _dragStartPoint;


  final links = DoubleLinkedQueue<SnakeLink>();

  SnakeLink get tailLink => links.last;

  SnakeLink get headLink => links.first;

  int get fruitsEaten => _fruitsEaten;

  @override
  Vector2 get vel => headLink.dir.prevVec * speed;

  @override
  void onKeyDown(RawKeyEvent event) {

    if(event.logicalKey == LogicalKeyboardKey.keyP){
      field.gamePaused = !field.gamePaused;
    }

    if(event.logicalKey == LogicalKeyboardKey.minus){
      speed -= 0.5;
    }

    if(event.logicalKey == LogicalKeyboardKey.equal){
      speed += 0.5;
    }

    if (kDebugMode) {
      if(event.logicalKey == LogicalKeyboardKey.keyS){
        _snakePainter.showTongue(1000);
      }
      else if(event.logicalKey == LogicalKeyboardKey.keyC){
        _snakePainter.collision();
      }
      else if(event.logicalKey == LogicalKeyboardKey.keyW){
        _snakePainter.wink(true, true);
      }
      else if(event.logicalKey == LogicalKeyboardKey.keyD){
        _debugShowDragPoints = !_debugShowDragPoints;
      }
      
    }

    
    Vector2? vec;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      vec = SnakeDir.west;
    }
    else if (event.logicalKey == LogicalKeyboardKey.arrowRight){
      vec = SnakeDir.east;
    }
    else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      vec = SnakeDir.south;
    }
    else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      vec = SnakeDir.north;
    }

    if (vec != null) {
      field.gamePaused = false;
      if(_futureTurns.isEmpty && headLink.dir.canChangeVector) {
        if (headLink.dir.vec != -vec) {
          changeDirection(vec);
        }
      }
      else {
        if (_futureTurns.isNotEmpty) {
          if (_futureTurns.last != vec && _futureTurns.last != -vec) {
            _futureTurns.add(vec);
          }
        }
        else {
          _futureTurns.add(vec);
        }
      }
    }
  }


  bool _inRange(double val, double r1, double r2) {
    return (val >= min(r1, r2) && val <= max(r1, r2));
  }


  @override onDoubleTap(){
    field.gamePaused = true;
  }

  @override
  void onPanStart(DragStartDetails details) {
  }

  @override
  void onPanEnd(DragEndDetails details) {
    _dragStartPoint = null;
  }

  bool _debugShowDragPoints = false;
  final _debugDragPoints = <Offset>[];

  @override
  void onPanUpdate(DragUpdateDetails details) {
    field.gamePaused = false;

    final sens = field.cellWidth * 0.5;
    final sensSquared = sens * sens;
    // print(sens);

    _dragStartPoint ??= Vector2(details.localPosition.dx, details.localPosition.dy);

    final curPoint = Vector2(details.localPosition.dx, details.localPosition.dy);
    final swipeDir = curPoint - _dragStartPoint!;

    if (swipeDir.length2 < sensSquared) return;

    var ang = rad2deg(headLink.dir.vec.angleToSigned(swipeDir));

    const da = 35.0;
    const db = 15.0;
    Vector2? ndir;

    if (headLink.dir.vec == SnakeDir.east) {
      if (_inRange(ang, da, (180 - db))) {
        ndir = SnakeDir.south;
      }
      else if (_inRange(ang, -da, -180+db)) {
        ndir = SnakeDir.north;
      }
    }
    else if (headLink.dir.vec == SnakeDir.west) {
      if (_inRange(ang, da, (180 - db))) {
        ndir = SnakeDir.north;
      }
      else if (_inRange(ang, -da, -180+db)) {
        ndir = SnakeDir.south;
      }
    }
    else if (headLink.dir.vec == SnakeDir.north) {
      if (_inRange(ang, da, (180 - db))) {
        ndir = SnakeDir.east;
      }
      else if (_inRange(ang, -da, -180+db)) {
        ndir = SnakeDir.west;
      }

    }
    else if (headLink.dir.vec == SnakeDir.south) {
      if (_inRange(ang, da, (180 - db))) {
        ndir = SnakeDir.west;
      }
      else if (_inRange(ang, -da, -180+db)) {
        ndir = SnakeDir.east;
      }
    }

    if (ndir != null) {
      _debugDragPoints.clear();
      if(speed > 0){
        _debugDragPoints.add(Offset(_dragStartPoint!.x, _dragStartPoint!.y));
        _debugDragPoints.add(Offset(curPoint.x, curPoint.y));
      }
      else {
        debugPrint('Change snake\'s direction: snake has collided');
      }

      changeDirection(ndir);
    }

    _dragStartPoint = null;
  }


  // @override
  // void onPanUpdate(DragUpdateDetails d) {

  //   _pts.add((d.localPosition));

  //   field.gamePaused = false;

  //   double cellWidth = field.cellWidth;

  //   final sensSquared = cellWidth * cellWidth;
  //   _accOff += Vector2(d.delta.dx, d.delta.dy);


  //   if (_accOff.length2 < sensSquared) return;

  //   var ang = headLink.dir.vec.angleToSigned(_accOff);
  //   ang = rad2deg(ang);
  //   _accOff = Vector2.zero();

    

  //   const da = 35.0;
  //   const db = 15.0;
  //   Vector2? ndir;

  //   if (headLink.dir.vec == SnakeDir.east) {
  //     if (inRange(ang, da, (180 - db))) {
  //       ndir = SnakeDir.south;
  //     }
  //     else if (inRange(ang, -da, -180+db)) {
  //       ndir = SnakeDir.north;
  //     }
  //   }
  //   else if (headLink.dir.vec == SnakeDir.west) {
  //     if (inRange(ang, da, (180 - db))) {
  //       ndir = SnakeDir.north;
  //     }
  //     else if (inRange(ang, -da, -180+db)) {
  //       ndir = SnakeDir.south;
  //     }
  //   }
  //   else if (headLink.dir.vec == SnakeDir.north) {
  //     if (inRange(ang, da, (180 - db))) {
  //       ndir = SnakeDir.east;
  //     }
  //     else if (inRange(ang, -da, -180+db)) {
  //       ndir = SnakeDir.west;
  //     }

  //   }
  //   else if (headLink.dir.vec == SnakeDir.south) {
  //     if (inRange(ang, da, (180 - db))) {
  //       ndir = SnakeDir.west;
  //     }
  //     else if (inRange(ang, -da, -180+db)) {
  //       ndir = SnakeDir.east;
  //     }
  //   }

  //   if (ndir != null) {
  //     changeDirection(ndir);
  //     // print(ndir);
  //     // print('turn $ang  $ndir');
  //   }

  // }


  void changeDirection(Vector2 newVec) {
    if (headLink.dir.vec == newVec) return;

    if (headLink.dir.vec != headLink.dir.prevVec) return;

    if (newVec == -headLink.dir.vec) return;

    headLink.dir.changeVec(newVec);
  }


  @override
  void paint(Canvas canvas, Size worldSize) {
    _snakePainter.draw(canvas, worldSize);

    if (_debugShowDragPoints) {
      if (_debugDragPoints.length == 2) {
        canvas.drawLine(_debugDragPoints[0], _debugDragPoints[1], Paint()..color=Colors.indigo..strokeWidth=5);
      }
      if (_debugDragPoints.isNotEmpty) {
        canvas.drawCircle(_debugDragPoints[0], 5, Paint()..color=Colors.green);
      }
      if (_debugDragPoints.length > 1) {
        canvas.drawCircle(_debugDragPoints[1], 5, Paint()..color=Colors.red);
      }
    }
  }


  void moveForward(double cells) {
    final tmpCells = cells;
   
    while(cells > 0.0) {
      if (cells > 1.0) {
        final newLink = SnakeLink.t(
          headLink.cellx + headLink.dir.vec.x, 
          headLink.celly + headLink.dir.vec.y, 
          headLink.dir.vec, 
          headLink.t);
        headLink.t = 1.0;
        links.addFirst(newLink);
        cells -= 1.0;
        continue;
      }
      else if (headLink.t + cells > 1) {
        // workaround of a nasty bug which caused invalid coordinates of newly 
        // created link (due to computation limitations of double variables)
        var newT = headLink.t + cells - 1.0;
        // newT = max(minimalDecrement(1000), newT);
        newT = max(0.0000000001, newT);

        final newLink = SnakeLink.t(
          headLink.cellx + headLink.dir.vec.x, 
          headLink.celly + headLink.dir.vec.y,  
          headLink.dir.vec, 
          newT);
       
        headLink.t = 1.0;

        links.addFirst(newLink);
        if (_futureTurns.isNotEmpty) {
          changeDirection(_futureTurns.first);
          _futureTurns.removeFirst();
        }
        break;
      }
      else {
        headLink.t += cells;
        break;
      }
    }

    if (_fruitsToDigest > 0) {
      if (_fruitsToDigest > tmpCells){
        cells = 0;
        _fruitsToDigest -= tmpCells;
      }
      else {
        cells = tmpCells - _fruitsToDigest;
        _fruitsToDigest = 0.0;
      }
    }
    else {
      cells = tmpCells;
    }

    while(cells > 0.0) {
      if (cells > 1.0) {
        final tt = tailLink.t;
        links.removeLast();
        tailLink.t = tt;
        cells -= 1.0;
        continue;
      }
      else if (tailLink.t + cells >= 2.0) {
        final newt =  1.0 + (tailLink.t + cells - 2.0);
        links.removeLast();
        tailLink.t = newt;
        break;
      }
      else {
        tailLink.t += cells;
        break;
      }
    }

  }


  void moveBackward(double cells) {
    _futureTurns.clear();
    final tmpCells = cells;
    
    while(cells > 0.0) {
      if (cells > 1.0) {
        final ht = headLink.t;
        links.removeFirst();
        headLink.t = ht;
        cells -= 1.0;
        continue;
      }
      else if (headLink.t - cells < 0.0) {
        final ht = 1.0 + headLink.t - cells;
        links.removeFirst();
        headLink.t = ht;
        break;
      }
      else {
        headLink.t -= cells;
        break;
      }
    }


    cells = tmpCells;
    while(cells > 0.0) {
      if (cells > 1.0) {
        final tt = tailLink.t;
        tailLink.t = 1.0;
        final newLink = SnakeLink.t(
          tailLink.cellx - tailLink.dir.prevVec.x,
          tailLink.celly - tailLink.dir.prevVec.y,
          tailLink.dir.prevVec, tt);
        links.addLast(newLink);
        cells--;
        continue;
      }
      else if (tailLink.t - cells < 1.0) {
        final tt = 1.0 + (tailLink.t - cells);
        tailLink.t = 1.0;
        final newLink = SnakeLink.t(
          tailLink.cellx - tailLink.dir.prevVec.x,
          tailLink.celly - tailLink.dir.prevVec.y,
          tailLink.dir.prevVec, tt);
        links.addLast(newLink);
        break;
      }
      else {
        tailLink.t -= cells;
        break;
      }
    }

  }



  @override
  void update(int timeDelta) {
    if (field.gamePaused) { 
      return;
    }

    double pathFraction = speed * (timeDelta / 1000);

    if (pathFraction > 0) {
      moveForward(pathFraction);
    } 
    else if (pathFraction < 0) {
      moveBackward(-pathFraction);
    }
  }

  
  void digestFruit() {
    _fruitsEaten++;
    _fruitsToDigest++;
    _snakePainter.digestFruit();
  }


  void animateCollision() {
    _snakePainter.collision();
  }


  void onWallCollision() {
    if (headLink.y.toInt() == 0) {
      headLink.y = field.height-2;
    }
    else if (headLink.y.toInt() == field.height-1) {
      headLink.y = 1.0;
    }
    else if (headLink.x.toInt() == 0) {
      headLink.x = field.width-2;
    }
    else if (headLink.x.toInt() == field.width-1) {
      headLink.x = 1.0;
    }
  }

  @override
  Iterable<Shape> get shapes => links;

}



class SnakePainter {
  SnakePainter(this.snake) {
    _snakePaint = Paint()
      ..color = snake.snakeColor1
      ..style = PaintingStyle.stroke
      ..isAntiAlias=true;

    _headPainter.headPaint.color = snake.snakeColor1;

    final eyelidColor = HSLColor.fromColor(snake.snakeColor1).withLightness(0.6).toColor();

    _headPainter.leftEye.topEyelidPaint.color =
      _headPainter.leftEye.bottomEyelidPaint.color =
      _headPainter.rightEye.topEyelidPaint.color =
      _headPainter.rightEye.bottomEyelidPaint.color = eyelidColor;

    _headPainter.leftEye.eyeCircuitPaint.color = snake.snakeColor1;
    _headPainter.rightEye.eyeCircuitPaint.color = snake.snakeColor1;

    final pupilColor = HSLColor.fromColor(snake.snakeColor1).withLightness(0.3).toColor();
    _headPainter.leftEye.pupilPaint.color = pupilColor;
    _headPainter.rightEye.pupilPaint.color = pupilColor;

    
    _headPainter.nostrilPaint.color = HSLColor.fromColor(snake.snakeColor1).withLightness(0.35).toColor();
    _headPainter.mouthPaint.color = HSLColor.fromColor(snake.snakeColor1).withLightness(0.3).toColor();
  }

  final Snake snake;
  final SnakeHeadPainter _headPainter = SnakeHeadPainter();
  late Paint _snakePaint;

  final _rand = Random.secure();

  AnimationController? showTongueAnimation;
  Animation<double>? tongueLength;
  Animation<double>? tongueAngle;

  AnimationController? mouthOpen;

  Animation<double>? leftEyeRatio;
  Animation<double>? rightEyeRatio;
  Animation<double>? leftPupilRatio;
  Animation<double>? rightPupilRatio;
  Animation<double>? leftEyeClosedRatio;
  Animation<double>? rightEyeClosedRatio;
  Animation<double>? headCompressionRatio;
  AnimationController? collisionAnimation;

  AnimationController? winkAnimation;

  Fountain? _fountain;
  Animation<double>? fountainAnim;

  Aftershock? _aftershock;
  Animation<double> ?aftershockAnim;
  
  AnimationController? collisionSparksAnimation;


  final List<SmoothVariable<double>> _fruitsToDigest = [];

  final _lookAngle = AnimatableVariable(0, 2*pi);
  int _winkLastTime = 0;
  int _showTongueLastTime = 0;
  
  

  set isPushing(bool val) {
    if(val) {
      headCompressionRatio = kAlwaysCompleteAnimation;
    } 
    else {
      headCompressionRatio = null;
    }
  }



  void collision() {
    if (collisionAnimation == null) {
      collisionAnimation = AnimationController(
          vsync: snake.field.tickerProvider!,
          duration: const Duration(milliseconds: 2000));
      collisionAnimation!.addStatusListener((status) {
        if(status == AnimationStatus.completed){
          collisionAnimation?.dispose();
          collisionAnimation = null;
          fountainAnim = null;
          _fountain = null;
          aftershockAnim = null;
          _aftershock = null;

        }
      });

      headCompressionRatio = SineSplineTween.fromArray(const [
        [0.0, 0],  [0.05, 1], [0.15, 1], [0.25, 0], [1, 0]
      ]).animate(collisionAnimation!);

      leftEyeRatio = SineTween(begin: 1, end: 0.8, ext1: 1.1, ext2: 0.8,
          periods: 4).animate(
          CurvedAnimation(
              parent: collisionAnimation!,
              curve: const Interval(0.5, 1)));

      rightEyeRatio = SineTween(begin: 1, end: 1.1, ext1: 0.8, ext2: 1.1,
          periods: 3).animate(          CurvedAnimation(
          parent: collisionAnimation!,
          curve: const Interval(0.5, 1)));


      leftEyeClosedRatio = SineSplineTween.fromArray(const [
        [0, 0],  [1, 1], [3, 1], [4, 0], [4.5, 1], [5, 0],
      ]).animate(collisionAnimation!);


      rightEyeClosedRatio = SineSplineTween.fromArray(const [
        [0, 0],  [1, 1], [3, 1], [4, 0], [4.5, 1], [5, 0], [6,0.9],
      ]).animate(collisionAnimation!);

      _headPainter.rightEye.lookAt = null;

      rightPupilRatio = SineSplineTween.fromArray([
        [0, 1], [0.2, 1.2], [0.5, 0.7]
      ]).animate(collisionAnimation!);
      // _headPainter.eyeBridgeRatio = 0.85;

    }

    if(collisionAnimation!.isCompleted) {
      collisionAnimation!.reset();
    }

    collisionAnimation!.forward();
  }


  void showTongue(int durationMs) {
    if(showTongueAnimation == null) {
      showTongueAnimation = AnimationController(
          vsync: snake.field.tickerProvider!,
          duration: Duration(milliseconds: durationMs));

      tongueLength = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
        TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0), weight: 1),
      ]).animate(showTongueAnimation!);


      final shakeTongueTween = SineTween(
          begin: 0, end: 0,
          ext1: pi/16, ext2: -pi/16,
          periods: 3);

      tongueAngle = TweenSequence<double>([
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
        TweenSequenceItem(tween: shakeTongueTween , weight: 5),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
      ]).animate(showTongueAnimation!);
    }

    showTongueAnimation?.reset();
    showTongueAnimation?.forward();
  }


  void hideTongue() {
    showTongueAnimation?.reset();
  }


  void openMouth(Duration duration) {
    mouthOpen ??= AnimationController(
          vsync: snake.field.tickerProvider!,
          duration: duration);

    if (mouthOpen?.status == AnimationStatus.dismissed) {
      mouthOpen?.duration = duration;
      mouthOpen?.forward();
    }
  }


  void closeMouth(Duration duration) {
    if (mouthOpen?.status != AnimationStatus.dismissed) {
      mouthOpen?.reverseDuration = duration;
      mouthOpen?.reverse();
    }
  }


  bool get isMouthOpen => mouthOpen?.status != AnimationStatus.dismissed;


  void wink(bool leftEye, bool rightEye, [
    Duration duration = const Duration(milliseconds: 500)]) {
    if(!(leftEye || rightEye)) return;

    if (winkAnimation == null) {
      winkAnimation = AnimationController(
          vsync: snake.field.tickerProvider!,
          duration: duration);
      winkAnimation!.addStatusListener((status) {
        if (status == AnimationStatus.completed){
          winkAnimation!.dispose();
          winkAnimation = null;
        }
      });

      final eyeClosedTween = TweenSequence([
        TweenSequenceItem(tween: Tween<double>(begin:0.0, end:0.99), weight: 1.5),
        TweenSequenceItem(tween: ConstantTween(0.99), weight: 2),
        TweenSequenceItem(tween: Tween<double>(begin:0.99, end:0.0), weight: 1),
      ]);

      leftEyeClosedRatio = leftEye ? eyeClosedTween.animate(winkAnimation!) : null;
      rightEyeClosedRatio = rightEye ? eyeClosedTween.animate(winkAnimation!) : null;
    }

    winkAnimation?.reset();
    winkAnimation?.forward();
    _winkLastTime = DateTime.now().millisecondsSinceEpoch;
  }


  Fruit? _getNearestFruit() {
    Fruit? fruit;
    double distance = double.negativeInfinity;

    final snakeHeadOffset = Offset(snake.headLink.x, snake.headLink.y);

    for (var item in snake.field.items) {
      if (item is! Fruit) continue;

      final fruitOffset = Offset(item.x, item.y);
      final diff = snakeHeadOffset - fruitOffset;
      final dist = diff.distanceSquared;

      if ((fruit == null) || (dist < distance)) {
        fruit = item;
        distance = dist;
      }
    }

    return  fruit;
  }


  double _calcSnakeLinkThickness(int linkIndex, int linksTotal) {
    assert(linkIndex >= 0);
    assert(linkIndex < linksTotal);
    assert(linksTotal >= 4);

    const maxRatio = 0.85  ;
    const minRatio = 0.65;
    
    if (linkIndex <= 1) {
      return maxRatio;
    }

    if (linksTotal <= 20) {
      return lerp(maxRatio, minRatio, (linkIndex-1) / 20);
    }

    return lerp(maxRatio, minRatio, (linkIndex-1) / (linksTotal-2));
  }


  Color _calcSnakeLinkColor(ColorTween tween, int linkIndex, int linksTotal) {
    assert(linkIndex >= 0);
    assert(linkIndex <= linksTotal);
    assert(linksTotal >= 4);

    if (linkIndex <= 1) {
      return tween.transform(0.0)!;
    }

    if (linksTotal <= 20) {
      return tween.transform((linkIndex-2) / 20)!;
    }

    return tween.transform((linkIndex-2) / (linksTotal-2))!;
  }


  // Offset _pointOnSnake(Size worldSize, double position) {
  //   assert(position >= 0.0  && position <= 1.0);
  //   final int snakeLength = snake.links.length;
  //   final linkIndexD = (snakeLength-1) * position - snake.headLink.t + 1;
  //   final int linkIndex = linkIndexD.truncate();
  //   final SnakeLink link = snake.links.elementAt(linkIndex);
  //   final Rect linkRect = snake.field.cellToWorld(link.cellx, link.celly, worldSize);
  //   final t = linkIndexD - linkIndex;
  //   return link.dir.interpolate(linkRect, 1.0-t);
  // }


  void _drawDigestingFruit(Canvas canvas, Size worldSize, double position) {
    assert(position >= 0.0  && position <= 1.0);

    final int snakeLength = snake.links.length;

    final begin = 1.0/snakeLength;
    const end = 2.2 / 3.0;
    position = lerp(begin, end, position);

    final linkIndexD = (snakeLength-1) * position - snake.headLink.t + 1;  
    final int linkIndex = linkIndexD.truncate();
    final SnakeLink link = snake.links.elementAt(linkIndex);
    final Rect linkRect = snake.field.cellToWorld(link.cellx, link.celly, worldSize);
    final t = linkIndexD - linkIndex;
    final Offset center = link.dir.interpolate(linkRect, 1.0-t);
    
    final double fruitRadus = linkRect.width * 
      _calcSnakeLinkThickness(linkIndex, snakeLength) * lerp(0.85, 0.45, position); 
    
    final color = _calcSnakeLinkColor(
      ColorTween(begin: snake.snakeColor1, end: snake.snakeColor2), 
      linkIndex, 
      snakeLength);

    canvas.drawCircle(
      center, 
      fruitRadus, 
      Paint()..color = color);
  }


  void digestFruit() {
    final double linksToDigest = snake.links.length * (2.2/3.0);
    final speed = snake.speed != 0 ? snake.speed*2 : 5.0;
    double timeToDigest = linksToDigest / speed * 1000;
    _fruitsToDigest.add(SmoothVariable.active(0.0, 1.0, Duration(milliseconds: timeToDigest.toInt())));
  }


  

  void draw(Canvas canvas, Size canvasSize) {
    // the first two links are the snake's head
    // the last two links are the snakes tail

    // int i=0;
    // for(final l in snake.links) {
    //   final col = i == 0 ? Colors.red : Colors.blue.withAlpha(100);
    //   final r = snake.field.rectToWorld(l);
    //   canvas.drawRect(r, Paint()..color=col);
    //   i++;
    // }

    // return;

    final colorTween = ColorTween(begin: snake.snakeColor1, end: snake.snakeColor2);

    _drawTail(
      canvas, canvasSize, 
      _calcSnakeLinkThickness(snake.links.length-2, snake.links.length),
      _calcSnakeLinkColor(colorTween, snake.links.length-2, snake.links.length));

    var snakeLinkEntry = snake.links.lastEntry()!.previousEntry()!.previousEntry();
    for (int i=snake.links.length-3; i>=2; i--, snakeLinkEntry = snakeLinkEntry .previousEntry()) {
      final snakeLink = snakeLinkEntry!.element;
      final col1 = _calcSnakeLinkColor(colorTween, i, snake.links.length);
      final col2 = _calcSnakeLinkColor(colorTween, i+1, snake.links.length);
      final widthRatio = _calcSnakeLinkThickness(i, snake.links.length);
      _drawLink(canvas, canvasSize, snakeLink, widthRatio, color1:col1, color2:col2);
      // _drawLink2(canvas, canvasSize, snakeLink, i, colorTween);
    }

    for (int i =0; i<_fruitsToDigest.length; i++) {
      _drawDigestingFruit(canvas, canvasSize, _fruitsToDigest[i].value);
    }

    _fruitsToDigest.removeWhere((element) => element.value >= 0.999);

    _headPainter.tongueMaxLength = snake.field.cellToWorld(0, 0).width;
    _headPainter.tongueLength = tongueLength?.value ?? -1.0;
    _headPainter.tongueAngle = tongueAngle?.value ?? 0.0;
    _headPainter.mouthOpened = mouthOpen?.value ?? 0.0;

    if (leftEyeRatio != null) _headPainter.leftEye.eyeRatio = leftEyeRatio!.value;

    if (rightEyeRatio != null) _headPainter.rightEye.eyeRatio = rightEyeRatio!.value;

    if (leftEyeClosedRatio != null) _headPainter.leftEye.eyelidsClosedRatio = leftEyeClosedRatio!.value;

    if (rightEyeClosedRatio != null) _headPainter.rightEye.eyelidsClosedRatio = rightEyeClosedRatio!.value;

    if (leftPupilRatio != null) _headPainter.leftEye.pupilRatio = leftPupilRatio!.value;

    if (rightPupilRatio != null) _headPainter.rightEye.pupilRatio = rightPupilRatio!.value;

    if (headCompressionRatio != null) _headPainter.headCompression = headCompressionRatio!.value;


      final nearestFruit = _getNearestFruit();
      if (nearestFruit != null && snake.speed >= 0.0) {
        final hx = (snake.headLink.right + snake.headLink.left) / 2.0;
        final hy = (snake.headLink.bottom + snake.headLink.top) / 2.0;
        double lookAng = atan2(nearestFruit.y - hy, nearestFruit.x - hx);
        if ( (_headPainter.leftEye.lookAngle != null) &&
             (lookAng - _headPainter.leftEye.lookAngle!).abs() > pi) {
          lookAng += lookAng < 0 ? pi*2 : -2*pi;
        }

        _lookAngle.animateTo(lookAng);
        _headPainter.leftEye.lookAngle = _lookAngle.value;
        _headPainter.rightEye.lookAngle = _lookAngle.value;


        final dx = (nearestFruit.x - snake.headLink.x-0.5);
        final dy = (nearestFruit.y - snake.headLink.y-0.5);
        final md = sqrt(dx*dx + dy*dy)-1.0; // distance to the nearest fruit
        final treq = max(0.1, md / (snake.speed == 0.0 ? 1 : snake.speed));

        if(treq <= 0.3) {
          // TODO: update algorithm
          final duration = Duration(milliseconds: (treq * 400.0).toInt());
          openMouth(duration);
        }
        else{
          closeMouth(const Duration(milliseconds: 400));
        }
      }
      else {
        closeMouth(const Duration(milliseconds: 300));
      }

    _drawHead(
        canvas, canvasSize,
        _calcSnakeLinkThickness(0, snake.links.length),
        _calcSnakeLinkColor(colorTween, 0, snake.links.length));



    if (collisionAnimation != null) {
      if (_fountain == null) {
        final headRect = snake.field.cellToWorld(snake.headLink.cellx, snake.headLink.celly, canvasSize);
        _fountain = Fountain(
            particleCount: 20,
            particleSize: Size(headRect.width/2, headRect.width/2),
            aperture: headRect.center,
            apertureSize: headRect.width * 2,
            direction: Offset(-snake.headLink.dir.vec.x, -snake.headLink.dir.vec.y),
            heightMin: headRect.width * 2,
            heightMax: headRect.width * 6);
        fountainAnim =
            Tween<double>(begin: 0, end: 1).animate(collisionAnimation!);

      }

      _fountain?.draw(canvas, fountainAnim!.value);
    }

    if (collisionAnimation != null) {
      if (_aftershock == null) {
        final headRect = snake.field.cellToWorld(snake.headLink.cellx, snake.headLink.celly, canvasSize);
        _aftershock = Aftershock(headRect.inflate(100), particleCount:10, particleSize:headRect.width*0.5);
        aftershockAnim = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
                parent: collisionAnimation!,
                curve: const Interval(0.3, 1)));
      }
      _aftershock?.draw(canvas, aftershockAnim!.value);
    }




    int curTime = DateTime.now().millisecondsSinceEpoch;

    if (collisionAnimation == null) {
      if (curTime - _winkLastTime >= 2000) {
        if (_rand.nextInt(2) == 0) {
          wink(true, true);
        }
        _winkLastTime = curTime;
      }

      if (curTime - _showTongueLastTime >= 5000 && !isMouthOpen) {
        if (_rand.nextInt(2) == 0) {
          showTongue(1000);
        }
        _showTongueLastTime = curTime;
      }
    }

  }

  void _drawLine(Canvas canvas, Rect rect, SnakeDir dir, double t, Paint paint){
    final li = _LineInterpolation(dir, rect, t);
    canvas.drawLine(li.p1, li.p2, paint);
  }


  void _drawArc(Canvas canvas, Rect rect, SnakeDir dir, double t, Paint paint) {
    final p = _ArcInterpolation(dir, rect, t);
    canvas.drawArc(p.rect, p.startAngle, p.sweepAngle, false, paint);
  }


  // void _drawLink(Canvas canvas, Size worldSize,
  //     SnakeLink snakeLink, double snakeThicknessPercent,
  //     {Color? color1, Color? color2,  bool inverted = false, double? t}) {

  //   assert( t==null || (t >= 0.0 && t <= 2.0));
  //   var rect = snake.field.cellToWorld(snakeLink.cellx, snakeLink.celly, worldSize);
  //   if (snakeLink.dir.isHorizontal) {
  //     rect = Rect.fromLTRB(rect.left-0.2, rect.top, rect.right+0.2, rect.bottom);
  //   }
  //   else if (snakeLink.dir.isVertical) {
  //     rect = Rect.fromLTRB(rect.left, rect.top-0.2, rect.right, rect.bottom+0.2);
  //   }
  //   else {
  //     rect = rect.inflate(0.2);
  //   }

  //   _snakePaint.strokeWidth = rect.width * snakeThicknessPercent;

  //   if (color1 != null || color2 != null) {
  //     if (color1 == color2) {
  //       _snakePaint.color = color1!;
  //       _snakePaint.shader = null;
  //     }
  //     else {
  //       _snakePaint.shader = LinearGradient(
  //         begin: Alignment(snakeLink.dir.vec.x.toDouble(), snakeLink.dir.vec.y.toDouble()),
  //           end: Alignment(-snakeLink.dir.vec.x.toDouble(), -snakeLink.dir.vec.y.toDouble()),
  //           colors:[color1!, color2!]
  //       ).createShader(rect);
  //     }
  //   }

  //   final dir = inverted ? snakeLink.dir.inverted : snakeLink.dir;

  //   t ??= snakeLink.t;

  //   if (dir.vec == dir.prevVec) {
  //     _drawLine(canvas, rect, dir, t, _snakePaint);
  //   }
  //   else {
  //     _drawArc(canvas, rect, dir, t, _snakePaint);
  //   }
  // }



  void _drawLink(Canvas canvas, Size worldSize,
      SnakeLink snakeLink, double snakeThicknessPercent,
      {Color? color1, Color? color2,  double? t}) {

    assert( t==null || (t >= 0.0 && t <= 2.0));
    var rect = snake.field.cellToWorld(snakeLink.cellx, snakeLink.celly, worldSize);
    if (snakeLink.dir.isHorizontal) {
      rect = Rect.fromLTRB(rect.left-0.2, rect.top, rect.right+0.2, rect.bottom);
    }
    else if (snakeLink.dir.isVertical) {
      rect = Rect.fromLTRB(rect.left, rect.top-0.2, rect.right, rect.bottom+0.2);
    }
    else {
      rect = rect.inflate(0.2);
    }

    _snakePaint.strokeWidth = rect.width * snakeThicknessPercent;

    if (color1 != null || color2 != null) {
      if (color1 == color2) {
        _snakePaint.color = color1!;
        _snakePaint.shader = null;
      }
      else {
        _snakePaint.shader = LinearGradient(
          begin: Alignment(snakeLink.dir.vec.x, snakeLink.dir.vec.y),
            end: Alignment(-snakeLink.dir.vec.x, -snakeLink.dir.vec.y),
            colors:[color1!, color2!]
        ).createShader(rect);
      }
    }

    t ??= snakeLink.t;

    if (snakeLink.dir.vec == snakeLink.dir.prevVec) {
      _drawLine(canvas, rect, snakeLink.dir, t, _snakePaint);
    }
    else {
      _drawArc(canvas, rect, snakeLink.dir, t, _snakePaint);
    }
  }


  void _drawTail(Canvas canvas, Size worldSize, double snakeThicknessPercent, Color color) {
    final tailPaint = Paint()..color=color..style=PaintingStyle.fill;

    final tailLink = snake.links.last;
    final prevLink = snake.links.lastEntry()!.previousEntry()!.element;

    Rect tailRect = snake.field.cellToWorld(tailLink.cellx, tailLink.celly, worldSize);
    Rect prevTailRect = snake.field.cellToWorld(prevLink.cellx, prevLink.celly, worldSize);

    final thicknessInPixels = (tailRect.width) * snakeThicknessPercent;

    double t = (snake.tailLink.t + snakeThicknessPercent/2);

    if(t <= 2) {
      canvas.drawCircle(tailLink.dir.interpolate(tailRect, t), thicknessInPixels / 2, tailPaint);
      _drawLink(canvas, worldSize, tailLink, snakeThicknessPercent, color1:color, color2:color, t: t);
      _drawLink(canvas, worldSize, prevLink, snakeThicknessPercent, color1:color, color2:color);
    }
    else {
      t = 1 + (t - 2);
      canvas.drawCircle(prevLink.dir.interpolate(prevTailRect, t), thicknessInPixels / 2, tailPaint);
      _drawLink(canvas, worldSize, prevLink, snakeThicknessPercent, color1:color, color2:color, t: t);
    }
  }


  double _calcHeadAngle(SnakeLink link, double t) {
    const halfPi = pi / 2.0;
    if (link.dir.vec == link.dir.prevVec) {
      if (link.dir.vec == SnakeDir.east) return 0.0;
      if (link.dir.vec == SnakeDir.west) return pi;
      if (link.dir.vec == SnakeDir.north) return -halfPi;
      if (link.dir.vec == SnakeDir.south) return halfPi;
    }
    else {
      final a = _ArcInterpolation._map[SnakeDir.two(link.dir.vec, -link.dir.prevVec)];
      if (a == null) {
        throw Exception('Invalid direction');
      }

      if (t <= 1.0) {
        return a.startAngle + a.sweepAngle * t;
      } 
      else {
        return a.startAngle + a.sweepAngle * (1 - t) ;
      }
    }

    return 0;
  }


  void _drawHead(Canvas canvas, Size worldSize, double snakeThicknessPercent, Color color) {

    final headLink = snake.links.first;
    final nextLink = snake.links.firstEntry()!.nextEntry()!.element;

    Rect headRect = snake.field.cellToWorld(headLink.cellx, headLink.celly, worldSize);
    Rect nextRect = snake.field.cellToWorld(nextLink.cellx, nextLink.celly, worldSize);

    final thicknessInPixels = (headRect.width) * snakeThicknessPercent;
    double t = (snake.headLink.t - snakeThicknessPercent/2);

    _headPainter.headWidth = _headPainter.headHeight = thicknessInPixels;

    if (t >= 0){
      // draw whole next link
      _drawLink(canvas, worldSize, nextLink, snakeThicknessPercent,
          color1:color, color2: color);

      _drawLink(canvas, worldSize, headLink, snakeThicknessPercent,
          color1: color, color2: color, t: t);

      _headPainter.headCenter = headLink.dir.interpolate(headRect, t);
      _headPainter.headAngle = _calcHeadAngle(snake.headLink, t);
    }
    else {
      t = 1 - (-t);
      _drawLink(canvas, worldSize, nextLink, snakeThicknessPercent,
        color1: color, color2: color, t:t);
      _headPainter.headCenter = nextLink.dir.interpolate(nextRect, 1+t);
      _headPainter.headAngle = _calcHeadAngle(nextLink, t);
    }

    _headPainter.paint(canvas, worldSize);
  }


}



class EyeParams {

  Paint eyeCircuitPaint = Paint()..color = Colors.indigo;

  Paint eyePaint = Paint()..color = Colors.white;
  double eyeRatio = 1;

  Paint topEyelidPaint = Paint()..color = Colors.indigo.shade400;
  double topEyelidClosedRatio = 0;

  Paint bottomEyelidPaint = Paint()..color = Colors.indigo.shade400;
  double bottomEyelidClosedRatio = 0;

  Paint pupilPaint = Paint()..color = Colors.indigo.shade900;
  double pupilRatio = 1;

  Offset? lookAt;

  double? lookAngle;

  set eyelidsClosedRatio(double t) {
    topEyelidClosedRatio = bottomEyelidClosedRatio = t;
  }

}



class SnakeHeadPainter {

  double headWidth = 100;
  double headHeight = 100;
  Offset headCenter = const Offset(50, 50);
  double headCompression = 0;

  double headAngle = 0;

  double tongueMaxLength = 60.0;
  double tongueLength = 00.0;
  double tongueThickness = -1.0;
  double tongueAngle = 0.0;
  Paint tonguePaint = Paint()..color = Colors.red;

  Paint headPaint = Paint()..color = Colors.indigo;

  EyeParams leftEye = EyeParams();
  EyeParams rightEye = EyeParams();
  double eyeBridgeRatio = 0.7;

  double mouthOpened = 0.0;
  Paint mouthPaint = Paint()..color = Colors.indigo.shade900;

  Paint nostrilPaint = Paint()..color = Colors.indigo.shade900;
  Paint toothPaint = Paint()..color = Colors.indigo.shade100;


  void setColor(Color color) {
    final hsl = HSLColor.fromColor(color);

    headPaint.color = color;
    nostrilPaint.color = HSLColor.fromColor(color).withLightness(0.35).toColor();

    leftEye.eyeCircuitPaint.color = color;
    rightEye.eyeCircuitPaint.color = color;

    final pupilColor = HSLColor.fromAHSL(
      1.0, 
      hsl.hue, 
      hsl.saturation, 
      max(hsl.lightness - 0.3, 0.0)).toColor();

    leftEye.pupilPaint.color = pupilColor;
    rightEye.pupilPaint.color = pupilColor;


    final eyelidColor = HSLColor.fromAHSL(
      1.0, 
      hsl.hue, 
      hsl.saturation, 
      min(hsl.lightness + 0.2, 1.0)).toColor();

    leftEye.topEyelidPaint.color = eyelidColor;
    leftEye.bottomEyelidPaint.color = eyelidColor;
    rightEye.topEyelidPaint.color = eyelidColor;
    rightEye.bottomEyelidPaint.color = eyelidColor;

  }


  void _paintTongue(Canvas canvas, Offset startPoint, double tongueLength) {
    if (tongueLength <= 0) return;

    Offset sp = startPoint;

    final tongueThickness = this.tongueThickness > 0
        ? this.tongueThickness
        : headHeight / 4;

    final List<Offset> pts = [
      Offset(sp.dx, sp.dy - tongueThickness/4),
      Offset(sp.dx + tongueLength, sp.dy - tongueThickness/2),
      //
      Offset(sp.dx + tongueLength - tongueMaxLength / 10, sp.dy),
      //
      Offset(sp.dx + tongueLength, sp.dy + tongueThickness/2),
      Offset(sp.dx, sp.dy + tongueThickness/4),
    ];

    Path path = Path();
    path.addPolygon(pts, true);
    if (tongueAngle == 0.0) {
      canvas.drawPath(path, tonguePaint);
    }
    else {
      canvas.save();
      canvas.translate(sp.dx, sp.dy);
      canvas.rotate(-tongueAngle);
      canvas.translate(-sp.dx, -sp.dy);
      canvas.drawPath(path, tonguePaint);
      canvas.restore();
    }
  }


  void _paintMouth(Canvas canvas, Rect rect) {

    final innerMouthRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width*0.9,
      height: rect.height*0.8
    );

    canvas.drawOval(innerMouthRect, mouthPaint);

    final lidWidth = lerp(rect.width, rect.width*0.6, mouthOpened);
    final lidHeight = lerp(rect.height, rect.height *1.3, mouthOpened);

    final mouthLid = Rect.fromLTWH(
        rect.left + rect.width * 0.1 * mouthOpened,
        rect.centerLeft.dy - lidHeight/2,
        lidWidth,
        lidHeight);

    if (tongueLength > 0) {
      _paintTongue(
        canvas, 
        mouthLid.centerRight, 
        tongueLength * tongueMaxLength + (rect.right - mouthLid.right));
    }

    final toothLength = (mouthLid.width/2) * 0.5 * mouthOpened;
    final tooth1Point1 = Offset (
        mouthLid.center.dx + cos(-pi/6) * (mouthLid.width/2),
        mouthLid.center.dy + sin(-pi/6) * (mouthLid.height/2)) ;

    final toothPath = Path();
    toothPath.addPolygon([
      tooth1Point1,
      tooth1Point1.translate(0, mouthLid.height * 0.15),
      tooth1Point1.translate(toothLength, mouthLid.height * 0.07)
    ], true);
    canvas.drawPath(toothPath, toothPaint);

    final tooth1Point2 = Offset (
        mouthLid.center.dx + cos(pi/6) * (mouthLid.width/2),
        mouthLid.center.dy + sin(pi/6) * (mouthLid.height/2)) ;

    final toothPath2 = Path();
    toothPath2.addPolygon([
      tooth1Point2,
      tooth1Point2.translate(0, -mouthLid.height * 0.15),
      tooth1Point2.translate(toothLength, -mouthLid.height * 0.07)
    ], true);
    canvas.drawPath(toothPath2, toothPaint);

    canvas.drawOval(mouthLid, headPaint);

    final nostril1Center = Offset (
      mouthLid.center.dx + cos(-pi*0.33) * (mouthLid.width/2) * 0.7,
      mouthLid.center.dy + sin(-pi*0.33) * (mouthLid.height/2) * 0.7) ;

    final nostril2Center = Offset (
        mouthLid.center.dx + cos(pi*0.35) * (mouthLid.width/2) * 0.7,
        mouthLid.center.dy + sin(pi*0.35) * (mouthLid.height/2) * 0.7) ;

    // canvas.drawCircle(nostril1Center, mouthLid.width * 0.06, nostrilPaint);
    // canvas.drawCircle(nostril2Center, mouthLid.width * 0.06, nostrilPaint);

    canvas.save();
    final r = Rect.fromCenter(
      center: Offset.zero, 
      width: mouthLid.width * 0.14, 
      height: mouthLid.height * 0.09
    );
    canvas.translate(nostril1Center.dx,  nostril1Center.dy);
    canvas.rotate(pi*0.2);
    canvas.drawOval(r, nostrilPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(nostril2Center.dx,  nostril2Center.dy);
    canvas.rotate(-pi*0.2);
    canvas.drawOval(r, nostrilPaint);
    canvas.restore();

  }


  void _paintEye(Canvas canvas, Rect eyeRect, EyeParams p) {

    // draw circles around eyes
    canvas.drawOval(eyeRect, p.eyeCircuitPaint);

    // draw eye
    final whiteRect = Rect.fromCenter(
        center: eyeRect.center,
        width: eyeRect.width * 0.8,
        height: eyeRect.height * 0.8);

    canvas.drawOval(whiteRect, p.eyePaint);

    // calc pupil location
    final pupilRadius = whiteRect.height / 2 * (0.6 * p.pupilRatio);
    final dd = whiteRect.height/2 - pupilRadius - 1;
    var pupilCenterDX = dd, pupilCenterDY = 0.0;
    if(p.lookAngle != null) {
      final lookAng = p.lookAngle! - headAngle;
      pupilCenterDX = (cos(lookAng)) * (dd);
      pupilCenterDY = (sin(lookAng)) * (dd);
    }

    // draw pupils
    canvas.drawCircle(whiteRect.center.translate(pupilCenterDX, pupilCenterDY), 
    pupilRadius, p.pupilPaint);

    // draw eyelids
    const topLidStartAngle = pi * 0.4;
    const topLidEndAngle = (2 * pi) - topLidStartAngle;

    const bottomLidStartAngle = topLidStartAngle;
    // const bottomLidEndAngle = topLidEndAngle;

    const tolerance = 0.00001;
    var startAngle =
      lerp(topLidStartAngle, pi, (1-p.topEyelidClosedRatio));
    var sweepAngle =
        (topLidEndAngle - topLidStartAngle) * p.topEyelidClosedRatio;
    if (p.topEyelidClosedRatio > tolerance) {
      // for some reason canvas.drawArc draws transparent circle
      // when sweepAngle is very small (like 0.0000001)
      canvas.drawArc(
          whiteRect.inflate(0.5), startAngle, sweepAngle, false, p.topEyelidPaint);
    }

    startAngle =
        lerp(bottomLidStartAngle, 0, (1-p.bottomEyelidClosedRatio));
    sweepAngle = - startAngle * 2;
    if (p.bottomEyelidClosedRatio > tolerance) {
      canvas.drawArc(
          whiteRect.inflate(0.5), startAngle, sweepAngle, false, p.bottomEyelidPaint);
    }

  }


  void _paintHead(Canvas canvas, Rect rect) {
    // draw head
    final headWidthRatio =lerp(1.1, 0.8, headCompression);
    final headHeightRatio =lerp(1.03, 1.6, headCompression);

    final headRect = Rect.fromLTWH(
        rect.left + (rect.width - rect.width * headWidthRatio),
        rect.top + ((rect.height - rect.height * headHeightRatio) / 2),
        rect.width * headWidthRatio,
        rect.height * headHeightRatio);

    canvas.drawOval(headRect, headPaint);

    // draw mouth
    _paintMouth(canvas, headRect);

    // draw eyes
    _paintEye(canvas, Rect.fromCenter(
        center: Offset(headRect.left, headRect.center.dy - (rect.height/2) * eyeBridgeRatio ),
        width: rect.width * (0.7 * leftEye.eyeRatio),
        height: rect.width * (0.7 * leftEye.eyeRatio)), leftEye);

    _paintEye(canvas, Rect.fromCenter(
        center: Offset(headRect.left, headRect.center.dy + (rect.height/2) * eyeBridgeRatio ),
        width: rect.width * (0.7 * rightEye.eyeRatio),
        height: rect.width * (0.7 * rightEye.eyeRatio)) , rightEye);

  }


  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(headCenter.dx, headCenter.dy);
    canvas.rotate(headAngle);
    canvas.translate(-headCenter.dx, -headCenter.dy);

    final headRect = Rect.fromCenter(
        center: headCenter,
        width: headWidth,
        height: headHeight);

    _paintHead(canvas, headRect);
    canvas.restore();
  }

}


