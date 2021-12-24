
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart' show Vector2;


abstract class Shape{

  RectShape get toRect;

  bool? _overlaps(Shape other);

  bool? overlaps(Shape other) {
    return _overlaps(other) ?? other._overlaps(this);
  }
}



class RectShape extends Shape {
  RectShape(this.x, this.y, this.width, this.height);
    // : assert(width > 0),
    //   assert(height > 0);

  double x;
  double y;
  double width;
  double height;

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;


  void set(double x, double y, double width, double height) {
    assert(width >= 0);
    assert(height >= 0);
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  void resize(double width, double height) {
    assert(width >= 0);
    assert(height >= 0);
    this.width = width;
    this.height = height;
  }

  void shift(Vector2 v) {
    x += v.x;
    y += v.y;
  }

  RectShape shifted(Vector2 v) {
    return RectShape(x + v.x, y + v.y, width, height);
  }


  RectShape inflated(double dw, double dh) {
    return RectShape(x - dw / 2, y - dh/2, width+dw, height+dh);
  }

  @override
  RectShape get toRect => this;


  static bool rectOverlaps(RectShape r1, RectShape r2) {
    bool b = 
      (r1.right <= r2.left) ||
      (r2.right <= r1.left) ||
      (r1.bottom <= r2.top) ||
      (r2.bottom <= r1.top);

    return !b && (r1.width > 0) && (r1.height > 0) && (r2.width > 0) && (r2.height > 0);
  }


  @override
  bool? _overlaps(Shape other) {
    if (other is RectShape) {
      return rectOverlaps(this, other);
    }

    return null;
  }

  @override
  String toString() => ('$runtimeType Rect {$x, $y} {$right, $bottom}');
}



class CircleShape extends Shape {
  CircleShape(this.x, this.y, this.radius)
    : assert(radius > 0);

  double x;
  double y;
  double radius;

  Vector2 get center => Vector2(x, y);

  void shift(Vector2 v) {
    x += v.x;
    y += v.y;
  }

  @override
  RectShape get toRect => RectShape(x-radius, y-radius, radius+radius, radius+radius);

  static bool circleOverlaps(CircleShape s1, CircleShape s2) {
    final dx = s1.x - s2.x;
    final dy = s1.y - s2.y;
    final magnitudeSquared = dx*dx + dy*dy;
    final radiusSquared = (s1.radius+s2.radius) * (s1.radius+s2.radius);
    return magnitudeSquared < radiusSquared;
  }

  static bool rectCircleOverlaps(RectShape r, CircleShape c) {
    final px = c.x.clamp(r.x, r.x + r.width);
    final py = c.y.clamp(r.y, r.y + r.height);

    final dx = px - c.x;
    final dy = py - c.y;

    final magnitudeSquared = dx*dx + dy*dy;
    final radiusSquared = c.radius * c.radius;
    return magnitudeSquared < radiusSquared;
  }



  @override
  bool? _overlaps(Shape other) {
    if (other is RectShape) {
      return rectCircleOverlaps(other, this);
    }

    if (other is CircleShape) {
      return circleOverlaps(this, other);
    }

    return null;
  }
}



abstract class  GameObject {

  Iterable<Shape> get shapes;
  Vector2 get vel => Vector2.zero();


  void onMounted() {}

  void onDismounted() {}

  void onKeyDown(RawKeyEvent event) {}

  void onPanUpdate(DragUpdateDetails details) {}

  void onPanStart(DragStartDetails details) { }

  void onPanEnd(DragEndDetails details) { }

  void onDoubleTap() { }

  void update(int timeDelta) { }


  void paint(Canvas canvas, Size worldSize);


  bool collide(GameObject other) {
    for(final s1 in shapes) {
      for (final s2 in other.shapes) {
        if(s1.overlaps(s2) ?? false) {
          return true;
        }
      }
    }
    return false;
  }


  Iterable<Collision> collisions(GameObject other) sync* {
    for (final shape in shapes) {
      for (final otherShape in other.shapes) {
        // final ci = shapeCollision(shape, vel, otherShape, other.vel);
        if (shape.overlaps(otherShape) ?? false) {
          yield Collision(this, shape, other, otherShape);
        }
      }
    }
  }

}



class Collision {
  Collision(this.o1, this.shape1, this.o2, this.shape2);
  
  GameObject o1;
  Shape shape1;
  GameObject o2;
  Shape shape2;
}



