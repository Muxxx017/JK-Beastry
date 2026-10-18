import 'package:flutter/material.dart';

class BestiaryMark extends StatelessWidget {
  final double size;

  const BestiaryMark({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _BestiaryMarkPainter()),
    );
  }
}

class _BestiaryMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale);

    final badge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 100, 100),
      const Radius.circular(25),
    );
    canvas.drawRRect(badge, Paint()..color = const Color(0xFF263E31));
    canvas.save();
    canvas.clipRRect(badge);
    canvas.drawCircle(
      const Offset(50, 39),
      21,
      Paint()..color = const Color(0xFFDAB56C),
    );

    final farRidge = Path()
      ..moveTo(0, 74)
      ..lineTo(30, 41)
      ..lineTo(48, 61)
      ..lineTo(68, 43)
      ..lineTo(100, 76)
      ..lineTo(100, 100)
      ..lineTo(0, 100)
      ..close();
    canvas.drawPath(farRidge, Paint()..color = const Color(0xFF9BA98E));
    final nearRidge = Path()
      ..moveTo(0, 82)
      ..lineTo(27, 61)
      ..lineTo(48, 76)
      ..lineTo(71, 58)
      ..lineTo(100, 83)
      ..lineTo(100, 100)
      ..lineTo(0, 100)
      ..close();
    canvas.drawPath(nearRidge, Paint()..color = const Color(0xFF526E51));

    final antlers = Paint()
      ..color = const Color(0xFFF4E7C5)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final antlerLines = Path()
      ..moveTo(49, 62)
      ..lineTo(42, 54)
      ..lineTo(39, 44)
      ..moveTo(42, 54)
      ..lineTo(32, 51)
      ..moveTo(39, 44)
      ..lineTo(42, 38)
      ..moveTo(39, 44)
      ..lineTo(33, 41)
      ..moveTo(51, 62)
      ..lineTo(58, 54)
      ..lineTo(61, 44)
      ..moveTo(58, 54)
      ..lineTo(68, 51)
      ..moveTo(61, 44)
      ..lineTo(58, 38)
      ..moveTo(61, 44)
      ..lineTo(67, 41);
    canvas.drawPath(antlerLines, antlers);

    final head = Path()
      ..moveTo(44, 60)
      ..lineTo(40, 64)
      ..lineTo(44, 68)
      ..lineTo(47, 78)
      ..lineTo(50, 83)
      ..lineTo(53, 78)
      ..lineTo(56, 68)
      ..lineTo(60, 64)
      ..lineTo(56, 60)
      ..lineTo(50, 63)
      ..close();
    canvas.drawPath(head, Paint()..color = const Color(0xFFF4E7C5));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
