
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'game_field_widget.dart';
import 'game_objects/snake.dart';
import 'select_carousel.dart';
import 'utils.dart';
import 'package:flutter/material.dart';

import 'game_objects/fruit.dart';
import 'settings.dart';

void main() {
  runApp(const SnakeApp());
}

// Root widget of the application.
class SnakeApp extends StatelessWidget {
  const SnakeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

@immutable
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}



class _HomePageState extends State<HomePage> {
  int _fruitsEaten = 0;
  int _bestScore = 0;
  bool _gamePaused = true;
  final FocusNode _focusNode = FocusNode();

  Settings settings = Settings();
  bool _firstRun = true;

  @override
  void initState(){
    super.initState();
  }


  void onPausePressed() {
    setState(() {
      _gamePaused = true;
    });
  }


  void showStartDialog(BuildContext context) async {
    final Settings settings = await showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (context) => StartDialog(this.settings));

    _focusNode.requestFocus();
    int bestScore = await settings.getBestScore();
      
    setState(() {
      _fruitsEaten = 0;
      this.settings = settings;
      _bestScore = bestScore;
    });
  }


  void onGameEnded(BuildContext context) {
    if (_fruitsEaten > _bestScore) {
      settings.setBestScore(_fruitsEaten);
    }

    showStartDialog(context);
  }

  @override
  Widget build(BuildContext context) {

    if (_firstRun) {
      WidgetsBinding.instance?.addPostFrameCallback((d) async{
        showStartDialog(context);
      });

      _firstRun = false;
      return Container(
        // color: const Color.fromARGB(255, 112, 167, 51)
        color: const Color.fromARGB(255, 173, 228, 87),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: settings.theme.wallColor,
        title: Row(
          children: [
            const SizedBox(width:8, height:10),
            const Image(image: AssetImage('assets/images/fruits/apple-96.png'),height: 48),
            const SizedBox(width:8, height:10),
            // Text(_fruitsEaten.toString(), style:  const TextStyle(fontWeight: FontWeight.bold),)
            Text(_fruitsEaten.toString(), style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white)),
            const SizedBox(width:32, height:32),
            
            if (_bestScore > 0) const Image(image: AssetImage('assets/images/ui/winner-96.png'),height: 48),
            if (_bestScore > 0) const SizedBox(width:8, height:10),
            if (_bestScore > 0) Text(_bestScore.toString(), style: Theme.of(context).textTheme.headline5!.copyWith(color: Colors.white)),
          ],
        ),
      ),

      body: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        color: settings.theme.wallColor,//Color.fromARGB(255, 131, 184, 71),
        child: Column( 
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: GameField(
                  settings:settings,
                  // gamePaused: _gamePaused,
                  focusNode: _focusNode,
                  onFruitEaten: (int fruits){
                    WidgetsBinding.instance?.addPostFrameCallback((d){
                      setState((){ _fruitsEaten = fruits;});
                    });
                  },
                  onGameEnded: () => onGameEnded(context),
                )
              )
            )
          ],
        ),
      ),
    );
  }
}



class StartDialog extends StatefulWidget {
  const StartDialog(this.settings, { Key? key}) : super(key: key);

  final Settings settings;

  @override
  _StartDialogState createState() => _StartDialogState();
}


class _StartDialogState extends State<StartDialog> {

  late final Settings settings;
  final focusNode = FocusNode(canRequestFocus: false);

  @override
  void initState(){
    super.initState();
    settings = Settings.clone(widget.settings);
  }


  void onFruitSelected(String fileName, int index) {
    settings.fruitName = fileName;
  }


  void onFruitAmountSelected(int amount, int index) {
    settings.fruitAmount = amount;
  }


  void onGridSizeSelected(FieldSize size, int index) {
    settings.fieldSize = size;
  }


  void onSpeedSelected(SnakeSpeed snakeSpeed, int index) {
    settings.snakeSpeed = snakeSpeed;
  }


  void onSnakeColorSelected(Pair<Color,Color> colors, int index) {
    settings.theme.snakeColor1 = colors.v1;
    settings.theme.snakeColor2 = colors.v2;
  }


  void onStartClicked(BuildContext context) {
    Navigator.pop(context, settings);
  }


  void onKeyPressed(RawKeyEvent e, BuildContext context){
    if ((e is RawKeyDownEvent && e.logicalKey == LogicalKeyboardKey.enter)) {
      onStartClicked(context);
    }
  }


  Future<ui.Image?> createColoredImage(int width, int height, Color color){
    ui.PictureRecorder picRec = ui.PictureRecorder();
    Canvas c = Canvas(picRec);
    var r = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    r = r.deflate(12);

    final hp = SnakeHeadPainter();
    hp.headCenter = r.center;
    hp.headWidth = r.width;
    hp.headHeight = r.height;
    hp.headPaint = Paint()..color=color;
    hp.setColor(color);

    hp.paint(c, Size(r.width, r.height));

    final pic = picRec.endRecording();
    return pic.toImage(width, height);
  }



  List<CarouselItem<Pair<Color,Color>>> snakeColorItems(){

    final colors = [
      Pair<Color, Color>(Colors.indigo, Colors.indigo.shade800),
      Pair<Color, Color>(Colors.pink, Colors.pink.shade700),
      Pair<Color, Color>(Colors.blue, Colors.blue.shade700),
      Pair<Color, Color>(Colors.amber, Colors.amber.shade800),
      Pair<Color, Color>(Colors.cyan.shade600, Colors.cyanAccent.shade400),
      Pair<Color, Color>(Colors.deepOrange, Colors.deepOrange.shade800),
      Pair<Color, Color>(Colors.deepPurple, Colors.deepPurple.shade300),
      Pair<Color, Color>(Colors.red, Colors.red.shade800),
      Pair<Color, Color>(Colors.green.shade700, Colors.green.shade900),
      Pair<Color, Color>(Colors.yellow.shade600, Colors.yellow),
      Pair<Color, Color>(Colors.purple, Colors.purpleAccent.shade700),
      Pair<Color, Color>(Colors.blueGrey, Colors.blueGrey.shade700),
    ];

    final res = <CarouselItem<Pair<Color,Color>>>[];
    for (final c in colors){
      res.add(CarouselItem.future(c, createColoredImage(48, 48  , c.v1)));
    }

    return res;
  }


  Widget _listViewItemWrap(Widget c) {

    final height = isMobile ? 32.0 : 48.0;
    final bottomPadding = isMobile ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.only(bottom:bottomPadding),
      child: SizedBox(
        width: 500,
        height: height,
        child: c
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    final fruitItems = [
      CarouselItem.future('random', loadAssetImage('ui/fruits-96.png')),
      for (final fn in FruitImage.fileNames)
        CarouselItem.future(fn, FruitImage.getOrLoad(fn)),
    ];

    final snakeSpeedItems = [
      CarouselItem<SnakeSpeed>.future(SnakeSpeed.normal, loadAssetImage('ui/speed-normal-96.png')),
      CarouselItem<SnakeSpeed>.future(SnakeSpeed.fast, loadAssetImage('ui/speed-fast-96.png')),
      CarouselItem<SnakeSpeed>.future(SnakeSpeed.slow, loadAssetImage('ui/speed-slow-96.png'))
    ];

    final gridSizeItems = [
      CarouselItem<FieldSize>.future(FieldSize.normal, loadAssetImage('ui/grid3-96.png')),
      CarouselItem<FieldSize>.future(FieldSize.small, loadAssetImage('ui/grid2-96.png')),
      CarouselItem<FieldSize>.future(FieldSize.large, loadAssetImage('ui/grid4-96.png')),
    ];

    final fruitAmountItems = [
      CarouselItem<int>.future(1, loadAssetImage('ui/ball1-96.png')),
      CarouselItem<int>.future(3, loadAssetImage('ui/ball3-96.png')),
      CarouselItem<int>.future(5, loadAssetImage('ui/ball5-96.png')),
    ];

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Dialog(
        child: RawKeyboardListener(
          focusNode: focusNode,
          onKey: (event) => onKeyPressed(event, context),
          child: SizedBox(
            width: 500,
            // padding: EdgeInsets.all(24),
            child: ListView(
              padding: const EdgeInsets.all(24),
              // mainAxisSize: MainAxisSize.min,
              shrinkWrap: true,
              children:[
                Container(
                  padding: const EdgeInsets.only(bottom:  24.0),
                  child: Center(child: Text('Snake', style: Theme.of(context).textTheme.headline4))
                ),
        
                _listViewItemWrap(Carousel(
                  items: fruitItems, 
                  gap:16,
                  selectedValue: settings.fruitName ,
                  onItemSelected: onFruitSelected)..focusNode.requestFocus()),
            
                _listViewItemWrap(Carousel(
                  items: fruitAmountItems, 
                  gap:16,
                  selectedValue: settings.fruitAmount,
                  onItemSelected: onFruitAmountSelected)),
            
            
                _listViewItemWrap(Carousel(
                  items: gridSizeItems, 
                  gap:16,
                  selectedValue: settings.fieldSize,
                  onItemSelected: onGridSizeSelected)),
            
            
                _listViewItemWrap(Carousel(
                  items: snakeSpeedItems, 
                  gap:16, 
                  selectedValue: settings.snakeSpeed,
                  onItemSelected: onSpeedSelected)),
            
            
                _listViewItemWrap(Carousel<Pair<Color,Color>>(
                  items: snakeColorItems(), 
                  gap:16, 
                  selectedValue: Pair(settings.theme.snakeColor1, settings.theme.snakeColor2),
                  onItemSelected: onSnakeColorSelected)),
            
                const SizedBox(height:24, width:16),
                
                SizedBox(
                  width:500,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow), 
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text('Start', style: Theme.of(context).textTheme.headline5!.apply(color: Colors.white) ),
                        ),
                        onPressed: (){onStartClicked(context);}, 
                      )
                    ]
                  ),
                ),
              ]
            ),
          ),
        )),
    );


  }
}


