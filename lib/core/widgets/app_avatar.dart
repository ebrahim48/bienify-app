import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// Circular profile image with a graceful fallback chain.
///
/// Network photo → [fallbackAsset] → initials → generic glyph. The mock
/// backend ships no photo URLs, so in practice doctors render the bundled
/// headshot and the chain only reaches initials if that is cleared too.
///
/// ```dart
/// AppAvatar(imageUrl: doctor.photoUrl, name: doctor.name, size: 44)
/// AppAvatar(name: patient.name, fallbackAsset: null)   // monogram instead
/// ```
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 44,
    this.backgroundColor = AppColors.primary100,
    this.foregroundColor = AppColors.primary800,
    this.fallbackAsset = AppAssets.doctorPlaceholder,
    this.child,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  /// Bundled image used when [imageUrl] is missing or fails. Pass `null` to
  /// fall straight through to initials.
  final String? fallbackAsset;

  /// Overrides both the photo and the initials (used for icon avatars).
  final Widget? child;

  /// Up to two uppercase letters, skipping the `Dr.` honorific.
  String get _initials {
    final source = (name ?? '').replaceAll(RegExp(r'^Dr\.?\s*'), '').trim();
    if (source.isEmpty) return '';
    final words = source.split(RegExp(r'[\s.,]+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final side = size.w;

    return Container(
      width: side,
      height: side,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: child ?? _photoOrInitials(side),
    );
  }

  Widget _photoOrInitials(double side) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _fallback(side);

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: side,
      height: side,
      placeholder: (context, _) => Shimmer.fromColors(
        baseColor: AppColors.gray100,
        highlightColor: AppColors.gray50,
        child: ColoredBox(color: AppColors.gray100, child: SizedBox.expand()),
      ),
      errorWidget: (context, _, _) => _fallback(side),
    );
  }

  Widget _fallback(double side) {
    final asset = fallbackAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        width: side,
        height: side,
        errorBuilder: (context, _, _) => _monogram(side),
      );
    }
    return _monogram(side);
  }

  Widget _monogram(double side) {
    final initials = _initials;
    if (initials.isEmpty) {
      return Icon(
        Icons.person_rounded,
        size: side * 0.55,
        color: foregroundColor,
      );
    }
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.labelLarge
            .rc(foregroundColor)
            .copyWith(fontSize: (size * 0.34).sp),
      ),
    );
  }
}
