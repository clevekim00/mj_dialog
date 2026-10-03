import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Shared code-native pixel art. Text and controls keep normal readable fonts.
class PixelGameArt {
  static const ink = Color(0xff263652);
  static void sprite(
    Canvas canvas,
    Offset origin,
    double pixel,
    List<String> rows,
    Map<String, Color> palette,
  ) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final color = palette[rows[y][x]];
        if (color != null) {
          canvas.drawRect(
            Rect.fromLTWH(
              (origin.dx + x * pixel).roundToDouble(),
              (origin.dy + y * pixel).roundToDouble(),
              pixel.ceilToDouble(),
              pixel.ceilToDouble(),
            ),
            paint..color = color,
          );
        }
      }
    }
  }

  static void cat(
    Canvas canvas,
    Offset feet, {
    bool white = false,
    bool duck = false,
    bool stride = false,
    double pixel = 4,
  }) {
    canvas.save();
    canvas.translate(feet.dx - 10 * pixel, feet.dy - (duck ? 8 : 13) * pixel);
    if (duck) canvas.scale(1, 8 / 13);
    sprite(
      canvas,
      Offset.zero,
      pixel,
      const [
        '             o   o  ',
        '             opoopo ',
        '             oooooo ',
        ' oo          ooioio ',
        ' oo    ooooooooooko ',
        '  oo  oooosoooowwoo ',
        '   ooooooosoooooooo ',
        '    oooooosooooooo  ',
        '    ooooooooooooo   ',
        '     ooooooooooo    ',
        '     oo oo  oo oo   ',
      ],
      {
        'o': white ? const Color(0xfff4f0e8) : const Color(0xffffc34b),
        's': white ? const Color(0xffc9d2de) : const Color(0xffd58a28),
        'p': const Color(0xffec9ca6),
        'i': ink,
        'k': const Color(0xffb75c76),
        'w': Colors.white,
      },
    );
    final paint = Paint()
      ..color = white ? const Color(0xffc9d2de) : const Color(0xffd58a28);
    for (final x in [5, 8, 12, 15]) {
      final offset = stride ? (x.isEven ? 1 : -1) : 0;
      canvas.drawRect(
        Rect.fromLTWH((x + offset) * pixel, 11 * pixel, 2 * pixel, 2 * pixel),
        paint,
      );
    }
    canvas.restore();
  }

  static void kid(
    Canvas canvas,
    Offset feet, {
    double pixel = 4,
    bool duck = false,
    bool stride = false,
  }) {
    // Teal baseball cap, dark hair, peach cheeks, yellow T-shirt, navy shorts.
    // No moustache, overalls or white gloves.
    const rows = [
      '.....TTTTT......',
      '....TTWTTTT.....',
      '....TTTTTTTTTT..',
      '....HHSSSS......',
      '...HHSSKSSSS....',
      '...HHSSSSSSSS...',
      '....SSPSSSS.....',
      '.....SSSS.......',
      '....YYYYYY......',
      '...SYYYYYYS.....',
      '...SYYYYYYS.....',
      '....YYYYYY......',
      '....BBBBBB......',
      '....BB..BB......',
      '....SS..SS......',
    ];
    canvas.save();
    canvas.translate(feet.dx - 8 * pixel, feet.dy - (duck ? 10 : 17) * pixel);
    if (duck) canvas.scale(1, 10 / 17);
    sprite(canvas, Offset.zero, pixel, rows, const {
      'T': Color(0xff258e91),
      'W': Color(0xfffff3c5),
      'H': Color(0xff4c3938),
      'S': Color(0xffffd0a6),
      'K': ink,
      'P': Color(0xffef9f94),
      'Y': Color(0xffffce55),
      'B': Color(0xff415783),
    });
    final paint = Paint()
      ..color = const Color(0xffd65e53)
      ..isAntiAlias = false;
    canvas.drawRect(
      Rect.fromLTWH((stride ? 2 : 3) * pixel, 15 * pixel, 4 * pixel, 2 * pixel),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH((stride ? 9 : 8) * pixel, 15 * pixel, 4 * pixel, 2 * pixel),
      paint,
    );
    canvas.restore();
  }

  static void bird(Canvas canvas, Offset center, {bool flap = false}) {
    sprite(
      canvas,
      center - const Offset(32, 24),
      4,
      [
        '......YYYY......',
        '....YYYYYYYY....',
        '...YYYYYYKYOO...',
        flap ? '.WWYYYYYYYYOO...' : '...YYYWWYYYOO...',
        flap ? 'WWWWYYYYYYY.....' : '..YYYYWWYYYY....',
        '...YYYYYYYY.....',
        '.....YYYY.......',
      ],
      const {
        'Y': Color(0xffffce55),
        'W': Color(0xffffedb8),
        'K': ink,
        'O': Color(0xffee895c),
      },
    );
  }

  static void star(Canvas canvas, Offset center) => sprite(
    canvas,
    center - const Offset(10, 10),
    4,
    const ['..Y..', '.YYY.', 'YYYYY', '.YYY.', '.Y.Y.'],
    const {'Y': Color(0xffffce55)},
  );
  static void scenery(
    Canvas canvas,
    Size size, {
    double scroll = 0,
    bool night = false,
  }) {
    final paint = Paint()..isAntiAlias = false;
    canvas.drawRect(
      Offset.zero & size,
      paint..color = night ? const Color(0xff142439) : const Color(0xffb9e0ed),
    );
    for (var i = 0; i < 5; i++) {
      final x =
          (((i * .27 - scroll * .02) % 1.35) * size.width / 4).floor() * 4.0;
      sprite(
        canvas,
        Offset(x, 24 + (i % 2) * 28),
        6,
        const ['..WWWW....', '.WWWWWWW..', 'WWWWWWWWWW', '.WWWWWWWW.'],
        {'W': night ? const Color(0xff213a53) : const Color(0xfffff7e5)},
      );
    }
    final ground = (size.height * .8 / 4).floor() * 4.0;
    canvas.drawRect(
      Rect.fromLTWH(0, ground, size.width, size.height - ground),
      paint..color = night ? const Color(0xff234849) : const Color(0xff62956c),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, ground + 8, size.width, size.height - ground - 8),
      paint..color = night ? const Color(0xff263247) : const Color(0xffb88464),
    );
    for (var i = 0; i < size.width / 24 + 2; i++) {
      final x = ((i * 24 - scroll * 20) % (size.width + 24) / 4).floor() * 4.0;
      canvas.drawRect(
        Rect.fromLTWH(x, ground + 16, 8, 4),
        paint
          ..color = night ? const Color(0xff344258) : const Color(0xffd3a780),
      );
    }
  }
}

class PixelGameBackdrop extends CustomPainter {
  const PixelGameBackdrop({this.night = false});
  final bool night;
  @override
  void paint(Canvas canvas, Size size) =>
      PixelGameArt.scenery(canvas, size, night: night);
  @override
  bool shouldRepaint(covariant PixelGameBackdrop oldDelegate) =>
      oldDelegate.night != night;
}

class PixelGameMascot extends StatelessWidget {
  const PixelGameMascot({
    super.key,
    this.active = false,
    this.cheering = false,
  });
  final bool cheering;
  final bool active;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 180,
    child: TweenAnimationBuilder<double>(
      key: ValueKey(cheering),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (_, value, _) => CustomPaint(
        painter: _MascotPainter(
          active,
          cheering ? math.sin(value * math.pi) * 18 : 0,
          cheering,
        ),
      ),
    ),
  );
}

class _MascotPainter extends CustomPainter {
  _MascotPainter(this.active, this.hop, this.cheering);
  final double hop;
  final bool cheering;
  final bool active;
  @override
  void paint(Canvas canvas, Size size) {
    PixelGameArt.scenery(canvas, size, night: true);
    PixelGameArt.cat(
      canvas,
      Offset(size.width / 2, size.height * .8 - hop),
      pixel: 5,
      stride: active,
    );
    if (active || cheering) PixelGameArt.star(canvas, const Offset(140, 40));
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.active != active ||
      oldDelegate.hop != hop ||
      oldDelegate.cheering != cheering;
}
