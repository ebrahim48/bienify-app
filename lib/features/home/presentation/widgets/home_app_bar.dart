import 'package:flutter/material.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/widgets/sizzl_logo.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final dateStr = '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 0.5)),
      ),
      child: Row(children: [
        const SizzlLogo(fontSize: 22, letterSpacing: -0.5),
        const Spacer(),
        Text(dateStr,
          style: AppTextStyles.body3.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('S',
              style: AppTextStyles.sub3.copyWith(color: AppColors.primary)),
          ),
        ),
      ]),
    );
  }
}
