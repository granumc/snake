
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


enum SnakeSpeed {
  slow,
  normal,
  fast
}

extension SnakeSpeedExt on SnakeSpeed {

  static final _map = {
    SnakeSpeed.slow: 4.0,
    SnakeSpeed.normal: 7.0,
    SnakeSpeed.fast: 10.0,
  };

  static SnakeSpeed? fromValue(double value) {
    for(final i in _map.entries){
      if (i.value == value) {
        return i.key;
      }
    }
  }

  static SnakeSpeed? fromName(String name) {
    for(final i in SnakeSpeed.values){
      if (i.name == name) {
        return i;
      }
    }
  }

  double get value => _map[this]!;
}


enum FieldSize {
  small,
  normal,
  large
}

extension FieldSizeExt on FieldSize {
// mobile  7  12  17
// desktop 10 17  24

  static final _mobile = {
    FieldSize.small: 7,
    FieldSize.normal: 11,
    FieldSize.large: 15,
  };

  static final _desktop = {
    FieldSize.small: 10,
    FieldSize.normal: 15,
    FieldSize.large: 20,
  };


  bool get _isMobile {
    return 
      (defaultTargetPlatform == TargetPlatform.android) ||
      (defaultTargetPlatform == TargetPlatform.iOS);
  }

  int get value {
    return _isMobile ? _mobile[this]! : _desktop[this]!;
  }

}

class GameTheme {

  GameTheme() {
    snakeColor1 = Colors.indigo;
    snakeColor2 = Colors.indigo.shade800;

    fieldColor1 = const Color.fromARGB(255, 173, 228, 87);
    fieldColor2 = const Color.fromARGB(255, 165, 222, 78);

    wallColor = const Color.fromARGB(255, 112, 167, 51);
  }

  GameTheme.clone(GameTheme other) {
    snakeColor1 = other.snakeColor1;
    snakeColor2 = other.snakeColor2;

    fieldColor1 = other.fieldColor1;
    fieldColor2 = other.fieldColor2;

    wallColor = other.wallColor;
  }

  late Color snakeColor1;
  late Color snakeColor2;

  late Color fieldColor1;
  late Color fieldColor2;

  late Color wallColor;

}



class GameFeatures {
  bool addRandomWallOnFruitEaten = false;
  bool swapDirectionOnFruitEaten = false;
  bool movingFruits = false;
  bool snakeIgnoreSelfCollide = false;
  bool transparentEdgeWalls = false;
}



class Settings {

  Settings();

  Settings.clone(Settings other) {
    fieldWidth = other.fieldWidth;
    fieldHeight = other.fieldHeight;
    fieldSize = other.fieldSize;

    fruitName = other.fruitName;
    fruitAmount = other.fruitAmount;
    theme = GameTheme.clone(other.theme);
    snakeSpeed = other.snakeSpeed;
  }

  int fieldWidth = -1;
  int fieldHeight = -1;
  FieldSize fieldSize = FieldSize.normal;
  String fruitName = 'random';
  int fruitAmount = 1;
  GameTheme theme = GameTheme(); 
  SnakeSpeed snakeSpeed = SnakeSpeed.normal;

  


  void save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('field.width', fieldWidth);
    prefs.setInt('field.height', fieldHeight);
    prefs.setString('field.fieldSize', fieldSize.name);
    
    prefs.setString('fruit.name', fruitName);
    prefs.setInt('fruit.amount', fruitAmount);
    
    prefs.setString('snake.speed', snakeSpeed.name);

    prefs.setInt('snake.color1', theme.snakeColor1.value);
    prefs.setInt('snake.color2', theme.snakeColor2.value);

    prefs.setInt('field.color1', theme.fieldColor1.value);
    prefs.setInt('field.color2', theme.fieldColor2.value);

    prefs.setInt('wall.color', theme.wallColor.value);
  }


  void load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    fieldWidth = prefs.getInt('field.width') ?? 20;
    fieldHeight = prefs.getInt('field.height') ?? 15;
    fieldSize = FieldSize.values.byName(
      prefs.getString('field.shortestSideLength') ?? FieldSize.normal.name);

    fruitName = prefs.getString('fruit.name') ?? 'random';
    fruitAmount = prefs.getInt('fruit.amount') ?? 1;

    snakeSpeed = SnakeSpeed.values.byName(prefs.getString('snake.speed') ?? SnakeSpeed.normal.name) ;

    theme.snakeColor1 = Color(prefs.getInt('snake.color1') ?? Colors.indigo.value);
    theme.snakeColor2 = Color(prefs.getInt('snake.color2') ?? Colors.indigo.value);

    theme.fieldColor1 = Color(prefs.getInt('field.color1') ?? Colors.green.value);
    theme.fieldColor2 = Color(prefs.getInt('field.color2') ?? Colors.green.shade200.value);

    theme.wallColor = Color(prefs.getInt('wall.color') ?? Colors.green.shade700.value);
  }


  String get _scoreId {
    return 'score.$fieldSize.$snakeSpeed.$fruitAmount';
  }


  Future<int> getBestScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      return prefs.getInt(_scoreId) ?? 0;
    }
    catch(ex) {
      return 0;
    }
  }

  void setBestScore(int score) {
    SharedPreferences.getInstance().then((prefs){
      prefs.setInt(_scoreId, score);
    });
  }

}


