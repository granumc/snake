import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';


class CarouselItem<T> {

  CarouselItem(this.value, this.image);

  CarouselItem.future(this.value, Future<ui.Image?> futureImage)
    : _futureImage = futureImage;
    

  T value;
  Future<ui.Image?>? _futureImage;
  ui.Image? image;
}


class Carousel<T> extends StatefulWidget {
  Carousel({
    Key? key, 
    required this.items,
    required this.onItemSelected,
    int? selectedIndex,
    T? selectedValue,
    this.gap = 8,
    FocusNode? focusNode
  }) : super(key: key) {

    this.focusNode = focusNode ?? FocusNode();

    if (selectedValue != null)     {
      for (var i=0; i < items.length; i++) {
        if (items[i].value == selectedValue) {
          this.selectedIndex = i;
          break;
        }
      }
    }
    else {
      this.selectedIndex = selectedIndex ?? 0;
    }

    // this.focusNode = focusNode ?? FocusNode();
  }


  final List<CarouselItem<T>> items;
  final double gap;
  late final int selectedIndex;
  final void Function(T value, int index) onItemSelected;
  late final FocusNode focusNode;

  @override
  _CarouselState<T> createState() => _CarouselState<T>();
}


class _CarouselState<T> extends State<Carousel<T>>
    with TickerProviderStateMixin {
  
  AnimationController? _controller;
  List<CarouselItem<T>> items = [];
  late _ImgList _imgList;
  late int selectedIndex;
  
  // late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    items = widget.items;
    selectedIndex = widget.selectedIndex;
    for (final item in items) {
      if (item.image == null) {
        assert(item._futureImage != null);
        item._futureImage!.then((image) {
          setState(() {
            item.image = image;
          });
        });
      }
    }

    // _focusNode = widget.focusNode ?? FocusNode();
    // _focusNode.addListener(() {
    //   setState(() {
    //   });
    // });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }


  void onHorizontalDragUpdate(DragUpdateDetails d) {
    _controller?.value -= d.delta.dx;
  }


  void onHorizontalDragEnd(DragEndDetails d) {
    double scrollOffset = _controller?.value ?? 0.0;
    int selIndex = _imgList.selectedIndex(scrollOffset);
    double newScrollOffset = _imgList.scrollOffsetByIndex(selIndex);
    _controller?.animateTo(
      newScrollOffset, 
      duration: const Duration(milliseconds: 200)).then((value){
        if (selectedIndex != selIndex) {
          selectedIndex = selIndex;
          widget.onItemSelected.call(items[selectedIndex].value, selectedIndex);
        }
    });
  }


  void onTapDown(TapDownDetails d){
    // final x = d.localPosition.dx;
    
    final selIndex = _imgList.itemIndexByCanvasCoords(_controller!.value, d.localPosition);
    final sc = _imgList.scrollOffsetByIndex(selIndex);
    // final sc = _imgList.imageRect(i, _controller!.value);
    _controller?.animateTo(sc, duration: const Duration(milliseconds: 400)).then((value){
      if (selectedIndex != selIndex) {
        selectedIndex = selIndex;
        widget.onItemSelected.call(items[selectedIndex].value, selectedIndex);
      }
    });
    widget.focusNode.requestFocus();
    
  }


  List<ui.Image?> get images {
    final res = <ui.Image?>[];
    for (final i in items) {
      res.add(i.image);
    }

    return res;
  }

  void onKey(RawKeyEvent e){
    if (e is RawKeyDownEvent) {
      if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (selectedIndex <= 0 ) return;
        final sc = _imgList.scrollOffsetByIndex(selectedIndex - 1);
        _controller?.stop();
        selectedIndex--;
        _controller?.animateTo(sc, duration: const Duration(milliseconds: 200)).then((value){
            widget.onItemSelected.call(items[selectedIndex].value, selectedIndex);
        });
      }
      else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (selectedIndex >= items.length - 1) return;
        final sc = _imgList.scrollOffsetByIndex(selectedIndex + 1);
        _controller?.stop();
        selectedIndex++;
        _controller?.animateTo(sc, duration: const Duration(milliseconds: 200)).then((value){
            widget.onItemSelected.call(items[selectedIndex].value, selectedIndex);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      onKey: onKey,
      // focusNode: _focusNode,
      focusNode: widget.focusNode,
      child: GestureDetector(
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        onHorizontalDragEnd: onHorizontalDragEnd,
        onTapDown: onTapDown,
        child: LayoutBuilder(
          builder: (context, constaints) {
            double h = 0;
            if (constaints.maxHeight == double.infinity) {
              h = _ImgList(images, widget.gap).canvasSize.height;
            }
            else {
              h = constaints.maxHeight;
            }
    
            Size sz = Size(constaints.maxWidth, h);
    
            _imgList = _ImgList.scaled(images, widget.gap, sz);
            _controller?.dispose();
            _controller = AnimationController(
              vsync: this, 
              lowerBound: _imgList.scrollLowerBound, 
              upperBound: _imgList.scrollUpperBound);
    
            final scrl = _imgList.scrollOffsetByIndex(selectedIndex);
            _controller?.animateTo(scrl, duration: const Duration());
      
            final _painter = _CarouselPainter(
                repaint: _controller, images: images, gap: widget.gap);

            return SizedBox(
              // color: _focusNode.hasFocus ? Colors.blue.shade50 : Colors.transparent,
              width: sz.width,
              height: sz.height,
              child: CustomPaint(painter: _painter)
            );
          },
        ),
      ),
    );
  }
}


class _CarouselPainter extends CustomPainter {
  _CarouselPainter({this.repaint, required this.images, required this.gap})
      : super(repaint: repaint);

  Animation<double>? repaint;
  List<ui.Image?> images;
  double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final scrollPos = repaint?.value ?? 0.0;
    paintImages(canvas, size, scrollPos);
  }


  void paintImages(Canvas canvas, Size size, double scrollPos) {
    canvas.clipRect(Rect.fromLTWH(0, -50, size.width, size.height+100));

    final il = _ImgList.scaled(images, gap, size);

    int selIndex = il.selectedIndex(scrollPos);
    for (int i=0; i<images.length; i++) {
      if (!il.isVisible(i, scrollPos)) continue;
      final img = images[i];

      var imgRect = il.imageRect(i, scrollPos);

      if (i == selIndex) {
        // canvas.drawRect(imgRect, Paint()..color = Colors.pink.withAlpha(150));
        final centerX = il.scrollOffsetByIndex(i);
        final dx = (centerX - scrollPos).abs();
        final fraction = 1.0 - dx / (imgRect.width / 2);
        final t = 1.0 + 0.3 * fraction;
        imgRect = Rect.fromCenter(
          center: imgRect.center, 
          width: imgRect.width * t, 
          height: imgRect.height * t);
      }

      final Paint paint = (i == selIndex) ? Paint() : (Paint()..color=Colors.white.withAlpha(100));
      paint.filterQuality = FilterQuality.medium;
      
      if (img != null) {
        final srcRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        canvas.drawImageRect(img, srcRect, imgRect, paint);
      }
    }
  }



  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}


class _ImgList {

  _ImgList(this.images, this.gap) {
    _rects = imageListToRectList(images, gap, null);
    var w = _rects.isEmpty ? 0.0 : _rects.last.right;
    var h = 0.0;
    for (final r in _rects) {
      h = max(h, r.height);
    }

    canvasSize = Size(w, h);
  }


  _ImgList.scaled(this.images, this.gap, this.canvasSize) {
    _rects = imageListToRectList(images, gap, canvasSize);
  }
  

  final List<ui.Image?> images;
  final double gap;
  late final List<Rect> _rects;
  late final Size canvasSize;


  static Rect scaleRectToFit(Rect rectToScale, Rect rectToFitIn) {
    if (rectToScale.height > rectToFitIn.height) {
      double factor = (rectToScale.height != 0.0)
          ? rectToFitIn.height / rectToScale.height
          : 0.0;

      return Rect.fromLTWH(rectToScale.left, rectToScale.top,
          rectToScale.width * factor, rectToScale.height * factor);
    }

    return rectToScale;
  }


  static List<Rect> imageListToRectList(List<ui.Image?> images, double gap, Size? canvasSize) {

    List<Rect> res = [];

    final canvasRect = Rect.fromLTWH(
      0.0, 
      0.0, 
      canvasSize?.width ?? 0.0, 
      canvasSize?.height ?? 0.0);
    
    double left = 0.0;
    
    for (final img in images) {
      final originalImageRect = 
        Rect.fromLTWH(left, 0.0, img?.width.toDouble() ?? 1.0, img?.height.toDouble() ?? 1.0);

      if (canvasSize == null) {
        res.add(originalImageRect);
        left = originalImageRect.right + gap;
      }
      else {
        final scaledImageRect = scaleRectToFit(originalImageRect, canvasRect);
        res.add(scaledImageRect);
        left = scaledImageRect.right + gap;
      }
    }

    return res;
  }


  double get scrollLowerBound {
    if (_rects.isEmpty) return 0.0;
    return -(canvasSize.width / 2.0) +   (_rects.first.width / 2.0);
  }


  double get scrollUpperBound {
    if (_rects.isEmpty) return 0.0;
    return scrollLowerBound + _rects.last.left;//.center.dx;
  }

  
  double get scrollWidth => scrollUpperBound - scrollLowerBound;

  
  double get width => _rects.isEmpty ? 0.0 : _rects.last.right;


  int selectedIndex(double scrollOffset) {
    if (images.isEmpty) return -1;

    if (scrollOffset <= scrollLowerBound) return 0;

    final selPoint = canvasSize.width / 2.0 + scrollOffset;

    final halfGap = gap / 2.0;

    for (int i = 0; i < _rects.length; i++) {
      final l = _rects[i].left - halfGap;
      final r = _rects[i].right + halfGap;
      if (selPoint >= l  &&  selPoint < r) {
        return i;
      }
    }

    return images.length - 1;
  }


  double scrollOffsetByIndex(int index) {
    assert(index >= 0  &&  index < _rects.length);
    return _rects[index].center.dx - canvasSize.width / 2;
  }


  Rect imageRect(int index, double scrollOffset) {
    assert(index >= 0  &&  index < _rects.length);
    final r = _rects[index];
    return r.translate(
      -scrollOffset, 
      (canvasSize.height - r.height) / 2.0);
  }


  bool isVisible(int index, double scrollOffset) {
    assert(index >= 0  &&  index < _rects.length);
    final rect = imageRect(index, scrollOffset);
    return !((rect.right < 0) || (rect.left > canvasSize.width));
  }


  int itemIndexByCanvasCoords(double scrollOffset, Offset canvasCoords) {
    int i = selectedIndex(canvasCoords.dx + scrollOffset - canvasSize.width / 2.0); 
    return i;
  }

}




