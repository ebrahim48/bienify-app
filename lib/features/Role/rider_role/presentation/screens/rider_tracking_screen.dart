import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../patient/pharmacy/data/static/pharmacy_mock_data.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_orders_controller.dart';

/// The live job on a map, with the route sheet under it.
///
/// The customer's note is the only thing that changes between the two
/// designs — it hangs over the sheet when View Note is tapped.
class RiderTrackingScreen extends GetView<RiderOrdersController> {
  const RiderTrackingScreen({super.key});

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
      body: Obx(() {
        final delivery = controller.active.value;
        if (delivery == null) return const SizedBox.shrink();

        return Stack(
          children: [
            const Positioned.fill(child: _Map()),
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
            Positioned(
              left: AppSpacing.base.w,
              top: AppSizes.xl5.h,
              child: _AwayChip(minutes: delivery.minutesAway),
            ),
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
  const _Map();

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: RiderTrackingScreen._courier,
        zoom: 12.5,
      ),
      // Not `const` sets: `Marker` and `Polyline` override `==`, which a
      // constant set may not contain.
      markers: {
        const Marker(
          markerId: MarkerId('courier'),
          position: RiderTrackingScreen._courier,
        ),
        const Marker(
          markerId: MarkerId('destination'),
          position: RiderTrackingScreen._destination,
        ),
      },
      polylines: {
        const Polyline(
          polylineId: PolylineId('route'),
          points: [
            RiderTrackingScreen._courier,
            RiderTrackingScreen._destination,
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

/// The white flag on the route saying how far off the courier is.
class _AwayChip extends StatelessWidget {
  const _AwayChip({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rMd,
      ),
      child: Text(
        AppStrings.minutesAway.trParams({'count': '$minutes'}),
        style: AppTextStyles.titleSmall.rc(AppColors.gray900),
      ),
    );
  }
}

/// Everything under the map: the road, the progress, both ends of the trip,
/// the note and the way to finish.
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
            Text(
              delivery.roadName,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.rc(AppColors.authInk),
            ),
            Text(
              AppStrings.nowArriving.trParams({
                'time': delivery.arrivingAtLabel,
              }),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _StepBar(stepsLeft: delivery.stepsLeft),
            AppSpacing.gapV(AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.stepsLeft.trParams({
                      'count': '${delivery.stepsLeft}',
                    }),
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                  ),
                ),
                Text(
                  AppStrings.latestArrival.trParams({
                    'time': delivery.latestArrivalLabel,
                  }),
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                ),
              ],
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _Endpoints(request: delivery.request),
            AppSpacing.gapV(AppSpacing.sm),
            _NoteRow(note: delivery.note),
            AppSpacing.gapV(AppSpacing.sm),
            _CustomerRow(unread: delivery.unreadMessages),
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

/// The doorway photos, and the button that reveals what the customer asked
/// for. The note hangs over the sheet rather than pushing it down, which is
/// how the design draws it.
class _NoteRow extends GetView<RiderOrdersController> {
  const _NoteRow({required this.note});

  final String note;

  static const double _thumb = 44;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            for (var index = 0; index < 2; index++) ...[
              if (index > 0) AppSpacing.gapH(AppSpacing.xs2),
              ClipRRect(
                borderRadius: AppRadius.rMd,
                child: Image.asset(
                  AppAssets.reportDocument,
                  width: _thumb.w,
                  height: _thumb.w,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const Spacer(),
            _ViewNoteButton(onTap: controller.toggleNote),
          ],
        ),
        Obx(
          () => controller.isNoteVisible.value
              ? Positioned(
                  right: 0,
                  top: _thumb.h,
                  child: _NoteBubble(note: note),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ViewNoteButton extends StatelessWidget {
  const _ViewNoteButton({required this.onTap});

  final VoidCallback onTap;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          child: Center(
            widthFactor: 1,
            child: Text(
              AppStrings.viewNote.tr,
              style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray400,
      borderRadius: AppRadius.rMd,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.xs.h,
        ),
        child: Text(
          note,
          style: AppTextStyles.bodyMedium.rc(AppColors.gray900),
        ),
      ),
    );
  }
}

/// The customer's avatar, and the chat with its unread count.
class _CustomerRow extends GetView<RiderOrdersController> {
  const _CustomerRow({required this.unread});

  final int unread;

  static const double _button = 44;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppAvatar(size: 36),
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
