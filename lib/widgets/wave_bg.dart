import 'package:flutter/material.dart';

class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WavePainter(),
      child: Container(),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final width = size.width;

    final paint1 = Paint()..color = Colors.deepPurple.shade500.withOpacity(0.5);
    final path1 = Path()
      ..lineTo(0, height * 0.7)
      ..quadraticBezierTo(width * 0.25, height * 0.6, width * 0.5, height * 0.75)
      ..quadraticBezierTo(width * 0.75, height * 0.9, width, height * 0.7)
      ..lineTo(width, 0)
      ..close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()..color = Colors.deepPurple.shade200.withOpacity(0.6);
    final path2 = Path()
      ..lineTo(0, height * 0.8)
      ..quadraticBezierTo(width * 0.3, height, width * 0.6, height * 0.85)
      ..quadraticBezierTo(width * 0.9, height * 0.7, width, height * 0.9)
      ..lineTo(width, 0)
      ..close();
    canvas.drawPath(path2, paint2);


  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
