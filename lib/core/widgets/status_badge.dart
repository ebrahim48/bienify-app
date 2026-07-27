import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// The scalloped "seal" badge with a check mark shown on the two success
/// screens — green after sign-up, primary blue after a password reset.
///
/// Drawn rather than shipped as an image so the same widget covers both
/// colours (and any future state) at any resolution.
///
/// ```dart
/// const StatusBadge(color: AppColors.success);
/// const StatusBadge(color: AppColors.actionFill);
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.color,
    this.size = AppSizes.statusBadgeSize,
    this.checkColor = AppColors.white,
    this.lobes = 12,
  });

  final Color color;
  final double size;
  final Color checkColor;

  /// Number of rounded bumps around the edge.
  final int lobes;

  @override
  Widget build(BuildContext context) {
    final side = size.w;
    return SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
        painter: _StatusBadgePainter(
          color: color,
          checkColor: checkColor,
          lobes: lobes,
        ),
      ),
    );
  }
}

class _StatusBadgePainter extends CustomPainter {
  const _StatusBadgePainter({
    required this.color,
    required this.checkColor,
    required this.lobes,
  });

  final Color color;
  final Color checkColor;
  final int lobes;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Bumps sit outside the base circle, so shrink it to keep the badge
    // inside its box.
    final step = 2 * math.pi / lobes;
    final base = size.width / 2 / (1 + math.sin(step / 2) * 0.62);
    final chordHalf = base * math.sin(step / 2);
    final bumpRadius = chordHalf * 1.02;

    final path = Path();
    for (var i = 0; i < lobes; i++) {
      final angle = step * i - math.pi / 2;
      final point = Offset(
        center.dx + base * math.cos(angle),
        center.dy + base * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.arcToPoint(
          point,
          radius: Radius.circular(bumpRadius),
          clockwise: true,
        );
      }
    }
    // Close the ring with a final bump back to the starting point.
    final first = Offset(
      center.dx + base * math.cos(-math.pi / 2),
      center.dy + base * math.sin(-math.pi / 2),
    );
    path
      ..arcToPoint(first, radius: Radius.circular(bumpRadius), clockwise: true)
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    // Check mark — proportional to the badge so it scales cleanly.
    final unit = size.width / 176;
    final check = Path()
      ..moveTo(center.dx - 34 * unit, center.dy + 2 * unit)
      ..lineTo(center.dx - 10 * unit, center.dy + 25 * unit)
      ..lineTo(center.dx + 36 * unit, center.dy - 24 * unit);

    canvas.drawPath(
      check,
      Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11 * unit
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StatusBadgePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.checkColor != checkColor ||
      oldDelegate.lobes != lobes;
}
