import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
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
      child: Scaffold(
        backgroundColor: AppColors.gray900,
        body: Column(
          children: [
            Expanded(child: _Stage(controller: controller)),
            _CallFooter(controller: controller),
          ],
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
        Obx(
          () => controller.isCameraOff.value
              ? const ColoredBox(color: AppColors.gray800)
              : Image.asset(AppAssets.doctorVideo, fit: BoxFit.cover),
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
          child: const _SelfView(),
        ),

        Positioned(
          left: AppSpacing.sm.w,
          top: AppSpacing.sm.h,
          child: SafeArea(child: const _ConnectionPill()),
        ),
      ],
    );
  }
}

/// The patient's own feed.
class _SelfView extends StatelessWidget {
  const _SelfView();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: SizedBox(
        width: VideoCallScreen._pipWidth.w,
        height: VideoCallScreen._pipHeight.h,
        child: Image.asset(AppAssets.clientVideo, fit: BoxFit.cover),
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xs2.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.openInk,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_rounded,
            size: AppSizes.lg.w,
            color: AppColors.white,
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          Text(
            AppStrings.goodConnection.tr,
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
              Obx(
                () => Text(
                  controller.durationLabel,
                  style: AppTextStyles.headlineSmall.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
              ),
              Text(
                AppStrings.callDuration.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
              ),
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
