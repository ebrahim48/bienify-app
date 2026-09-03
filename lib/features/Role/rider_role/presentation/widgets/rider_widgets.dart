import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../controllers/rider_shell_controller.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/rider.dart';

/// The pieces the courier's screens are assembled from.

/// Avatar, name over a location, and the bell — the same masthead the guide
/// and the dashboard both open with.
class RiderMasthead extends StatelessWidget {
  const RiderMasthead({
    super.key,
    required this.name,
    required this.location,
    required this.onNotifications,
    this.photoUrl,
  });

  final String name;
  final String location;

  /// The courier's own picture, when the server has one.
  final String? photoUrl;

  final VoidCallback onNotifications;

  static const double _avatar = 40;

  /// The Profile tab, rather than a route pushed over the shell.
  static void _openProfile() =>
      Get.find<RiderShellController>().selectIndex(_profileTab);

  /// Its index in `RiderShellScreen`: Home, Orders, Earnings, Profile.
  static const int _profileTab = 3;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Their own picture and their own name both open their profile, from
        // here as from anywhere else.
        GestureDetector(
          onTap: _openProfile,
          child: photoUrl != null
              ? AppAvatar(
                  imageUrl: photoUrl,
                  name: name,
                  size: _avatar,
                  fallbackAsset: null,
                  backgroundColor: AppColors.authInk,
                  foregroundColor: AppColors.white,
                )
              : Container(
                  width: _avatar.w,
                  height: _avatar.w,
                  decoration: const BoxDecoration(
                    color: AppColors.authInk,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_rounded,
                    size: AppSizes.xl2.w,
                    color: AppColors.white,
                  ),
                ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: GestureDetector(
            onTap: _openProfile,
            behavior: HitTestBehavior.opaque,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.rc(AppColors.authInk),
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: AppSizes.lg.w,
                    color: AppColors.gray600,
                  ),
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.gray600,
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
        InkResponse(
          onTap: onNotifications,
          radius: AppSizes.xl2.r,
          child: Icon(
            Icons.notifications_none_rounded,
            size: AppSizes.xl2.w,
            color: AppColors.authInk,
          ),
        ),
      ],
    );
  }
}

/// A blue disc with the courier's or customer's initials.
class InitialsDisc extends StatelessWidget {
  const InitialsDisc({
    super.key,
    required this.initials,
    this.size = 40,
    this.fill = AppColors.actionFill,
  });

  final String initials;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.titleSmall.rc(AppColors.white),
      ),
    );
  }
}

/// A finished delivery: who, when, and what it paid.
class DeliveryRecordRow extends StatelessWidget {
  const DeliveryRecordRow({
    super.key,
    required this.record,
    this.showOrderCode = false,
  });

  final DeliveryRecord record;

  /// The earnings history prints the order number under the fee; the
  /// dashboard does not.
  final bool showOrderCode;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Row(
        children: [
          InitialsDisc(initials: record.initials),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  record.whenLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                record.feeLabel,
                style: AppTextStyles.titleSmall.rc(AppColors.feeInk),
              ),
              if (showOrderCode)
                Text(
                  record.orderCode,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small capitalised caption above a block.
class RiderSectionLabel extends StatelessWidget {
  const RiderSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.rw(AppColors.gray500, FontWeight.w500),
      ),
    );
  }
}

/// The green "+$4.50" a request card carries.
class FeePill extends StatelessWidget {
  const FeePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.feeSurface,
        borderRadius: AppRadius.rMd,
      ),
      child: Text(label, style: AppTextStyles.labelLarge.rc(AppColors.feeInk)),
    );
  }
}

/// The delivery-zone chips under the zone dropdown.
class ZoneChips extends StatelessWidget {
  const ZoneChips({super.key, required this.zones, required this.onRemove});

  final List<String> zones;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs.w,
      runSpacing: AppSpacing.xs.h,
      children: [
        for (final zone in zones)
          Material(
            color: AppColors.zoneChip,
            borderRadius: AppRadius.rFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // Tapping a chip drops the zone, which is the only way to
              // undo picking one.
              onTap: () => onRemove(zone),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.xs2.h + 2,
                ),
                child: Text(
                  zone,
                  style: AppTextStyles.bodyMedium.rc(AppColors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A labelled switch row, as the GPS permission is drawn.
class RiderToggleRow extends StatelessWidget {
  const RiderToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.actionFill,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The wizard's progress bar — one continuous track rather than segments.
class RiderProgressBar extends StatelessWidget {
  const RiderProgressBar({
    super.key,
    required this.step,
    required this.stepCount,
  });

  final int step;
  final int stepCount;

  static const double _height = 5;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rFull,
      child: LinearProgressIndicator(
        value: (step + 1) / stepCount,
        minHeight: _height.h,
        backgroundColor: AppColors.uploadSurface,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.actionFill),
      ),
    );
  }
}

/// A form caption, grey and small, above a control.
class RiderFieldLabel extends StatelessWidget {
  const RiderFieldLabel(this.label, {super.key, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
      child: Text(
        isRequired ? '$label *' : label,
        style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
      ),
    );
  }
}

/// A starred photo requirement: its title and hint on the left, the upload
/// tile on the right.
class PhotoRequirementRow extends StatelessWidget {
  const PhotoRequirementRow({
    super.key,
    required this.title,
    required this.box,
  });

  final String title;
  final Widget box;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title *',
                style: AppTextStyles.titleSmall.rw(
                  AppColors.gray900,
                  FontWeight.w400,
                ),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Text(
                AppStrings.ensureClearPhoto.tr,
                style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
              ),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.sm),
        SizedBox(width: 146.w, child: box),
      ],
    );
  }
}
