import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import 'app_avatar.dart';

/// An avatar with a connection dot on its corner.
///
/// Shared by the patient's message list and the doctor's, because they are
/// showing the same fact about the same socket and should not be able to
/// disagree about how it looks.
class PresenceAvatar extends StatelessWidget {
  const PresenceAvatar({
    super.key,
    required this.isOnline,
    required this.size,
    this.imageUrl,
    this.name,
    this.fallbackAsset,
  });

  /// Null while presence is unknown, which draws no dot at all — a question
  /// nobody has answered yet should not look like a confident "offline".
  final bool? isOnline;

  final double size;
  final String? imageUrl;
  final String? name;
  final String? fallbackAsset;

  /// Identifies the dot for tests.
  static const Key dotKey = ValueKey('presence-dot');

  /// Proportional to the avatar so the dot stays legible on a small row and
  /// does not balloon on a large one.
  double get _dot => size * 0.28;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppAvatar(
          imageUrl: imageUrl,
          name: name,
          size: size,
          fallbackAsset: fallbackAsset,
        ),
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              // Keyed so a test can find the dot itself rather than one of
              // the several containers the avatar is built from.
              key: dotKey,
              width: _dot.w,
              height: _dot.w,
              decoration: BoxDecoration(
                color: isOnline! ? AppColors.success400 : AppColors.gray400,
                shape: BoxShape.circle,
                // A ring in the card's colour, so the dot reads as sitting on
                // the photo rather than being cut out of it.
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
