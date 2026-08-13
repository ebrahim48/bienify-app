import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_avatar.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// The portrait panel at the top of Doctor Details: a soft blue wash behind
/// the doctor, with the message action floating top-right.
///
/// The design uses a full-bleed cut-out portrait. No such asset ships with
/// the project, so the available headshot is shown large and circular — a
/// deliberate composition rather than an upscaled thumbnail. Swap
/// [portraitAsset] for a cut-out when one lands.
class DoctorHero extends StatelessWidget {
  const DoctorHero({
    super.key,
    required this.onMessage,
    this.imageUrl,
    this.name,
    this.portraitAsset,
  });

  final VoidCallback onMessage;
  final String? imageUrl;

  /// Whose initials stand in when there is no photograph.
  final String? name;

  /// A bundled portrait, when one is genuinely wanted. Null by default: a
  /// doctor who has uploaded nothing shows their initials rather than the
  /// stock face every other photoless doctor would also wear.
  final String? portraitAsset;

  static const double height = 260;
  static const double _actionSize = 48;
  static const double _portraitSize = 176;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.rXl,
                // Radial wash from the design: a violet core fading to the
                // cool tint at the edges.
                gradient: const RadialGradient(
                  center: Alignment(0, 0.15),
                  radius: 0.95,
                  colors: [
                    AppColors.primary300,
                    AppColors.primary100,
                    AppColors.primary50,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: Container(
                  width: _portraitSize.w,
                  height: _portraitSize.w,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: _portrait(),
                ),
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.base.h,
            right: AppSpacing.base.w,
            child: _MessageAction(onTap: onMessage),
          ),
        ],
      ),
    );
  }

  /// The doctor's own photo when the server has one, the bundled portrait
  /// otherwise. This took [imageUrl] but never read it, so every practitioner
  /// on Doctor Details wore the same stock face.
  Widget _portrait() {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _withoutPhoto();

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => Shimmer.fromColors(
        baseColor: AppColors.primary200,
        highlightColor: AppColors.primary100,
        child: ColoredBox(color: AppColors.primary200),
      ),
      errorWidget: (context, _, _) => _withoutPhoto(),
    );
  }

  /// The bundled portrait if one was asked for, otherwise this doctor's own
  /// initials at portrait size.
  Widget _withoutPhoto() {
    final asset = portraitAsset;
    if (asset != null) return Image.asset(asset, fit: BoxFit.cover);
    return AppAvatar(name: name, size: _portraitSize);
  }
}

class _MessageAction extends StatelessWidget {
  const _MessageAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary200,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: DoctorHero._actionSize.w,
          height: DoctorHero._actionSize.w,
          child: Center(
            child: AppSvgIcon(
              AppIcons.message,
              size: AppSizes.xl2,
              color: AppColors.gray900,
            ),
          ),
        ),
      ),
    );
  }
}
