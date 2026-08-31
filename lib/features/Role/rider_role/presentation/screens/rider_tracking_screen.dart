import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_orders_controller.dart';

/// The live job on a map, with the route sheet under it.
///
/// The customer's note is the only thing that changes between the two
/// designs — it hangs over the sheet when View Note is tapped.
class RiderTrackingScreen extends GetView<RiderOrdersController> {
  const RiderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Obx(() {
        final delivery = controller.active.value;
        if (delivery == null) return const SizedBox.shrink();

        return Stack(
          children: [
            Positioned.fill(child: _Map(controller: controller)),
            SafeArea(
              child: Padding(
                padding: AppSpacing.pagePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RoundAction(
                      icon: Icons.close_rounded,
                      onTap: () => Get.back<void>(),
                    ),
                    const _HelpChip(),
                  ],
                ),
              ),
            ),
            // A "15 min away" chip used to sit here, from a constant. Nothing
            // measures a distance or estimates an arrival on this screen, so
            // there is no number to put in it.
            Align(
              alignment: Alignment.bottomCenter,
              child: _RouteSheet(delivery: delivery),
            ),
          ],
        );
      }),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({required this.controller});

  final RiderOrdersController controller;

  /// Used only to frame an empty map before a route lands — never as a pin.
  /// The two constants this file held were drawn as real markers, so every job
  /// showed the same road between the same two points.
  static const LatLng _fallbackCentre = LatLng(18.4861, -69.9312);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final route = controller.route.value;
      final courier = route?.courier;
      final pickup = route?.pickup;
      final dropoff = route?.dropoff;
      final centre = courier ?? dropoff ?? pickup;

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: centre == null
              ? _fallbackCentre
              : LatLng(centre.lat, centre.lng),
          zoom: 12.5,
        ),
        // Not `const` sets: `Marker` and `Polyline` override `==`, which a
        // constant set may not contain.
        markers: {
          if (courier != null)
            Marker(
              markerId: const MarkerId('courier'),
              position: LatLng(courier.lat, courier.lng),
            ),
          if (pickup != null)
            Marker(
              markerId: const MarkerId('pickup'),
              position: LatLng(pickup.lat, pickup.lng),
              infoWindow: InfoWindow(title: pickup.label),
            ),
          if (dropoff != null)
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(dropoff.lat, dropoff.lng),
              infoWindow: InfoWindow(title: dropoff.label),
            ),
        },
        // The road the server routed, when it could. Falls back to joining the
        // two ends — which is a guess at a road, so it is only drawn when
        // there is nothing better and both ends are actually known.
        polylines: {
          if (route != null && route.hasRoad)
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                for (final point in route.path) LatLng(point.lat, point.lng),
              ],
              color: AppColors.gray950,
              width: 4,
            )
          else if (courier != null && dropoff != null)
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                LatLng(courier.lat, courier.lng),
                LatLng(dropoff.lat, dropoff.lng),
              ],
              color: AppColors.gray950,
              width: 4,
            ),
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
      );
    });
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
  const _HelpChip();

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

class _RouteSheet extends GetView<RiderOrdersController> {
  const _RouteSheet({required this.delivery});

  final ActiveDelivery delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base.w,
        AppSpacing.base.h,
        AppSpacing.base.w,
        AppSpacing.base.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: AppRadius.rXl2.topLeft),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Where the parcel is going, which is the one heading a courier
            // needs. It used to read a road name that no lookup produced.
            Text(
              delivery.destination,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.rc(AppColors.authInk),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _StepBar(stepsLeft: delivery.stepsLeft),
            AppSpacing.gapV(AppSpacing.xs),
            // The arrival and latest-arrival times that flanked this were both
            // constants. The step count is derived from the delivery's own
            // status, so it cannot disagree with what the server holds.
            Text(
              AppStrings.stepsLeft.trParams({
                'count': '${delivery.stepsLeft}',
              }),
              style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
            ),
            // Measured along the road by the routing service, not estimated
            // here. A "15 min away" chip used to sit on this screen from a
            // constant; this one is absent whenever nothing routed the
            // journey, rather than falling back to a number.
            Obx(() {
              final route = controller.route.value;
              final eta = route?.etaLabel;
              final distance = route?.distanceLabel;
              if (eta == null && distance == null) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs.h),
                child: Text(
                  [?eta, ?distance].join(' · '),
                  style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                ),
              );
            }),
            AppSpacing.gapV(AppSpacing.sm),
            _Endpoints(request: delivery.request),
            AppSpacing.gapV(AppSpacing.sm),
            _CustomerRow(
              name: delivery.request.customerName,
              photoUrl: delivery.request.customerPhotoUrl,
              unread: delivery.unreadMessages,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _ArrivedButton(
              label: controller.advanceLabel,
              onTap: controller.arrived,
            ),
          ],
        ),
      ),
    );
  }
}

/// Four segments, filled for the legs already ridden.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.stepsLeft});

  final int stepsLeft;

  static const int _total = 4;
  static const double _height = 5;

  @override
  Widget build(BuildContext context) {
    final done = _total - stepsLeft;

    return Row(
      children: [
        for (var index = 0; index < _total; index++) ...[
          if (index > 0) AppSpacing.gapH(AppSpacing.xs2),
          Expanded(
            child: Container(
              height: _height.h,
              decoration: BoxDecoration(
                color: index < done
                    ? AppColors.actionFill
                    : AppColors.uploadSurface,
                borderRadius: AppRadius.rFull,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Where it comes from and where it goes, with the swap glyph between.
class _Endpoints extends StatelessWidget {
  const _Endpoints({required this.request});

  final DeliveryRequest request;

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
                style: AppTextStyles.labelMedium.rw(
                  AppColors.gray500,
                  FontWeight.w500,
                ),
              ),
              Text(
                request.pickupName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Icon(
          Icons.swap_horiz_rounded,
          size: AppSizes.xl2.w,
          color: AppColors.gray900,
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.deliverTo.tr,
                style: AppTextStyles.labelMedium.rw(
                  AppColors.gray500,
                  FontWeight.w500,
                ),
              ),
              Text(
                request.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
              Text(
                request.customerAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomerRow extends GetView<RiderOrdersController> {
  const _CustomerRow({
    required this.name,
    required this.photoUrl,
    required this.unread,
  });

  /// Whose parcel this is. Without it the disc drew a bundled headshot of a
  /// doctor in place of the customer.
  final String name;

  /// Their own picture. Null falls through to initials — no stock face stands
  /// in for the person the courier is about to meet.
  final String? photoUrl;

  final int unread;

  static const double _button = 44;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(name: name, imageUrl: photoUrl, size: 36),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: Text(
            AppStrings.customer.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: AppColors.actionFill,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: controller.openChat,
                child: SizedBox(
                  width: _button.w,
                  height: _button.w,
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: AppSizes.xl.w,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xs2.w),
                  decoration: const BoxDecoration(
                    color: AppColors.badge,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unread',
                    style: AppTextStyles.labelSmall.rc(AppColors.white),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Outlined rather than filled — the trip is not done until it is tapped.
///
/// Carries the step it is about to take: a parcel is collected and put on the
/// road before it arrives, and the server will not skip either.
class _ArrivedButton extends StatelessWidget {
  const _ArrivedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.authPanelSoft,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: AppSizes.controlHeight.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: AppColors.primary200,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Center(
            child: Text(
              label.tr,
              style: AppTextStyles.buttonLarge.rc(AppColors.actionFill),
            ),
          ),
        ),
      ),
    );
  }
}
