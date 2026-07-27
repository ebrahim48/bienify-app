import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/utils/app_colors.dart';
import 'core/utils/app_text_styles.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/app_pages.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'bienify',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.splash,
          getPages: AppPages.routes,
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.white,
            fontFamily: 'Instrument Sans',
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.brand,
              surface: AppColors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.primary),
              titleTextStyle: AppTextStyles.h5,
            ),
            textTheme: TextTheme(
              displayLarge:   AppTextStyles.h1,
              displayMedium:  AppTextStyles.h2,
              displaySmall:   AppTextStyles.h3,
              headlineMedium: AppTextStyles.h4,
              headlineSmall:  AppTextStyles.h5,
              titleLarge:     AppTextStyles.sub1,
              titleMedium:    AppTextStyles.sub2,
              titleSmall:     AppTextStyles.sub3,
              bodyLarge:      AppTextStyles.body1,
              bodyMedium:     AppTextStyles.body2,
              bodySmall:      AppTextStyles.body3,
            ),
          ),
        );
      },
    );
  }
}
