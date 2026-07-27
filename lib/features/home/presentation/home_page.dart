import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import 'controllers/home_controller.dart';
import 'tabs/home_tab.dart';
import 'tabs/pantry_tab.dart';
import 'tabs/account_tab.dart';
import 'widgets/app_bottom_nav.dart';
import '../../meal/presentation/screens/cookbook_screen.dart';
import '../../meal/presentation/controllers/meal_controller.dart';
import '../../shopping/presentation/screens/shopping_screen.dart';
import '../../shopping/presentation/controllers/shopping_controller.dart';
import '../../pantry/presentation/controllers/pantry_controller.dart';
import '../../account/presentation/controllers/account_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    Get.put(MealController());
    Get.put(ShoppingController());
    Get.put(PantryController());
    Get.put(AccountController());
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true, // content runs under the translucent nav pill
      body: Obx(() {
        final ctrl = Get.find<HomeController>();
        switch (ctrl.currentTab.value) {
          case 0: return const HomeTab();
          case 1: return const CookbookScreen();
          case 2: return const ShoppingScreen();
          case 3: return const PantryTab();
          case 4: return const AccountTab();
          default: return const HomeTab();
        }
      }),
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
