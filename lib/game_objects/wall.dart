
import 'package:flutter/material.dart';

import 'field.dart';
import 'game_object.dart';



class Wall extends RectShape with GameObject {
  Wall(
    this.field, 
    double x, double y, 
    double width, double height, {
    Color color = Colors.green 
    }) : _paint = Paint()..color=color..isAntiAlias=false,
      super(x, y, width, height) {

    shapes = [this];
  }

  Wall clone() {
    final res = Wall(field, x, y, width, height, color:_paint.color);
    return res;
  }

  final Field field;
  final Paint _paint;

  @override
  void paint(Canvas canvas, Size worldSize) {
    canvas.drawRect(field.rectToWorld(this), _paint);
  }

  @override
  late List<Shape> shapes;
}

