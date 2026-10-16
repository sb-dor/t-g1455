import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

/// The page background, declared to the glass: the diagonal gradient with the
/// two soft glows, drawn exactly as they appear on screen. One palette per
/// [brightness].
class TodoBackdropPainter extends GlassProxyPainter {
  const TodoBackdropPainter({this.brightness = Brightness.dark});

  final Brightness brightness;

  static const LinearGradient _darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF11131C), Color(0xFF252044), Color(0xFF172F3D)],
  );

  static const LinearGradient _lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF5F3FF), Color(0xFFE8E2FA), Color(0xFFDCEFEF)],
  );

  bool get _light => brightness == Brightness.light;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    final LinearGradient gradient = _light ? _lightGradient : _darkGradient;
    canvas.drawRect(box, Paint()..shader = gradient.createShader(box));
    _glow(
      canvas,
      _light ? const Color(0x557C5CFC) : const Color(0x667C5CFC),
      Rect.fromLTWH(size.width + 70 - 240, 110, 240, 240),
    );
    _glow(
      canvas,
      _light ? const Color(0x5543D9AD) : const Color(0x5543D9AD),
      Rect.fromLTWH(-90, size.height - 80 - 270, 270, 270),
    );
  }

  static void _glow(Canvas canvas, Color color, Rect rect) => canvas.drawCircle(
    rect.center,
    rect.width / 2,
    Paint()
      ..shader = RadialGradient(
        colors: <Color>[color, color.withValues(alpha: 0)],
      ).createShader(rect),
  );

  @override
  bool shouldRepaint(TodoBackdropPainter oldPainter) =>
      oldPainter.brightness != brightness;

  @override
  bool get isOpaque => true;
}

const TodoBackdropPainter kTodoBackdrop = TodoBackdropPainter();

const TodoBackdropPainter kTodoBackdropLight = TodoBackdropPainter(
  brightness: Brightness.light,
);

/// The average colour of each palette, for `GlassHost.backdrop`.
const Color kTodoBackdropColor = Color(0xFF11131C);
const Color kTodoBackdropLightColor = Color(0xFFE8E4F6);

TodoBackdropPainter todoBackdropFor(Brightness brightness) =>
    brightness == Brightness.light ? kTodoBackdropLight : kTodoBackdrop;
