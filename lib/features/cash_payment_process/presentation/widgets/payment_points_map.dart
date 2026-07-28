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
import '../../data/static/cash_payment_data.dart';
import '../../domain/entities/cash_payment.dart';

/// Google map of nearby payment points, framed as in the design.
///
/// The API key lives in `AndroidManifest.xml` / `AppDelegate`, not here.
/// Selecting a marker feeds the featured card below the map.
class PaymentPointsMap extends StatelessWidget {
  const PaymentPointsMap({
    super.key,
    required this.points,
    required this.selectedId,
    required this.onSelected,
  });

  final List<PaymentPoint> points;
  final String? selectedId;
  final ValueChanged<PaymentPoint> onSelected;

  static const double height = 260;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(
      CashPaymentData.originLatitude,
      CashPaymentData.originLongitude,
    ),
    zoom: 14,
  );

  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('origin'),
      position: _initialCamera.target,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(title: AppStrings.yourLocation.tr),
    ),
    for (final point in points)
      Marker(
        markerId: MarkerId(point.id),
        position: LatLng(point.latitude, point.longitude),
        infoWindow: InfoWindow(title: point.name, snippet: point.hoursLabel),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          point.id == selectedId
              ? BitmapDescriptor.hueViolet
              : BitmapDescriptor.hueRed,
        ),
        onTap: () => onSelected(point),
      ),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.rXl,
          border: Border.all(
            color: AppColors.primary300,
            width: AppSizes.borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.rXl,
          child: Stack(
            children: [
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: _initialCamera,
                  markers: _markers,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  // The card itself scrolls with the page, so the map only
                  // needs to respond to deliberate drags on it.
                  gestureRecognizers: const {},
                ),
              ),
              Positioned(
                left: AppSpacing.sm.w,
                bottom: AppSpacing.sm.h,
                child: const _LocationChip(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip();

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
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: 0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.base.w,
            height: AppSizes.base.w,
            decoration: const BoxDecoration(
              color: AppColors.actionFill,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(
            AppStrings.yourLocation.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
