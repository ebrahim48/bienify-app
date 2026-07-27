import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/splash_controller.dart';

/// Brand lock-up centred on the warm off-white background while
/// [SplashController] decides where to send the user.
class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  /// Logo width measured from the design (231 of 390).
  static const double _logoWidth = 231;

  @override
  Widget build(BuildContext context) {
    // Touching `controller` here starts the destination check as soon as the
    // first frame is scheduled.
    controller;

    return AppScaffold(
      backgroundColor: AppColors.authBackground,
      padded: false,
      scrollable: false,
      child: Center(
        child: Image.asset(
          AppAssets.logo,
          width: _logoWidth.w,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
