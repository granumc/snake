
import 'dart:math';
import 'dart:ui';

import 'package:flutter/animation.dart';

import 'utils.dart';



void _drawExplodingCircle(Canvas canvas, Rect rect, double t, Paint paint) {
  // final double radiusFraction = t;
  final double radiusFraction = slerp(0, 1, 0, 0.7, t);
  final double ang = slerp(pi/2, 0, 0.6, 1, t);

  if (radiusFraction == 0) return;

  final r = Rect.fromCenter(
      center: rect.center,
      width: rect.width * radiusFraction,
      height: rect.height * radiusFraction);

  if(ang == pi/2) {
    canvas.drawOval(r, paint);
    return;
  }

  for(double a=0; a<2*pi;  a += pi/2){
    final startAngle = a - ang / 2;
    final sweepAngle = ang;
    canvas.drawArc(r, startAngle, sweepAngle, false, paint);
  }

}



void _drawFlare(
  Canvas canvas, 
  Rect rect, 
  double t, 
  Paint paint, { 
  bool drawBigFlare=true,
  bool drawSmallFlare=true,
  bool drawCircle=true}) {

  if (t <= 0) return;

  const east = Offset(1, 0);
  const west = Offset(-1, 0);
  const north = Offset(0, -1);
  const south = Offset(0, 1);

  const se = Offset(0.6, 0.6) ;
  const sw = Offset(-0.6, 0.6);
  const ne = Offset(0.6, -0.6);
  const nw = Offset(-0.6, -0.6);

  final hw = (rect.width / 2);
  final hh = (rect.height / 2);

  final c = rect.center;

  if (drawBigFlare) {
    final startFrac = slerp(0, 1, 0.5, 0.8, t);
    final endFrac = slerp(0, 1, 0, 0.5, t);

    final e1 = c + (east * startFrac * hw);
    final e2 = c + (east * endFrac * hw);
    canvas.drawLine(e1, e2, paint);

    final w1 = c + (west * startFrac * hw);
    final w2 = c + (west * endFrac * hw);
    canvas.drawLine(w1, w2, paint);

    final n1 = c + (north * startFrac * hh);
    final n2 = c + (north * endFrac * hh);
    canvas.drawLine(n1, n2, paint);

    final s1 = c + (south * startFrac * hh);
    final s2 = c + (south * endFrac * hh);
    canvas.drawLine(s1, s2, paint);
  }

  if (drawSmallFlare) {
    final startFracS = slerp(0, 1, 0.5, 0.8, t);
    final endFracS = slerp(0, 1, 0.2, 0.5, t);

    final ne1 = c + (ne * startFracS * hw);
    final ne2 = c + (ne * endFracS * hw);
    canvas.drawLine(ne1, ne2, paint);

    final nw1 = c + (nw * startFracS * hw);
    final nw2 = c + (nw * endFracS * hw);
    canvas.drawLine(nw1, nw2, paint);

    final sw1 = c + (sw * startFracS * hw);
    final sw2 = c + (sw * endFracS * hw);
    canvas.drawLine(sw1, sw2, paint);

    final se1 = c + (se * startFracS * hw);
    final se2 = c + (se * endFracS * hw);
    canvas.drawLine(se1, se2, paint);
  }

  if (drawCircle) {
    final exc = slerp(0, 1, 0.5, 0.9, t);
    _drawExplodingCircle(canvas, rect.deflate(rect.width * 0.1), exc, paint);
  }
}



Path _createStarPath(Size size, int tips, double smoothness, double angle) {
  assert(tips >= 3);
  assert((smoothness >= 0) && (smoothness <= 1));

  final Rect rect = Rect.fromLTWH(
      -size.width/2, -size.height/2, size.width, size.height);
  Path res = Path();

  final hw = rect.width / 2;
  final hh = rect.height / 2;

  final shw = hw * smoothness;
  final shh = hh * smoothness;

  final c = rect.center;
  final dAngle = (2 * pi / tips);

  for(int i=0; i<tips; i++) {
    final angle1 = (angle) + (2 * pi * (i/tips));
    final x1 = c.dx + cos(angle1) * hw;
    final y1 = c.dy + sin(angle1) * hh;
    (i == 0) ? res.moveTo(x1, y1) : res.lineTo(x1, y1);

    final angle2 = angle1 + dAngle/2;
    final x2 = c.dx + cos(angle2) * shw;
    final y2 = c.dy + sin(angle2) * shh;
    res.lineTo(x2, y2);
  }

  res.close();
  return res;
}



abstract class Particle {

  Particle() {
    paint = Paint()..color=color.begin!;
  }

  
  Tween<Offset> pos = Tween<Offset>(begin:Offset.zero, end: Offset.zero);
  Curve posCurve = Curves.linear;

  Tween<double> scale = Tween<double>(begin:1, end:1);
  Curve scaleCurve = Curves.linear;

  Tween<double> angle = Tween<double>(begin:0, end:0);
  Curve angleCurve = Curves.linear;

  ColorTween color = ColorTween(
    begin: const Color.fromARGB(255, 255, 255, 255), 
    end: const Color.fromARGB(255, 255, 255, 255));

  Curve colorCurve = Curves.linear;

  Curve paintCurve = Curves.linear;

  late Paint paint;

  Offset get rotationCenter => Offset.zero;


  void drawParticle(Canvas canvas, Paint paint, double t);


  void draw(Canvas canvas, double t) {
    canvas.save();
    final p = pos.transform(posCurve.transform(t));
    canvas.translate(p.dx, p.dy);

    final ang = angle.transform(angleCurve.transform(t));
    if (ang != 0) {
      final rc = rotationCenter;
      canvas.translate(rc.dx, rc.dy);
      canvas.rotate(ang);
      canvas.translate(-rc.dx, -rc.dy);
    }

    final sc = scale.transform(scaleCurve.transform(t));
    if(sc != 1) {
      canvas.scale(sc);
    }

    paint.color = color.transform(colorCurve.transform(t))!;

    drawParticle(canvas, paint, paintCurve.transform(t));

    canvas.restore();
  }

}


class ExplodingCircleParticle extends Particle {

  ExplodingCircleParticle(Size size)
      : _rect = Rect.fromLTWH(-size.width/2, -size.height/2,
        size.width, size.height);

  final Rect _rect;

  @override
  void drawParticle(Canvas canvas, Paint paint, double t) {
    _drawExplodingCircle(canvas, _rect, t, paint);
  }

}


class FlareParticle extends Particle {

  FlareParticle(Size size, {
    this.drawBigFlare = true,
    this.drawSmallFlare = true,
    this.drawCirle = true 
    }) 
    : _rect = Rect.fromLTWH(-size.width/2, -size.height/2,
      size.width, size.height);

  final Rect _rect;
  bool drawBigFlare;
  bool drawSmallFlare;
  bool drawCirle;

  @override
  void drawParticle(Canvas canvas, Paint paint, double t) {
    _drawFlare (
        canvas, _rect, t, paint,
        drawBigFlare: drawBigFlare,
        drawSmallFlare: drawSmallFlare,
        drawCircle: drawCirle);
  }

}


class StarParticle extends Particle {
  StarParticle(
    Size size, 
    int tips, 
    double smoothness, [
    double angle = 0
    ]) : _starPath = _createStarPath(size, tips, smoothness, angle);

  final Path _starPath;

  @override
  void drawParticle(Canvas canvas, Paint paint, double t) {
    canvas.drawPath(_starPath, paint);
  }
}


class Fountain {

  Fountain({
    required int particleCount,
    required this.particleSize,
    required Offset aperture,
    required double apertureSize,
    required this.direction,
    this.spreadAngle = pi/2,
    required this.heightMin,
    required this.heightMax,
  }) :  assert(particleCount > 0),
        assert(apertureSize > 0.0),
        assert(!((direction.dx==0.0 && direction.dy==0.0))),
        assert(heightMin > 0.0),
        assert(heightMin <= heightMax)
  {
    // find perpendicular line to the direction
    final directionLength = direction.distance;
    final ratio = (apertureSize / 2) / directionLength;
    aperture1 = aperture + Offset(direction.dy, -direction.dx) * ratio ;
    aperture2 = aperture + Offset(-direction.dy, direction.dx) * ratio ;

    createParticles(particleCount);
  }

  final List<Particle> _particles = [];

  // edge points of the aperture
  late final Offset aperture1;
  late final Offset aperture2;

  // direction of the fountain
  final Offset direction;
  final double spreadAngle;
  final double heightMin;
  final double heightMax;
  final Size particleSize;


  void createParticles(int particleCount){
    assert(particleCount > 0);

    final ang = spreadAngle / 2;
    final a1 = angleToOXSigned(direction) - ang;
    final a2 = angleToOXSigned(direction) + ang;

    final rand = Random.secure();
    for (int i=0; i<particleCount; i++) {
      final p = StarParticle(particleSize, 4+rand.nextInt(4), 0.4);

      final r = rand.nextDouble();
      p.pos.begin = Offset.lerp(aperture1, aperture2, r);
      final a = lerp(a1, a2, r);
      final len = lerp(heightMin, heightMax, rand.nextDouble());
      p.pos.end = p.pos.begin! + Offset(cos(a)*len, sin(a)*len);
      p.posCurve = Curves.easeOut;

      p.scale.end = lerp(1,2, rand.nextDouble());
      p.scaleCurve = Curves.easeInQuad;

      // p.angle.begin=lerp(-pi, pi, rand.nextDouble());
      // p.angle.end=lerp(-pi, pi, rand.nextDouble());

      p.paint.style = (rand.nextDouble() > 0.5) ? PaintingStyle.stroke : PaintingStyle.fill;
      p.paint.strokeWidth=1;
      p.color.begin = const Color.fromARGB(255, 255, 255, 255);
      p.color.end = p.color.begin!.withAlpha(0);
      p.colorCurve = Interval(0.4, 0.4+0.6  *rand.nextDouble(), curve: Curves.easeInQuart );

      _particles.add(p);
    }

  }

  void draw(Canvas canvas, double t) {
    for(final p in _particles) {
      p.draw(canvas, t);
    }
  }

  // used fot test purpose only
  void drawTest(Canvas canvas, double t) {
    final m1 = Offset.lerp(aperture1, aperture2, 0.5)!;
    var m2 = direction * (heightMax / direction.distance);
    m2 = m1 + m2;
    late  Offset aperture1p;
    late  Offset aperture2p;
    Paint paint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..strokeWidth = 3;

    final ang = spreadAngle / 2;
    aperture1p = Offset(
        direction.dx * cos(ang) + direction.dy * sin(ang),
        -direction.dx * sin(ang) + direction.dy * cos(ang));
    aperture2p = Offset(
        direction.dx * cos(ang) - direction.dy * sin(ang),
        direction.dx * sin(ang) + direction.dy * cos(ang));

    final directionLength = direction.distance;
    aperture1p = aperture1p * (heightMax/directionLength);
    aperture2p = aperture2p * (heightMax/directionLength);

    final v1 = m1 + aperture1p;
    final v2 = m1 + aperture2p;

    canvas.drawLine(aperture1, aperture2, paint);
    canvas.drawLine(m1, m2, paint);
    // canvas.drawLine(m1, v1, paint);
    // canvas.drawLine(m1, v2, paint);

    canvas.drawLine(aperture1, aperture1+(v1-m1), paint);
    canvas.drawLine(aperture2, aperture2+(v2-m1), paint);
  }


}


class Aftershock {

  Aftershock(
    this.rect, {
    required int particleCount,  
    required this.particleSize,
    this.particleColor = const Color(0xFFFFFFFF)}) {
    createParticles(particleCount);
  }

  Rect rect;
  final List<Particle> _particles = [];
  final double particleSize;
  final Color particleColor;


  void createParticles(int particleCount){
    final rand = Random.secure();
    for (int i=0; i<particleCount; i++) {

      final p = rand.nextDouble() >= 0.7
          ? ExplodingCircleParticle(Size(particleSize, particleSize))
          : FlareParticle(Size(particleSize, particleSize), drawSmallFlare: false);

      final pos = Offset(lerp(rect.left, rect.right, rand.nextDouble()),
          lerp(rect.top, rect.bottom, rand.nextDouble()));

      p.pos.begin = p.pos.end = pos;

      final ttlA = 0.4 * rand.nextDouble();
      final ttlB = ttlA + 0.3 + (0.7-ttlA) * rand.nextDouble();
      p.paintCurve = Interval(ttlA, ttlB);

      p.paint.style = PaintingStyle.stroke;
      p.paint.strokeWidth = 3;
      p.color.begin = p.color.end = particleColor;

      _particles.add(p);
    }
  }

  void draw(Canvas canvas, double t) {
    for(final p in _particles) {
      p.draw(canvas, t);
    }
  }

}

