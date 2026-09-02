import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Hand-drawn line glyphs from the design, painted from their SVG viewBoxes
/// so stroke weights stay proportional at any render size.
class Glyph extends StatelessWidget {
  const Glyph._(this._painter, this.width, this.height);

  /// Magnifier, 14×14 viewBox.
  factory Glyph.search({double size = 14}) =>
      Glyph._(const _SearchPainter(), size, size);

  /// Crossed-out picture frame, 22×22 viewBox. [withScene] adds the
  /// mountain line used on the hero fallback.
  factory Glyph.brokenImage({double size = 22, bool withScene = false}) =>
      Glyph._(_BrokenImagePainter(withScene: withScene), size, size);

  /// Crossed-out wifi arcs, 34×34 viewBox.
  factory Glyph.wifiOff({double size = 34}) =>
      Glyph._(const _WifiOffPainter(), size, size);

  /// Circle with exclamation, 34×34 viewBox, critical colour.
  factory Glyph.alert({double size = 34}) =>
      Glyph._(const _AlertPainter(), size, size);

  /// 2×2 grid (Explore tab), 15×15 viewBox rendered at 18.
  factory Glyph.grid({required Color color, double size = 18}) =>
      Glyph._(_GridPainter(color), size, size);

  /// Heart outline (Favourites tab), 15×14 viewBox rendered at 19×18.
  factory Glyph.heart({required Color color}) =>
      Glyph._(_HeartPainter(color), 19, 18);

  /// Person (Profile tab), 16×16 viewBox rendered at 18.
  factory Glyph.person({required Color color, double size = 18}) =>
      Glyph._(_PersonPainter(color), size, size);

  final _ViewBoxPainter _painter;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _painter);
  }
}

abstract class _ViewBoxPainter extends CustomPainter {
  const _ViewBoxPainter(this.viewBox);

  final Size viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / viewBox.width, size.height / viewBox.height);
    paintViewBox(canvas);
  }

  void paintViewBox(Canvas canvas);

  @override
  bool shouldRepaint(covariant _ViewBoxPainter oldDelegate) => false;

  static Paint stroke(Color color, double width) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;
  }

  static Paint fill(Color color) => Paint()..color = color;
}

class _SearchPainter extends _ViewBoxPainter {
  const _SearchPainter() : super(const Size(14, 14));

  @override
  void paintViewBox(Canvas canvas) {
    final paint = _ViewBoxPainter.stroke(AppColors.ink, 1.2);
    canvas.drawCircle(const Offset(6, 6), 4.6, paint);
    canvas.drawLine(const Offset(9.5, 9.5), const Offset(13, 13), paint);
  }
}

class _BrokenImagePainter extends _ViewBoxPainter {
  const _BrokenImagePainter({required this.withScene})
    : super(const Size(22, 22));

  final bool withScene;

  @override
  void paintViewBox(Canvas canvas) {
    final frame = _ViewBoxPainter.stroke(AppColors.rule28, 1.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1, 3, 20, 16),
        const Radius.circular(1.5),
      ),
      frame,
    );
    if (withScene) {
      final scene = Path()
        ..moveTo(1, 15)
        ..relativeLineTo(5.5, -4.5)
        ..relativeLineTo(4, 3.5)
        ..relativeLineTo(3.5, -3)
        ..relativeLineTo(7, 6);
      canvas.drawPath(scene, frame);
    }
    canvas.drawLine(
      const Offset(2, 2),
      const Offset(20, 20),
      _ViewBoxPainter.stroke(AppColors.rule40, 1.3),
    );
  }

  @override
  bool shouldRepaint(covariant _BrokenImagePainter oldDelegate) =>
      oldDelegate.withScene != withScene;
}

class _WifiOffPainter extends _ViewBoxPainter {
  const _WifiOffPainter() : super(const Size(34, 34));

  @override
  void paintViewBox(Canvas canvas) {
    final arcs = _ViewBoxPainter.stroke(AppColors.rule25, 1.4);
    canvas.drawPath(
      Path()
        ..moveTo(4, 13)
        ..arcToPoint(const Offset(30, 13), radius: const Radius.circular(18)),
      arcs,
    );
    canvas.drawPath(
      Path()
        ..moveTo(9.5, 18.5)
        ..arcToPoint(
          const Offset(24.5, 18.5),
          radius: const Radius.circular(11),
        ),
      arcs,
    );
    canvas.drawCircle(
      const Offset(17, 25),
      2,
      _ViewBoxPainter.fill(AppColors.rule35),
    );
    canvas.drawLine(
      const Offset(3, 3),
      const Offset(31, 31),
      _ViewBoxPainter.stroke(AppColors.ink, 1.4),
    );
  }
}

class _AlertPainter extends _ViewBoxPainter {
  const _AlertPainter() : super(const Size(34, 34));

  @override
  void paintViewBox(Canvas canvas) {
    canvas.drawCircle(
      const Offset(17, 17),
      15,
      _ViewBoxPainter.stroke(AppColors.critical, 1.4),
    );
    canvas.drawLine(
      const Offset(17, 9),
      const Offset(17, 20),
      _ViewBoxPainter.stroke(AppColors.critical, 1.6),
    );
    canvas.drawCircle(
      const Offset(17, 24.5),
      1.4,
      _ViewBoxPainter.fill(AppColors.critical),
    );
  }
}

class _GridPainter extends _ViewBoxPainter {
  const _GridPainter(this.color) : super(const Size(15, 15));

  final Color color;

  @override
  void paintViewBox(Canvas canvas) {
    final paint = _ViewBoxPainter.stroke(color, 1.4);
    for (final origin in const <Offset>[
      Offset(1, 1),
      Offset(8.6, 1),
      Offset(1, 8.6),
      Offset(8.6, 8.6),
    ]) {
      canvas.drawRect(origin & const Size(5.4, 5.4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HeartPainter extends _ViewBoxPainter {
  const _HeartPainter(this.color) : super(const Size(15, 14));

  final Color color;

  @override
  void paintViewBox(Canvas canvas) {
    final path = Path()
      ..moveTo(7.5, 13.2)
      ..cubicTo(7.5, 13.2, 0.8, 9.3, 0.8, 4.9)
      ..arcToPoint(const Offset(7.5, 2.4), radius: const Radius.circular(4))
      ..arcToPoint(const Offset(14.2, 4.9), radius: const Radius.circular(4))
      ..cubicTo(14.2, 9.3, 7.5, 13.2, 7.5, 13.2)
      ..close();
    canvas.drawPath(path, _ViewBoxPainter.stroke(color, 1.4));
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PersonPainter extends _ViewBoxPainter {
  const _PersonPainter(this.color) : super(const Size(16, 16));

  final Color color;

  @override
  void paintViewBox(Canvas canvas) {
    final paint = _ViewBoxPainter.stroke(color, 1.4);
    canvas.drawCircle(const Offset(8, 5.4), 3.1, paint);
    final shoulders = Path()
      ..moveTo(2.4, 15)
      ..cubicTo(2.4, 11.9, 4.9, 10.3, 8, 10.3)
      ..cubicTo(11.1, 10.3, 13.6, 11.9, 13.6, 15);
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _PersonPainter oldDelegate) =>
      oldDelegate.color != color;
}
