import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';

/// Photo, name, one grey line under it and a date on the right.
///
/// The same 358×70 card appears three times in Results to Review — the
/// patient list, the patient screen and Order Additional Test — with only the
/// second line changing, so it is one widget.
class PatientRowCard extends StatelessWidget {
  const PatientRowCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.dateLabel,
    this.photoAsset,
    this.photoUrl,
    this.onTap,
  });

  final String name;

  /// `CXR-2` in the list, the complaint on the patient screen.
  final String subtitle;

  final String dateLabel;
  final String? photoAsset;

  /// The patient's picture off the server, preferred over [photoAsset].
  final String? photoUrl;

  final VoidCallback? onTap;

  /// A rounded square, not the circular `AppAvatar` the rest of the app uses —
  /// these designs crop the photo square.
  static const double photoSide = 46;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      borderColor: AppColors.chipSurface,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.sm.h,
      ),
      child: Row(
        children: [
          PatientPhoto(asset: photoAsset, url: photoUrl),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(dateLabel, style: AppTextStyles.bodyLarge.rc(AppColors.gray500)),
        ],
      ),
    );
  }
}

/// The rounded-square patient photo, shared by the row card and the order
/// detail's own patient panel.
///
/// Server picture → bundled [asset] → generic glyph, the same chain
/// [AppAvatar] walks. Every seeded account carries a `profile.avatarUrl`, so
/// on real data this reaches the first rung.
class PatientPhoto extends StatelessWidget {
  const PatientPhoto({super.key, this.asset, this.url});

  final String? asset;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final side = PatientRowCard.photoSide.w;

    return Container(
      width: side,
      height: side,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.chipSurface,
        borderRadius: AppRadius.rXl,
      ),
      child: _image(side),
    );
  }

  Widget _image(double side) {
    final photo = url;
    if (photo != null && photo.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        width: side,
        height: side,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: AppColors.gray100,
          highlightColor: AppColors.gray50,
          child: ColoredBox(color: AppColors.gray100),
        ),
        errorWidget: (context, _, _) => _fallback(side),
      );
    }
    return _fallback(side);
  }

  Widget _fallback(double side) {
    final bundled = asset;
    if (bundled == null) return _glyph(side);

    return Image.asset(
      bundled,
      fit: BoxFit.cover,
      width: side,
      height: side,
      errorBuilder: (context, _, _) => _glyph(side),
    );
  }

  Widget _glyph(double side) => Icon(
    Icons.person_rounded,
    size: side * 0.55,
    color: AppColors.gray500,
  );
}
