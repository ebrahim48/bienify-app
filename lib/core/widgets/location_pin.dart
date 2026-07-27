import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// The 64×79 map-pin illustration on the location-permission screen: a solid
/// teardrop with a knocked-out centre, sitting on an elliptical ring.
///
/// Painted instead of imported so it inherits the theme colour and stays
/// crisp at every density.
class LocationPin extends StatelessWidget {
  const LocationPin({
    super.key,
    this.color = AppColors.authInk,
    this.width = AppSizes.locationPinWidth,
    this.height = AppSizes.locationPinHeight,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
      height: height.h,
      child: CustomPaint(painter: _LocationPinPainter(color: color)),
    );
  }
}

class _LocationPinPainter extends CustomPainter {
  const _LocationPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry is expressed against the 64×79 design box and scaled.
    final sx = size.width / 64;
    final sy = size.height / 79;

    final paint = Paint()..color = color;

    // ─── Base ring ─────────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(32 * sx, 65.5 * sy),
        width: 62 * sx,
        height: 27 * sy,
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * sx,
    );

    // ─── Teardrop ──────────────────────────────────────────────────────────
    const cx = 32.0;
    const cy = 24.0;
    const r = 24.0;
    const tipY = 70.0;
    const d = tipY - cy;

    // Tangent points from the tip to the head circle.
    final tangentAngle = math.atan2(r * r / d, r * math.sqrt(d * d - r * r) / d);

    final headRect = Rect.fromCircle(
      center: Offset(cx * sx, cy * sy),
      radius: r * sx,
    );

    // `evenOdd` turns the inner circle into a hole, so the page background
    // shows through exactly as it does in the design.
    final drop = Path()
      ..fillType = PathFillType.evenOdd
      ..addArc(headRect, tangentAngle, -(math.pi + 2 * tangentAngle))
      ..lineTo(cx * sx, tipY * sy)
      ..close()
      ..addOval(
        Rect.fromCircle(
          center: Offset(cx * sx, cy * sy),
          radius: 10.5 * sx,
        ),
      );

    canvas.drawPath(drop, paint);
  }

  @override
  bool shouldRepaint(_LocationPinPainter oldDelegate) =>
      oldDelegate.color != color;
}
