import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/home_controller.dart';
import '../../../doctors/presentation/widgets/doctor_list_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/lab_request_card.dart';
import '../widgets/section_header.dart';
import '../../../appointments/presentation/widgets/appointment_card.dart';

/// The Home feed.
///
/// One scroll view: greeting, search entry point, open lab requests, upcoming
/// appointments, then nearby doctors. Sections that have no data simply do
/// not render, so an empty account degrades cleanly instead of showing empty
/// headings.
///
/// Lives inside `MainShellScreen`, which owns the bottom navigation — this
/// widget only supplies the body.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.refreshFeed,
            color: AppColors.primary800,
            backgroundColor: AppColors.surface,
            child: Obx(() => _body(context)),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.xl),
            HomeHeader(
              name: controller.patientName,
              location: controller.location,
              onProfileTap: controller.openProfile,
              onLocationTap: controller.changeLocation,
              onCartTap: controller.openCart,
              onMessagesTap: controller.openMessages,
              onNotificationsTap: controller.openNotifications,
            ),
            AppSpacing.gapV(AppSpacing.xl2),
            if (controller.isLoading)
              const HomeSkeleton()
            else if (controller.hasFailed)
              _Failure(controller: controller)
            else
              ..._sections(),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections() {
    return [
      HomeSearchBar(onTap: controller.openSearch),
      AppSpacing.gapV(AppSpacing.base),

      for (final request in controller.labRequests) ...[
        LabRequestCard(
          request: request,
          onReview: () => controller.reviewLabRequest(request),
        ),
        AppSpacing.gapV(AppSpacing.base),
      ],

      if (controller.upcomingAppointments.isNotEmpty) ...[
        SectionHeader(title: AppStrings.upcomingAppointments.tr),
        AppSpacing.gapV(AppSpacing.sm),
        for (final appointment in controller.upcomingAppointments) ...[
          AppointmentCard(
            appointment: appointment,
            onJoin: () => controller.joinAppointment(appointment),
          ),
          AppSpacing.gapV(AppSpacing.sm),
        ],
        AppSpacing.gapV(AppSpacing.xs),
      ],

      if (controller.nearbyDoctors.isNotEmpty) ...[
        SectionHeader(
          title: AppStrings.nearbyDoctors.tr,
          onSeeAll: controller.seeAllDoctors,
        ),
        AppSpacing.gapV(AppSpacing.sm),
        for (final doctor in controller.nearbyDoctors) ...[
          DoctorListCard(
            doctor: doctor,
            onTap: () => controller.openDoctor(doctor),
          ),
          AppSpacing.gapV(AppSpacing.sm),
        ],
      ],
    ];
  }
}

/// Retryable error state, shown in place of the feed body.
class _Failure extends StatelessWidget {
  const _Failure({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl4.h),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48.w,
            color: AppColors.gray300,
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            controller.errorMessage.value ??
                AppStrings.somethingWentWrong.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.md),
          AppButton(
            label: AppStrings.retry.tr,
            expanded: false,
            onPressed: controller.load,
          ),
        ],
      ),
    );
  }
}
