
import 'field.dart';
import 'package:flutter/material.dart';

import 'game_object.dart';


class TestItem extends RectShape with GameObject {

  TestItem(Field field):super(0, 0, 1, 1);
  

  @override
  void paint(Canvas canvas, Size worldSize) {
  }


  @override
  void update(int timeDelta) {
  }

  @override
  List<Shape> get shapes => [this];

}

