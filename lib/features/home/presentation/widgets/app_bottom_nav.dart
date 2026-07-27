import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controllers/home_controller.dart';

/// Floating translucent pill nav — the content scrolls underneath it, which is
/// what the frosted fill is there to show.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return SizedBox(
      height: 100,
      child: Center(
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxWidth: 362),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(48),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(5),
                color: AppColors.white.withValues(alpha: 0.10),
                child: Obx(() {
                  final current = ctrl.currentTab.value;
                  // The active item keeps its 70px pill; the rest share what's
                  // left of the 352px row, with a 10px gap between each.
                  return Row(
                    spacing: 10,
                    children: [
                      for (final item in _items)
                        if (item.index == current)
                          _NavItem(spec: item, isActive: true, onTap: ctrl.switchTab)
                        else
                          Expanded(
                            child: _NavItem(spec: item, isActive: false, onTap: ctrl.switchTab),
                          ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const List<_NavSpec> _items = [
  _NavSpec(index: 0, label: 'Home',     icon: Icons.home_rounded),
  _NavSpec(index: 1, label: 'Meal',     icon: Icons.restaurant_menu_rounded, svgPath: 'assets/icons/meal.svg'),
  _NavSpec(index: 2, label: 'Shopping', icon: Icons.shopping_cart_outlined),
  _NavSpec(index: 3, label: 'Pantry',   icon: Icons.kitchen_outlined),
  _NavSpec(index: 4, label: 'Account',  icon: Icons.person_outline_rounded),
];

class _NavSpec {
  const _NavSpec({
    required this.index,
    required this.label,
    required this.icon,
    this.svgPath,
  });
  final int index;
  final String label;
  final IconData icon;
  final String? svgPath;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });
  final _NavSpec spec;
  final bool isActive;
  final void Function(int) onTap;

  Widget _buildIcon(Color color) {
    if (spec.svgPath != null) {
      return SvgPicture.asset(
        spec.svgPath!,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(spec.icon, color: color, size: 22);
  }

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.white : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => onTap(spec.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 70 : null,
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(color),
            const SizedBox(height: 2),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: AppTextStyles.body4.copyWith(
                color: color,
                height: 1.1,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
