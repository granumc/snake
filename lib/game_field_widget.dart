
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'game_objects/field.dart';
import 'settings.dart';



class GameField extends StatefulWidget {
  const GameField({
    Key? key, 
    required this.settings, 
    required this.focusNode,
    this.onGameEnded, 
    this.onFruitEaten,
    this.gamePaused = true
    }) : super(key: key);

  final Settings settings;
  final FocusNode focusNode;
  final void Function(int fruits)? onFruitEaten;
  final void Function()? onGameEnded;
  final bool gamePaused;

  @override
  GameFieldState createState() => GameFieldState();
}


class GameFieldState extends State<GameField> with TickerProviderStateMixin {
  late AnimationController _controller;
  Field? field;
  late Settings settings;

  @override
  void initState() {
    super.initState();
    // going fullscreen (on Android only?)
    // if (Platform.isAndroid)
    //   SystemChrome.setEnabledSystemUIOverlays([]);

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 30));
    _controller.repeat();
    settings = widget.settings;
  }

  @override
  void dispose() {
    // going out of fullscreen
    // if (Platform.isAndroid)
    //   SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GameField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.settings != oldWidget.settings) {
      field = null;
    }

    if (field != null) {
      // field?.gamePaused = widget.gamePaused;
    }

  }

  void onKeyboard(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    field?.onKeyDown(event);
  }


  @override
  Widget build(BuildContext context) {

    return LayoutBuilder(builder: (context, constraints){

      final minSideGridSize = widget.settings.fieldSize.value;

      if (field == null) {
        
        var fieldWidth = 0;
        var fieldHeight = 0;

        if (constraints.maxHeight <= constraints.maxWidth) {
          final factor = constraints.maxWidth / constraints.maxHeight;
          fieldHeight = minSideGridSize;
          fieldWidth = (minSideGridSize.toDouble() * factor).toInt();
        }
        else {
          final factor = constraints.maxHeight / constraints.maxWidth;
          fieldWidth = minSideGridSize;
          fieldHeight = (minSideGridSize * factor).toInt();
        }

        widget.settings.fieldWidth = fieldWidth;
        widget.settings.fieldHeight = fieldHeight;

        field = setupGame(
          widget.settings, 
          _controller, 
          this, 
          onGameEnded: widget.onGameEnded,
          onFruitEaten: widget.onFruitEaten);
      }

      return Padding(
        padding: const EdgeInsets.all(0.0),
        child: AspectRatio(
          aspectRatio: field!.width / field!.height,
          child: GestureDetector(
            onPanStart: field!.onPanStart,
            onPanEnd: field!.onPanEnd,
            onPanUpdate: field!.onPanUpdate,
            onDoubleTap: field!.onDoubleTap,
            child: RawKeyboardListener(
              onKey: onKeyboard,
              focusNode: widget.focusNode,
              autofocus: true,
              child: CustomPaint(
                painter: field,
                child: Container(),
              ),
            ),
          ),
        ),
      );
    
    });

  }
}
