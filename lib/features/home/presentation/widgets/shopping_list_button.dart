import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controllers/home_controller.dart';

class ShoppingListButton extends StatelessWidget {
  const ShoppingListButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return GestureDetector(
      onTap: () => ctrl.switchTab(2),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          const Icon(Icons.shopping_cart_outlined, color: AppColors.white, size: 22),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shopping list',
                  style: AppTextStyles.sub2.copyWith(color: AppColors.white)),
              Obx(() => Text(
                '${ctrl.totalMeals} meals. tap to view',
                style: AppTextStyles.body4.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              )),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: AppColors.white, size: 20),
        ]),
      ),
    );
  }
}
