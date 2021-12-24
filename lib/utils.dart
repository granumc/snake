
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



double rad2deg(double rad) => (360.0 / (2.0 * pi)) * rad;


double deg2rad(double deg) => ((2.0 * pi) / 360.0) * deg;


double angleToOXSigned(Offset vector) => atan2(vector.dy, vector.dx);


// Returns the angle between vectors v1 and v2 in radians.
double angle(Offset v1, Offset v2) {
  if (v1.dx == v2.dx && v1.dy == v2.dy) {
    return 0.0;
  }

  final dot = (v1.dx * v2.dx) + (v1.dy * v2.dy);
  final l1 = sqrt((v1.dx * v1.dx) + (v1.dy * v1.dy));
  final l2 = sqrt((v2.dx * v2.dx) + (v2.dy * v2.dy));
  final d = dot / (l1 * l2);
  return acos(d.clamp(-1.0, 1.0));
}


// Returns the signed angle between vectors v1 and v2 in radians.
double angleSigned(Offset v1, Offset v2) {
  if (v1.dx == v2.dx && v1.dy == v2.dy) {
    return 0.0;
  }

  final cross = (v1.dx * v2.dy) - (v1.dy * v2.dx)  ;
  final dot = (v1.dx * v2.dx) + (v1.dy * v2.dy);

  return atan2(cross, dot);
}



Offset vectorRotate(Offset vector, double angle, [bool clockwise=true]) {
  late Offset res;

  if (clockwise) {
    res = Offset(vector.dx * cos(angle) + vector.dy * sin(angle),
        -vector.dx * sin(angle) + vector.dy * cos(angle));
  } else {
    res = Offset(vector.dx * cos(angle) - vector.dy * sin(angle),
        vector.dx * sin(angle) + vector.dy * cos(angle));
  }

  return res;
}


double lerp(double a, double b, double t) => a + (b - a) * t;

// interval interpolation (by analogy with lerp)
// interpolates value between a and b
double slerp(double a, double b, double ta, double tb, double t) {
  //   |
  // b |       /------
  //   |      /
  // a |-----/
  //   |
  //   +------------------
  //   0    ta  tb    1

  if (t <= ta) return a;
  if (t >= tb) return b;

  assert(ta != tb);
  return a + (b-a) * ((t-ta) / (tb - ta));
}


double solveLine(double x1, double y1, double x2, double y2, double x) {
  // (x2 - x) / (x2 - x1) == (y2 - y) / (y2 - y1)
  // y = y2 - (x2 - x) * (y2 - y1) / (x2 - x1);

  const double tolerance = 0.000001;
  if (x2 - x1 == 0.0) {
    assert ((x2 - x1).abs() < tolerance, 'Invalid points');
    return y1;
  }
  final y = y2 - (x2 - x) * (y2 - y1) / (x2 - x1);
  return y ;
}


double solveStep(double x1, double y1, double x2, double y2, double x) {
  // (x2 - x) / (x2 - x1) == (y2 - y) / (y2 - y1)
  // y = y2 - (x2 - x) * (y2 - y1) / (x2 - x1);
  if (x <= x1) return y1;
  if (x >= x2) return y2;

  // final y = y2 - (x2 - x) * (y2 - y1) / (x2 - x1);
  // return y ;
  return solveLine(x1, y1, x2, y2, x);
}


// const int int64MinValue = -9223372036854775808;


// const int int64MaxValue = 9223372036854775807;


// double decrement(double value, [int count = 1]) {
//   if (value.isInfinite || value.isNaN || count == 0) {
//     return value;
//   }

//   if (count < 0) {
//     return decrement(value, -count);
//   }

//   // Translate the bit pattern of the double to an integer.
//   // Note that this leads to:
//   // double > 0 --> long > 0, growing as the double value grows
//   // double < 0 --> long < 0, increasing in absolute magnitude as the double
//   //                          gets closer to zero!
//   //                          i.e. 0 - epsilon will give the largest long value!
//   var bytes = ByteData(8);
//   bytes.setFloat64(0, value);
//   int intValue = bytes.getInt64(0);

//   // If the value is zero then we'd really like the value to be -0. So we'll make it -0
//   // and then everything else should work out.
//   if (intValue == 0) {
//     // Note that long.MinValue has the same bit pattern as -0.0.
//     intValue = int64MinValue;
//   }

//   if (intValue < 0) {
//     intValue += count;
//   } else {
//     intValue -= count;
//   }

//   // Note that not all long values can be translated into double values. There's a whole bunch of them
//   // which return weird values like infinity and NaN
//   bytes.setInt64(0, intValue);
//   return bytes.getFloat64(0);
// }


// double increment(double value, [int count = 1]) {
//   if (value.isInfinite || value.isNaN || count == 0) {
//     return value;
//   }

//   if (count < 0) {
//     return decrement(value, -count);
//   }

//   // Translate the bit pattern of the double to an integer.
//   // Note that this leads to:
//   // double > 0 --> long > 0, growing as the double value grows
//   // double < 0 --> long < 0, increasing in absolute magnitude as the double
//   //                          gets closer to zero!
//   //                          i.e. 0 - epsilon will give the largest long value!
//   var bytes = ByteData(8);
//   bytes.setFloat64(0, value);
//   int intValue = bytes.getInt64(0);
//   if (intValue < 0) {
//     intValue -= count;
//   } else {
//     intValue += count;
//   }

//   // Note that int64MinValue has the same bit pattern as -0.0.
//   if (intValue == int64MinValue) {
//     return 0.0;
//   }

//   // Note that not all long values can be translated into double values.
//   // There's a whole bunch of them which return weird values like infinity and NaN
//   bytes.setInt64(0, intValue);
//   return bytes.getFloat64(0);
// }


// double minimalDecrement(double value) {
//   return (value - decrement(value)).abs();
// }

// double minimalIncrement(double value){
//   return (value - increment(value)).abs();
// }

bool get isMobile {
  return 
    (defaultTargetPlatform == TargetPlatform.android) ||
    (defaultTargetPlatform == TargetPlatform.iOS);
}


Duration testPerfomance(int iterations, void Function() func) {
  final startTime = DateTime.now();

  for (int i=0; i<iterations; i++) {
    func();
  }

  final endTime = DateTime.now();
  return endTime.difference(startTime);
}



Future<ui.Image> loadAssetImage(
  String fileName, {
  int? targetWidth, 
  int? targetHeight
}) async {
  
  final a = await rootBundle.load("assets/images/$fileName");
  final b = await ui.instantiateImageCodec(
    a.buffer.asUint8List(),
    targetWidth: targetWidth,
    targetHeight: targetHeight);
  
  final c = await b.getNextFrame();
  return Future<ui.Image>.value(c.image);
}



class SineTween extends Tween<double> {

  SineTween({
    required double begin,
    required double end,
    required double ext1,
    required double ext2,
    required int periods})
      : assert(_between(begin, ext1, ext2)),
        assert(_between(end, ext1, ext2)) {

    // value(angle) = sin(angle) * radius + pivot
    // angle(value) = asin((value - pivot) / radius)

    final valueRange = (ext1 - ext2).abs();
    radius = valueRange / 2.0;
    pivot = ext1 + (ext2 - ext1) * 0.5;

    angleFrom = asin((begin - pivot) / radius);
    angleTo = asin((end - pivot) / radius);
    angleTo = angleTo + 2 * pi * periods * (ext1>ext2 ? 1 : -1);
  }

  late double pivot;
  late double radius;
  late double angleFrom;
  late double angleTo;


  static bool _between(double v, double ext1, double ext2) {
    final mx = max(ext1, ext2);
    final mn = min(ext1, ext2);
    return (v >= mn) && (v <= mx);
  }


  @override
  double transform(double t) {
    return pivot + radius * sin(angleFrom + (angleTo - angleFrom) * t);
  }

}



class SineSplineTween extends Tween<double> {

  SineSplineTween(this.points)
      : assert(points.isNotEmpty),
        assert(() {
          for (int i=0; i<points.length-1; i++) {
            if (points[i+1].dx < points[i].dx) return false;
          }
          return true;
        } (), 'Each x coordinate must be greater than the preceding x coordinate');

  SineSplineTween.fromArray(List<List<double>> arr)
      : assert(arr.isNotEmpty),
        points = [] {
    for (var a in arr) {
      if (a.length != 2) {
        throw Exception('Point must contain exactly two components but $a contains ${a.length}');
      }
      if ((points.isNotEmpty) && (points.last.dx > a[0])) {
        throw Exception('Each x coordinate must be greater than the preceding x coordinate');
      }

      points.add(Offset(a[0], a[1]));
    }
  }

  List<Offset> points;

  double get length => points.last.dx - points.first.dx;

  List<Offset> getInterval(double t){
    assert((t >= 0.0) && (t <= 1.0));
    if (t == 0.0) return [points[0], points[1]];
    if (t == 1.0) return [points[points.length-2], points[points.length-1]];
    final x = lerp(points.first.dx, points.last.dx, t);
    for (int i=0; i<points.length-1; i++) {
      if ((x >= points[i].dx) && (x <= points[i+1].dx)) {
        return [points[i], points[i+1]];
      }
    }
    throw Exception("x is out of range");
  }

  @override
  double transform(double t) {
    final pts = getInterval(t);
    final p1 = pts[0], p2 = pts[1];

    final x = lerp(points.first.dx, points.last.dx, t);
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final radius = (dy / 2).abs();
    final pivot = min(p1.dy, p2.dy) + radius;

    late final double res;
    if (p1.dy <= p2.dy) {
      final angle = lerp(-pi/2, pi/2, (x-p1.dx)/dx);
      res = pivot + sin(angle) * radius;
    }
    else {
      final angle = lerp(pi/2, pi*1.5, (x-p1.dx)/dx);
      res = pivot + sin(angle) * radius;
    }

    return res;
  }
}



class UnifiedPair<T1, T2> {
  UnifiedPair(this.a, this.b);

  T1 a;
  T2 b;

  @override
  bool operator==(Object? other) {

    var res = false;
    if((other is UnifiedPair<T1, T2>)) {
      res = ((a == other.a) && (b == other.b)) ||
            ((a == other.b) && (b == other.a));
    } 
    else if((other is UnifiedPair<T2, T1>)) {
      res = ((a == other.a) && (b == other.b)) ||
            ((a == other.b) && (b == other.a));
    }

    return res;
  }

  @override
  int get hashCode {
    return (a.hashCode <= b.hashCode) 
      ? Object.hash(a, b)
      : Object.hash(b, a);
  }

  TRes call<TRes, FT1, FT2>(TRes Function(FT1, FT2) func){
    assert((FT1 == T1 && FT2 == T2) || (FT1 == T2 && FT2 == T1));
    if ((FT1 == T1 && FT2 == T2)) {
      return func(a as FT1, b as FT2);
    } else {
      return func(b as FT1, a as FT2);
    }
  }

}



class Pair<T1, T2> {
  Pair(this.v1, this.v2);

  T1 v1;
  T2 v2;

  @override
  bool operator==(Object? other) {
    return 
      (other is Pair<T1,T2>) &&
      (v1 == other.v1) &&
      (v2 == other.v2);
  }

  @override
  int get hashCode {
    return  Object.hash(v1, v2);
  }
}



class AnimatableVariable {

  /// [speed] is units per second
  AnimatableVariable(double value, double speed) 
    : _begin = value, 
      _end = value, 
      _speed = speed {
   
    _startTime = DateTime.now().millisecondsSinceEpoch  ;    
  }

  AnimatableVariable.active(double begin, double end, double speed) 
    : _begin = begin,
      _end = end,
      _speed = speed {

    _startTime = DateTime.now().millisecondsSinceEpoch  ;
  }
  
  double _begin;
  double _end;
  int _startTime = 0;
  double _speed = 0.0;

  void animateTo(double newValue, [double? speed]) {
    _begin = value;
    _end = newValue;
    if (speed != null) {
      _speed = speed;
    }
    _startTime = DateTime.now().millisecondsSinceEpoch;
  }

  void set(double newValue) {
    _begin = newValue;
    _end = newValue;
  }

  double get value {
    if (_begin == _end) return _begin;

    final curTime = DateTime.now().millisecondsSinceEpoch;
    final dTime = (curTime - _startTime)/1000;
    final timeReq = ((_end - _begin) / _speed).abs();
    if (dTime >= timeReq) return _end;
    return _begin >= _end 
      ? _begin - (_speed * dTime)
      : _begin + (_speed * dTime);
  }
}



class SmoothVariable<T> {

  SmoothVariable(T value) : _begin = value, _end = value;

  SmoothVariable.active(T begin, T end, Duration duration) 
    : _begin = begin,
      _end = end,
      _startTime = 0,
      _duration = duration.inMilliseconds {
    _startTime = DateTime.now().millisecondsSinceEpoch  ;
  }
  
  T _begin;
  T _end;
  int _startTime = 0;
  int _duration = 0;

  void set(T newValue, [Duration? duration]) {
    _begin = value;
    _end = newValue;
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _duration = duration?.inMilliseconds ?? 0;
  }

  T get value {
    if (_duration == 0) return _end;
    
    final curTime = DateTime.now().millisecondsSinceEpoch;
    final dTime = curTime - _startTime;

    if (dTime >= _duration) return _end;

    final double t = dTime / _duration;
    
    return (_begin as dynamic) + ((_end as dynamic) - (_begin as dynamic)) * t;
  }
}



class SwingVariable {
  SwingVariable(this.begin, this.end, this.duration, [this.oneWay=false]) 
    : _startTimeMs = 0,
      _durationMs = duration.inMilliseconds;
  
  double begin;
  double end;
  bool oneWay = false;
  Duration duration;
  final int _durationMs;
  int _startTimeMs;
  

  double get value {

    final curTimeMs = DateTime.now().millisecondsSinceEpoch;

    if (_startTimeMs == 0) {
      _startTimeMs = curTimeMs;
      return begin;
    }

    double t = 0;
    double res = 0;

    var msPassed = curTimeMs - _startTimeMs;
    bool isForth = oneWay || (msPassed ~/ _durationMs).isEven;
    msPassed = msPassed % _durationMs;
    if (isForth) {
      t = msPassed / _durationMs;
      res = begin + (end - begin) * t;
    }
    else{
      t = msPassed / _durationMs;
      res = end + (begin - end) * t;
    }

    return res;
  }
}


