import 'package:flutter/material.dart';

class PixelCutBorder extends ShapeBorder {
  const PixelCutBorder({required this.color, this.width = 1, this.cut = 6});

  final Color color;
  final double width;
  final double cut;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(width));

  Path _path(Rect rect) {
    final inset = cut.clamp(0, rect.shortestSide / 2).toDouble();
    return Path()
      ..moveTo(rect.left + inset, rect.top)
      ..lineTo(rect.right - inset, rect.top)
      ..lineTo(rect.right, rect.top + inset)
      ..lineTo(rect.right, rect.bottom - inset)
      ..lineTo(rect.right - inset, rect.bottom)
      ..lineTo(rect.left + inset, rect.bottom)
      ..lineTo(rect.left, rect.bottom - inset)
      ..lineTo(rect.left, rect.top + inset)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (width <= 0) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      Paint()
        ..isAntiAlias = false
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      PixelCutBorder(color: color, width: width * t, cut: cut * t);
}
