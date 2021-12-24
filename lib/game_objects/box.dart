
import 'dart:ui' as ui;

import 'field.dart';
import '../utils.dart';
import 'package:flutter/material.dart';

import 'game_object.dart';


class MovableBox2 extends RectShape with GameObject  {

  MovableBox2(double x, double y, this.field)
      : assert (x >= 0  &&  x < field.width),
        assert (y >= 0  &&  y < field.height),
        _x = SmoothVariable(x),
        _y = SmoothVariable(y),
        super(x, y, 1.0, 1.0);

  @override
  Iterable<Shape> get shapes sync* { yield this; }


  final Field field;

  final SmoothVariable<double> _x;
  final SmoothVariable<double> _y;


  final _paint = ui.Paint()..color = Colors.red;

  @override
  void paint(ui.Canvas canvas, ui.Size worldSize) {
    var r = field.rectToWorld(RectShape(_x.value, _y.value, 1, 1), worldSize);
    canvas.drawRect(r, _paint);
  }

  void moveBox(double xCoord, double yCoord, double speed) {
    x = xCoord;
    y = yCoord;
    final dur = Duration(milliseconds: (1000.0 / speed).floor());
    _x.set(xCoord, dur);
    _y.set(yCoord, dur);

  }

}

