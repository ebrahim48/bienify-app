import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/pharmacy.dart';
import '../controllers/order_tracking_controller.dart';

/// Live courier tracking on a real map, with the route sheet below it.
class LiveTrackingScreen extends GetView<OrderTrackingController> {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
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

/// The tracking map, with the courier's pin gliding between reports.
///
/// A courier reports every 15 metres, so a marker placed straight onto each
/// new position jumps. The pin is therefore tweened between the last two
/// **reported** positions — a visual smoothing of two measured points, never
/// an invented third one: the distance and arrival time beside it stay exactly
/// what the routing service measured, and are not derived from this.
class _Map extends StatefulWidget {
  const _Map({required this.controller});

  final OrderTrackingController controller;

  @override
  State<_Map> createState() => _MapState();
}

class _MapState extends State<_Map> with SingleTickerProviderStateMixin {
  OrderTrackingController get controller => widget.controller;

  late final AnimationController _glide = AnimationController(
    vsync: this,
    // A touch longer than a brisk ping, so the pin is still travelling when
    // the next position lands and the motion reads as continuous.
    duration: const Duration(milliseconds: 1200),
  );

  /// Where the pin is drawn: between [_from] and [_to] as the glide runs.
  LatLng? _from;
  LatLng? _to;

  /// The last reported position seen, so a rebuild that changes nothing about
  /// the courier does not restart the animation.
  MapPoint? _last;

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  /// Starts a glide to [next] when the courier has actually moved.
  void _moveTo(MapPoint? next) {
    if (next == null) return;
    if (_last != null && _last!.lat == next.lat && _last!.lng == next.lng) return;

    final target = LatLng(next.lat, next.lng);
    // The first position is placed, not travelled to: gliding in from nowhere
    // would send the pin across the city.
    _from = _last == null ? target : (_currentPin() ?? target);
    _to = target;
    _last = next;
    _glide.forward(from: 0);
  }

  LatLng? _currentPin() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return null;
    final t = Curves.easeOut.transform(_glide.value);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  /// Santo Domingo, used only to frame an empty map before the first position
  /// arrives — never as a pin. The four constants this file used to hold were
  /// drawn as real markers, so every order showed the same courier on the same
  /// road whatever the delivery was actually doing.
  static const LatLng _fallbackCentre = LatLng(18.4861, -69.9312);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final route = controller.route.value;
      final courier = route?.courier;
      final pickup = route?.pickup;
      final dropoff = route?.dropoff;

      final centre = courier ?? dropoff ?? pickup;

      // Scheduled rather than called inline: this runs during build, and
      // driving an animation from inside one is not allowed.
      WidgetsBinding.instance.addPostFrameCallback((_) => _moveTo(courier));

      final markers = <Marker>{
        if (courier != null)
          Marker(
            markerId: const MarkerId('courier'),
            // The gliding position while a tween is running, the reported one
            // otherwise.
            position: _currentPin() ?? LatLng(courier.lat, courier.lng),
            infoWindow: InfoWindow(title: AppStrings.courier.tr),
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
      };

      // The road the courier is actually driving, routed server-side. Falls
      // back to joining the two ends, and only when both are known — a line to
      // a pin that is not there would be a guess at a route.
      final points = route != null && route.hasRoad
          ? [for (final p in route.path) LatLng(p.lat, p.lng)]
          : (courier != null && dropoff != null
                ? [
                    LatLng(courier.lat, courier.lng),
                    LatLng(dropoff.lat, dropoff.lng),
                  ]
                : const <LatLng>[]);

      final line = points.isEmpty
          ? const <Polyline>{}
          : <Polyline>{
              Polyline(
                polylineId: const PolylineId('route'),
                points: points,
                color: AppColors.gray950,
                width: 4,
              ),
            };

      // Rebuilt on every animation frame so the marker actually travels;
      // `markers` and `line` are captured from the observable read above, so
      // the `Obx` still tracks them.
      return AnimatedBuilder(
        animation: _glide,
        builder: (context, _) => GoogleMap(
          initialCameraPosition: CameraPosition(
            target: centre == null
                ? _fallbackCentre
                : LatLng(centre.lat, centre.lng),
            zoom: 12.5,
          ),
          markers: {
            for (final marker in markers)
              marker.markerId.value == 'courier' && _currentPin() != null
                  ? marker.copyWith(positionParam: _currentPin())
                  : marker,
          },
          polylines: line,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
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
              Obx(() {
                final route = controller.route.value;
                final reached = controller.routeStepsReached;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.routeStatusLabel,
                      style: AppTextStyles.titleLarge.rc(AppColors.authInk),
                    ),
                    AppSpacing.gapV(AppSpacing.xs2),
                    // How long the courier is away, and how far.
                    //
                    // An arrival time used to sit here from a constant, and
                    // was deleted because nothing estimated one. There is a
                    // routing engine behind this screen now: the server asks
                    // Directions for the road from the courier's last reported
                    // position to where they are heading, and this is that
                    // answer. Still absent — not zeroed — whenever the route
                    // could not be established, which is why it is a separate
                    // line above the subtitle rather than replacing it.
                    if (route?.etaLabel != null ||
                        route?.distanceLabel != null) ...[
                      Text(
                        [?route?.etaLabel, ?route?.distanceLabel].join(' · '),
                        style: AppTextStyles.titleMedium.rc(
                          AppColors.actionFill,
                        ),
                      ),
                      AppSpacing.gapV(AppSpacing.xxs),
                    ],
                    // What is known regardless: when the courier last reported.
                    Text(
                      controller.routeSubtitle,
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
                                color: index < reached
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
                    Text(
                      AppStrings.stepsLeft.trParams({
                        'count': '${4 - reached}',
                      }),
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray900),
                    ),
                    AppSpacing.gapV(AppSpacing.base),
                    _RouteEnds(route: route),
                  ],
                );
              }),
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
  const _RouteEnds({required this.route});

  final DeliveryRoute? route;

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
                route?.pickup?.label ?? AppStrings.notRecorded.tr,
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
                route?.dropoff?.label ?? AppStrings.notRecorded.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.authInk),
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
    return Obx(() {
      final person = controller.courier.value;

      // Nobody has taken the order yet. Saying so beats naming a courier who
      // is not carrying it, which is what a fixture here did for every order.
      if (person == null) {
        return Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.noCourierYet.tr,
                style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          AppAvatar(
            name: person.name,
            imageUrl: person.photoUrl.isEmpty ? null : person.photoUrl,
            size: 48,
            fallbackAsset: AppAssets.rider,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  person.name,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Row(
                  children: [
                    if (person.hasRating) ...[
                      Icon(
                        Icons.star_rounded,
                        size: AppSizes.lg.w,
                        color: AppColors.star,
                      ),
                      AppSpacing.gapH(AppSpacing.xxs),
                      Text(
                        '${person.rating.toStringAsFixed(1)} '
                        '${AppStrings.reviewsCount.trParams({'count': '${person.reviewCount}'})}',
                        style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                      ),
                    ] else
                      // A new courier has no score. Printing 4.9 for them, as
                      // the fixture did, is a recommendation nobody made.
                      Text(
                        AppStrings.noRatingsYet.tr,
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
    });
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
