import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../controllers/order_tracking_controller.dart';

/// Live courier tracking on a real map, with the route sheet below it.
class LiveTrackingScreen extends GetView<OrderTrackingController> {
  const LiveTrackingScreen({super.key});

  static const LatLng _courier = LatLng(
    PharmacyMockData.courierLatitude,
    PharmacyMockData.courierLongitude,
  );
  static const LatLng _destination = LatLng(
    PharmacyMockData.destinationLatitude,
    PharmacyMockData.destinationLongitude,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _Map()),
          SafeArea(
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoundAction(
                    icon: Icons.close_rounded,
                    onTap: controller.finishDelivery,
                  ),
                  _HelpChip(),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _RouteSheet(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _Map extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LiveTrackingScreen._courier,
        zoom: 12.5,
      ),
      markers: {
        const Marker(
          markerId: MarkerId('courier'),
          position: LiveTrackingScreen._courier,
        ),
        const Marker(
          markerId: MarkerId('destination'),
          position: LiveTrackingScreen._destination,
        ),
      },
      polylines: {
        const Polyline(
          polylineId: PolylineId('route'),
          points: [
            LiveTrackingScreen._courier,
            LiveTrackingScreen._destination,
          ],
          color: AppColors.gray950,
          width: 4,
        ),
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.xl5.w,
          height: AppSizes.xl5.w,
          child: Icon(icon, size: AppSizes.xl2.w, color: AppColors.gray900),
        ),
      ),
    );
  }
}

class _HelpChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline_rounded,
            size: AppSizes.xl.w,
            color: AppColors.gray900,
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          Text(
            AppStrings.help.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.gray900),
          ),
        ],
      ),
    );
  }
}

/// Route, progress and courier, over the map.
class _RouteSheet extends StatelessWidget {
  const _RouteSheet({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl3.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: AppSpacing.base.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PharmacyMockData.routeTitle,
                style: AppTextStyles.titleLarge.rc(AppColors.authInk),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Text(
                PharmacyMockData.arrivingAt,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
              ),
              AppSpacing.gapV(AppSpacing.sm),
              Row(
                children: [
                  for (var index = 0; index < 4; index++) ...[
                    Expanded(
                      child: Container(
                        height: AppSizes.xs.h,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppColors.actionFill
                              : AppColors.gray100,
                          borderRadius: AppRadius.rFull,
                        ),
                      ),
                    ),
                    if (index != 3) AppSpacing.gapH(AppSpacing.xs2),
                  ],
                ],
              ),
              AppSpacing.gapV(AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.stepsLeft.trParams({'count': '3'}),
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray900),
                  ),
                  Text(
                    PharmacyMockData.latestArrival,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                  ),
                ],
              ),
              AppSpacing.gapV(AppSpacing.base),
              const _RouteEnds(),
              AppSpacing.gapV(AppSpacing.base),
              _Rider(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteEnds extends StatelessWidget {
  const _RouteEnds();

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
                AppStrings.pickUpFrom.tr,
                style: AppTextStyles.labelSmall
                    .rc(AppColors.gray400)
                    .copyWith(letterSpacing: 1),
              ),
              Text(
                PharmacyMockData.pickupFrom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.authInk),
              ),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Icon(
          Icons.swap_horiz_rounded,
          size: AppSizes.xl2.w,
          color: AppColors.authInk,
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.deliverTo.tr,
                style: AppTextStyles.labelSmall
                    .rc(AppColors.gray400)
                    .copyWith(letterSpacing: 1),
              ),
              Text(
                PharmacyMockData.deliverTo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.authInk),
              ),
              Text(
                PharmacyMockData.deliverToAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.rc(AppColors.gray400),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rider extends StatelessWidget {
  const _Rider({required this.controller});

  final OrderTrackingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppAvatar(name: PharmacyMockData.riderName, size: 48),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                PharmacyMockData.riderName,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.star,
                  ),
                  AppSpacing.gapH(AppSpacing.xxs),
                  Text(
                    '${PharmacyMockData.riderRating}'
                    '(${PharmacyMockData.riderReviews} reviews)',
                    style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                  ),
                ],
              ),
            ],
          ),
        ),
        _ChatAction(onTap: controller.openRiderChat),
      ],
    );
  }
}

class _ChatAction extends StatelessWidget {
  const _ChatAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.actionFill,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: AppSizes.xl5.w,
              height: AppSizes.xl5.w,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.white,
              ),
            ),
          ),
        ),
        Positioned(
          top: -2.h,
          right: -2.w,
          child: Container(
            width: AppSizes.lg.w,
            height: AppSizes.lg.w,
            decoration: BoxDecoration(
              color: AppColors.badge,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Text(
                '1',
                style: AppTextStyles.labelSmall.rw(
                  AppColors.white,
                  FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
