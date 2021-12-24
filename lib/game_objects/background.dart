

import 'dart:ui';

import 'field.dart';
import 'game_object.dart';



class BackgroundItem extends GameObject {

  BackgroundItem(
    this.field, {
    this.bgColor1 = const Color.fromARGB(255, 173, 228, 87),
    this.bgColor2 = const Color.fromARGB(255, 165, 222, 78),
  });

  static final _emptyPaint = Paint()..isAntiAlias = false;

  final Field field;
  final Color bgColor1;
  final Color bgColor2;

  Image? _bgImage;

  void _drawChessboard({
    required Canvas canvas,
    required Size boardSize,
    required Paint paint1,
    required Paint paint2,
    required int columns,
    required int rows}) {
    
    final iw = boardSize.width / columns;
    final ih = boardSize.height / rows;

    for (int y=0; y<rows; y++) {
      for (int x=0; x<columns; x++) {
        final r = Rect.fromLTWH(x * iw, y * ih, iw, ih);
        final p = (x & 1) == (y & 1) ? paint1 : paint2;
        canvas.drawRect(r, p);
      }
    }
  }


  void _createBackgroundImage(int fieldWidth, int fieldHeight, Size size) {
    final picRec = PictureRecorder();
    final canvas = Canvas(picRec);

    _drawChessboard(
        canvas: canvas,
        boardSize: size,
        paint1: Paint()..color=bgColor1..isAntiAlias=false,
        paint2: Paint()..color=bgColor2..isAntiAlias=false,
        rows: fieldHeight,
        columns: fieldWidth);

    final pic = picRec.endRecording();
    pic.toImage(size.width.toInt(), size.height.toInt()).then((img){
      final Image? tmpBgImage = _bgImage;
      _bgImage = img;
      tmpBgImage?.dispose();
    });
  }


  @override
  void paint(Canvas canvas, Size worldSize) {
    if ((_bgImage == null) ||
        ((_bgImage!.width != worldSize.width.toInt()) || 
        (_bgImage!.height != worldSize.height.toInt()))) {
      canvas.drawRect(Rect.fromLTWH(0, 0, worldSize.width, worldSize.height), Paint()..color=bgColor1);
      _createBackgroundImage(field.width, field.height, worldSize);
    }
    else {
      canvas.drawImage(_bgImage!, Offset.zero, _emptyPaint);
    }
  }

  @override
  final shapes = [RectShape(0, 0, 0, 0)];
}


