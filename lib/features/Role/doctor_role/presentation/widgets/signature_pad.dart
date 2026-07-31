import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';

/// A surface the doctor signs with a finger.
///
/// **The pad owns its ink.** Strokes are widget state, not controller state:
/// they are a drawing, and a `GetxController` that held them would rebuild the
/// canvas on every sampled point. The controller is told only whether the pad
/// has anything on it, which is all it needs to enable Save.
///
/// Clearing works by [SignaturePadState.clear] through a [GlobalKey], because
/// the Clear affordance is drawn outside the pad in the design.
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.hint,
    required this.onChanged,
    this.height = 64,
  });

  /// Shown until the first stroke lands — `dr.deep` in the design.
  final String hint;

  /// Fired when the pad goes from empty to signed or back.
  final ValueChanged<bool> onChanged;

  final double height;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  /// One list per stroke, so lifting the finger breaks the line instead of
  /// joining the end of one stroke to the start of the next.
  final List<List<Offset>> _strokes = [];

  bool get isEmpty => _strokes.isEmpty;

  void clear() {
    if (_strokes.isEmpty) return;
    setState(_strokes.clear);
    widget.onChanged(false);
  }

  void _start(Offset point) {
    final wasEmpty = _strokes.isEmpty;
    setState(() => _strokes.add([point]));
    if (wasEmpty) widget.onChanged(true);
  }

  void _extend(Offset point) => setState(() => _strokes.last.add(point));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height.h,
      width: double.infinity,
      child: GestureDetector(
        // Opaque so a stroke can start anywhere on the pad, including over
        // the hint text.
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _start(details.localPosition),
        onPanUpdate: (details) => _extend(details.localPosition),
        child: CustomPaint(
          painter: _InkPainter(_strokes),
          child: _strokes.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.hint,
                    style: AppTextStyles.titleMedium.rw(
                      AppColors.fieldHint,
                      FontWeight.w400,
                    ),
                  ),
                )
              : const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.authInk
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        // A tap is a dot, not nothing.
        canvas.drawPoints(PointMode.points, stroke, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  // The list is mutated in place, so identity says nothing about the ink —
  // repaint whenever the pad rebuilds, which only happens while drawing.
  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}
