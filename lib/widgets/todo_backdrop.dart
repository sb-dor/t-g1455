import 'package:flutter/material.dart';
import 'package:g1455/g1455.dart';

/// The page background, declared to the glass: the diagonal gradient with the
/// two soft glows, drawn exactly as they appear on screen.
class TodoBackdropPainter extends GlassProxyPainter {
  const TodoBackdropPainter();

  static const LinearGradient _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF11131C), Color(0xFF252044), Color(0xFF172F3D)],
  );

  @override
  void paint(Canvas canvas, Size size) {
    final Rect box = Offset.zero & size;
    canvas.drawRect(box, Paint()..shader = _gradient.createShader(box));
    _glow(
      canvas,
      const Color(0x667C5CFC),
      Rect.fromLTWH(size.width + 70 - 240, 110, 240, 240),
    );
    _glow(
      canvas,
      const Color(0x5543D9AD),
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
  bool shouldRepaint(TodoBackdropPainter oldPainter) => false;

  @override
  bool get isOpaque => true;
}

const TodoBackdropPainter kTodoBackdrop = TodoBackdropPainter();
