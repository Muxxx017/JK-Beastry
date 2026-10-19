import 'package:flutter/material.dart';
import 'package:zoology_app/theme/bestiary_theme.dart';

class FieldLandscape extends StatelessWidget {
  const FieldLandscape({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _FieldLandscapePainter(),
      child: SizedBox.expand(),
    );
  }
}

class _FieldLandscapePainter extends CustomPainter {
  const _FieldLandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF536A57), BestiaryPalette.forest],
      ).createShader(rect);
    canvas.drawRect(rect, background);

    final sunCenter = Offset(size.width * .79, size.height * .28);
    canvas.drawCircle(
      sunCenter,
      size.shortestSide * .11,
      Paint()..color = const Color(0xFFD7BD87).withValues(alpha: .76),
    );

    final distant = Path()
      ..moveTo(0, size.height * .65)
      ..lineTo(size.width * .20, size.height * .29)
      ..lineTo(size.width * .30, size.height * .45)
      ..lineTo(size.width * .48, size.height * .19)
      ..lineTo(size.width * .69, size.height * .56)
      ..lineTo(size.width * .84, size.height * .37)
      ..lineTo(size.width, size.height * .60)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(distant, Paint()..color = const Color(0xFF89957C));

    final mid = Path()
      ..moveTo(0, size.height * .73)
      ..lineTo(size.width * .25, size.height * .49)
      ..lineTo(size.width * .43, size.height * .68)
      ..lineTo(size.width * .72, size.height * .42)
      ..lineTo(size.width, size.height * .67)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(mid, Paint()..color = const Color(0xFF63765F));

    final valley = Path()
      ..moveTo(0, size.height * .82)
      ..lineTo(size.width * .17, size.height * .68)
      ..lineTo(size.width * .34, size.height * .78)
      ..lineTo(size.width * .57, size.height * .59)
      ..lineTo(size.width * .76, size.height * .75)
      ..lineTo(size.width, size.height * .62)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(valley, Paint()..color = const Color(0xFF334D3B));

    final contour = Paint()
      ..color = const Color(0xFFD8DDCA).withValues(alpha: .26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final line = Path()
        ..moveTo(size.width * (index * .22 - .12), size.height)
        ..quadraticBezierTo(
          size.width * .50,
          size.height * (.75 + index * .035),
          size.width * (1.14 - index * .18),
          size.height,
        );
      canvas.drawPath(line, contour);
    }
  }

  @override
  bool shouldRepaint(covariant _FieldLandscapePainter oldDelegate) => false;
}
