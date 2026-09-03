import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/services/video_call_service.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../controllers/video_call_controller.dart';

/// The consultation call: the doctor's feed full-bleed, the patient's feed
/// picture-in-picture, and the call controls on a white footer.
class VideoCallScreen extends GetView<VideoCallController> {
  const VideoCallScreen({super.key});

  static const double _pipWidth = 120;
  static const double _pipHeight = 168;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the video.
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        // Back is a hang-up, not a way out of the screen. Both ringing screens
        // already knew this; the call screen did not, so backing out of a live
        // consultation left the service still thinking a call was in progress.
        // Every later call was then auto-declined as "busy" for the rest of the
        // session, and the server held the consultation for four hours — while
        // the other party found out only when Agora eventually noticed.
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.endCall();
        },
        child: Scaffold(
          backgroundColor: AppColors.gray900,
          body: Column(
            children: [
              Expanded(child: _Stage(controller: controller)),
              _CallFooter(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.controller});

  final VideoCallController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // The observable is read here, inside the builder: an Obx whose
        // closure only constructs a child subscribes to nothing, because the
        // child's own build runs outside it.
        Obx(
          () => _RemoteFeed(
            call: controller.call.value,
            engine: controller.service.engine,
          ),
        ),

        // Keeps the name legible over a bright frame.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.gray900.withValues(alpha: 0.65),
                  AppColors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.base.w,
                AppSpacing.xl2.h,
                AppSpacing.base.w,
                AppSpacing.base.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.appointment.doctorName,
                    style: AppTextStyles.titleLarge.rw(
                      AppColors.white,
                      FontWeight.w400,
                    ),
                  ),
                  AppSpacing.gapV(AppSpacing.xs2),
                  Text(
                    controller.appointment.specialty,
                    style: AppTextStyles.bodyLarge.rc(AppColors.gray100),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: AppSpacing.base.w,
          bottom: AppSpacing.xl4.h,
          child: Obx(
            () => _SelfView(
              isCameraOff: controller.isCameraOff.value,
              // Read so the preview appears the moment the channel is joined:
              // the engine is not observable, and the camera toggle alone
              // would leave this grey until it was pressed.
              engine: controller.call.value.stage == CallStage.idle
                  ? null
                  : controller.service.engine,
            ),
          ),
        ),

        Positioned(
          left: AppSpacing.sm.w,
          top: AppSpacing.sm.h,
          child: SafeArea(
            child: Obx(
              () => _ConnectionPill(
                isLive: controller.call.value.stage == CallStage.live,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The other party, full-bleed.
///
/// Until they arrive there is no frame to show, so the stage says what it is
/// waiting for rather than holding a black rectangle.
class _RemoteFeed extends StatelessWidget {
  const _RemoteFeed({required this.call, required this.engine});

  final CallState call;
  final RtcEngine? engine;

  @override
  Widget build(BuildContext context) {
    if (call.hasRemote && engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine!,
          canvas: VideoCanvas(uid: call.remoteUid),
          connection: RtcConnection(channelId: call.channelId),
        ),
      );
    }

    return ColoredBox(
      color: AppColors.gray800,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.base.w),
          child: Text(
            _waitingLabel(call),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray100),
          ),
        ),
      ),
    );
  }

  String _waitingLabel(CallState call) => switch (call.stage) {
    CallStage.requestingPermissions => AppStrings.callAskingPermission.tr,
    CallStage.connecting => AppStrings.callConnecting.tr,
    CallStage.failed => call.message,
    // In the channel, nobody on the other end yet: that is a phone ringing.
    _ => AppStrings.callRinging.tr,
  };
}

/// This side's own feed.
class _SelfView extends StatelessWidget {
  const _SelfView({required this.isCameraOff, required this.engine});

  final bool isCameraOff;
  final RtcEngine? engine;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: SizedBox(
        width: VideoCallScreen._pipWidth.w,
        height: VideoCallScreen._pipHeight.h,
        child: isCameraOff || engine == null
            ? const ColoredBox(color: AppColors.gray900)
            : AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: engine!,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xs2.h,
      ),
      decoration: BoxDecoration(
        // Green only once both parties are actually through; a "Good
        // connection" badge over a channel nobody has joined is a lie.
        color: isLive ? AppColors.openInk : AppColors.gray600,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.wifi_rounded : Icons.wifi_tethering_rounded,
            size: AppSizes.lg.w,
            color: AppColors.white,
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          Text(
            isLive
                ? AppStrings.goodConnection.tr
                : AppStrings.callConnecting.tr,
            style: AppTextStyles.labelMedium.rc(AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _CallFooter extends StatelessWidget {
  const _CallFooter({required this.controller});

  final VideoCallController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.base.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Until the other side picks up there is no duration to show —
              // a stopped 00:00 reads as a broken clock — so the footer rings
              // instead, and the count replaces it once they are both on.
              Obx(() {
                final isLive =
                    controller.call.value.stage == CallStage.live;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLive
                          ? controller.durationLabel
                          : AppStrings.callRinging.tr,
                      style: AppTextStyles.headlineSmall.rw(
                        AppColors.gray900,
                        FontWeight.w400,
                      ),
                    ),
                    Text(
                      isLive ? AppStrings.callDuration.tr : '',
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                    ),
                  ],
                );
              }),
              AppSpacing.gapV(AppSpacing.base),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Obx(
                    () => _CallAction(
                      icon: controller.isMuted.value
                          ? Icons.mic_off_rounded
                          : Icons.mic_none_rounded,
                      onTap: controller.toggleMute,
                    ),
                  ),
                  Obx(
                    () => _CallAction(
                      icon: controller.isCameraOff.value
                          ? Icons.videocam_off_outlined
                          : Icons.videocam_outlined,
                      onTap: controller.toggleCamera,
                    ),
                  ),
                  _CallAction(
                    icon: Icons.call_end_rounded,
                    background: AppColors.error600,
                    ink: AppColors.white,
                    onTap: controller.endCall,
                  ),
                  _CallAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: controller.openChat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.icon,
    required this.onTap,
    this.background = AppColors.chatFieldFill,
    this.ink = AppColors.gray900,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color background;
  final Color ink;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: _size.w,
            height: _size.w,
            child: Icon(icon, size: AppSizes.xl2.w, color: ink),
          ),
        ),
      ),
    );
  }
}
