

import 'dart:math';
import 'dart:ui' as ui;

import 'field.dart';
import '../utils.dart';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

import 'game_object.dart';


class FruitImage {
  static final Map<String, ui.Image?> _map = {
    'apple-96.png' : null,
    'apricot-96.png' : null,
    'artichoke-96.png': null,
    'beet-96.png': null,
    'blueberry-96.png' : null,
    'broccoli-96.png' : null,
    'cherry-96.png' : null,
    'corn-96.png' : null,
    'grape-96.png' : null,
    'mint-96.png': null,
    'mushroom-96.png' : null,
    'paprika-96.png' : null,
    'peach-96.png' : null,
    'pear-96.png' : null,
    'pineapple-96.png': null,
    'plum-96.png' : null,
    'pumpkin-96.png' : null,
    'radish-96.png' : null,
    'raspberry-96.png' : null,
    'spinach-96.png' : null,
    'strawberry-96.png' : null,
    'tomato-96.png' : null,
    'watermelon-96.png' : null,
    'wheat-96.png': null,
    'wholeWatermelon-96.png' : null,  
  };


  static Iterable<String> get fileNames => _map.keys;


  static Future<ui.Image?> getOrLoad(String fileName) {

    if (fileName == 'random') {
      return random;
    }

    assert(_map.containsKey(fileName));

    if (_map[fileName] != null) {
      return Future.value(_map[fileName]);
    }

    return loadAssetImage('fruits/'+fileName);
  }

 
  static Future<ui.Image?> get random {
    final index = Random().nextInt(fileNames.length);
    return getOrLoad(fileNames.elementAt(index));
  }


  static List<Future<ui.Image?>> get all {
    final res = <Future<ui.Image?>>[];
    
    for (final fn in fileNames) {
      res.add(getOrLoad(fn));
    }

    return res;
  }

}





class Fruit extends CircleShape with GameObject  {

  Fruit(this.field, double x, double y, Future<ui.Image?> futureImage, {Vector2? velocity})
    : assert (x >= 0  &&  x < field.width),
      assert (y >= 0  &&  y < field.height),
      vel = velocity ?? Vector2.zero(),
      super(x, y, 0.5) {

    _scaleController = AnimationController(
      vsync: field.tickerProvider!, 
      duration: const Duration(milliseconds: 600));

    _scale = Tween<double>(begin: 0.1, end: 1.0).animate(_scaleController!);
    _scaleController!.forward().then((value){
      _scaleController!.reset();
      _scale = Tween<double>(begin: 1.0, end: 1.5).animate(_scaleController!);
      _scaleController!.repeat(reverse: true, );
    });

    futureImage.then((img) => _image = img);
  }


  @override
  void onDismounted() {
    _scaleController?.dispose();
  }


  Fruit clone() {
    final res = Fruit(field, x, y, Future.value(_image), velocity: vel.clone());
    return res;
  }

  final Field field;
  ui.Image? _image;
  final _paint = ui.Paint()..color = Colors.red..filterQuality=ui.FilterQuality.medium;
  late Animation<double> _scale;
  AnimationController? _scaleController;

  @override
  Vector2 vel = Vector2.zero();

  @override
  void paint(ui.Canvas canvas, ui.Size worldSize) {
    var fruitRect = field.rectToWorld(toRect);

    fruitRect = Rect.fromCenter(
      center: fruitRect.center, 
      width: fruitRect.width * _scale.value, 
      height: fruitRect.width * _scale.value);

    if (_image != null) {
      final imageRect = Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble());
      canvas.drawImageRect(_image!, imageRect, fruitRect, _paint);
    }
  }


  @override
  void update(int timeDelta) {
    if (timeDelta == 0) return;
    final c = timeDelta.toDouble() / 1000.0;
    x += vel.x * c;
    y += vel.y * c;
  }

  @override
  Iterable<Shape> get shapes sync* { yield this; }
 
}



