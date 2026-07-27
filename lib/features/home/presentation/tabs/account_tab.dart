import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../account/presentation/controllers/account_controller.dart';
import '../../../account/presentation/widgets/change_password_sheet.dart';
import '../widgets/home_app_bar.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  static const _allDietary = [
    'Vegetarian', 'Vegan', 'Halal', 'Kosher',
    'Dairy-free', 'Nut-free', 'Pescatarian',
    'High protein', 'Gluten-free',
  ];

  static const _allCuisines = [
    'Italian', 'Mexican', 'Asian', 'American',
    'Mediterranean', 'Indian', 'Middle Eastern', 'British',
  ];

  void _showChangePassword(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  void _showLogoutDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => _ConfirmDialog(
        title: 'Log out',
        message: 'Are you sure you want to log out?',
        actionLabel: 'Log out',
        actionColor: AppColors.error,
        onAction: () {
          Get.back();
          Get.offAllNamed(AppRoutes.onboarding);
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => _ConfirmDialog(
        title: 'Delete account',
        message: 'This will permanently delete your account and all data. This action cannot be undone.',
        actionLabel: 'Delete',
        actionColor: AppColors.error,
        onAction: () {
          Get.back();
          // TODO: call delete account API
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AccountController>();
    return SafeArea(
      child: Column(children: [
        const HomeAppBar(),
        Expanded(
          child: Obx(() => ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              const SizedBox(height: 20),

              // ── Profile header ──────────────────────────────────────
              Row(children: [
                Stack(children: [
                  Container(
                    width: 60, height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        ctrl.name.value.isNotEmpty
                            ? ctrl.name.value[0].toUpperCase() : 'K',
                        style: AppTextStyles.h4.copyWith(
                            color: AppColors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 10, color: AppColors.white),
                    ),
                  ),
                ]),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ctrl.name.value, style: AppTextStyles.h5),
                      const SizedBox(height: 2),
                      Text(ctrl.householdSummary,
                          style: AppTextStyles.body3.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.editProfile),
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded,
                        size: 16, color: AppColors.white),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── YOUR PLAN ───────────────────────────────────────────
              _SectionLabel('YOUR PLAN'),
              const SizedBox(height: 8),
              _Card(children: [
                _NameRow(name: ctrl.name.value),
                _divider(),
                _StepperRow(
                  label: 'Adults',
                  subtitle: 'Full portions',
                  value: ctrl.adults.value,
                  onDec: () => ctrl.decrement(ctrl.adults),
                  onInc: () => ctrl.increment(ctrl.adults),
                ),
                _divider(),
                _StepperRow(
                  label: 'Children',
                  subtitle: 'Counted as lighter portions',
                  value: ctrl.children.value,
                  onDec: () => ctrl.decrement(ctrl.children),
                  onInc: () => ctrl.increment(ctrl.children),
                ),
                _divider(),
                _BudgetRow(
                  value: ctrl.weeklyBudget.value,
                  onDec: () => ctrl.decrement(ctrl.weeklyBudget),
                  onInc: () => ctrl.increment(ctrl.weeklyBudget),
                ),
                const SizedBox(height: 4),
                Text(
                  'Changes apply to your budget and servings right away.',
                  style: AppTextStyles.body4.copyWith(
                      color: AppColors.textSecondary),
                ),
              ]),
              const SizedBox(height: 20),

              // ── MEALS PER WEEK ──────────────────────────────────────
              _SectionLabel('MEALS PER WEEK'),
              const SizedBox(height: 8),
              _Card(children: [
                _StepperRow(
                  label: 'Breakfast',
                  value: ctrl.breakfast.value,
                  onDec: () => ctrl.decrement(ctrl.breakfast),
                  onInc: () => ctrl.increment(ctrl.breakfast),
                ),
                _divider(),
                _StepperRow(
                  label: 'Lunch',
                  value: ctrl.lunch.value,
                  onDec: () => ctrl.decrement(ctrl.lunch),
                  onInc: () => ctrl.increment(ctrl.lunch),
                ),
                _divider(),
                _StepperRow(
                  label: 'Dinner',
                  value: ctrl.dinner.value,
                  onDec: () => ctrl.decrement(ctrl.dinner),
                  onInc: () => ctrl.increment(ctrl.dinner),
                ),
              ]),
              const SizedBox(height: 20),

              // ── DIETARY PREFERENCES ─────────────────────────────────
              _SectionLabel('DIETARY PREFERENCES'),
              const SizedBox(height: 8),
              _Card(children: [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _allDietary.map((d) {
                    final sel = ctrl.dietary.contains(d);
                    return _ChipButton(
                      label: d,
                      selected: sel,
                      onTap: () => ctrl.toggleDietary(d),
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 20),

              // ── CUISINES YOU LIKE ───────────────────────────────────
              _SectionLabel('CUISINES YOU LIKE'),
              const SizedBox(height: 8),
              _Card(children: [
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _allCuisines.map((c) {
                    final sel = ctrl.cuisines.contains(c);
                    return _ChipButton(
                      label: c,
                      selected: sel,
                      onTap: () => ctrl.toggleCuisine(c),
                    );
                  }).toList(),
                ),
              ]),
              const SizedBox(height: 20),

              // ── NOTIFICATIONS ───────────────────────────────────────
              _SectionLabel('NOTIFICATIONS'),
              const SizedBox(height: 8),
              _Card(children: [
                _ToggleRow(
                  label: 'Expiry reminders',
                  subtitle: 'Nudge before pantry items go off',
                  value: ctrl.notifyExpiry.value,
                  onChanged: (v) => ctrl.notifyExpiry.value = v,
                ),
                _divider(),
                _ToggleRow(
                  label: 'Weekly plan ready',
                  subtitle: 'When your new week\'s meals are planned',
                  value: ctrl.notifyWeeklyPlan.value,
                  onChanged: (v) => ctrl.notifyWeeklyPlan.value = v,
                ),
                _divider(),
                _ToggleRow(
                  label: 'Shopping reminders',
                  subtitle: 'A nudge to shop before the week starts',
                  value: ctrl.notifyShopping.value,
                  onChanged: (v) => ctrl.notifyShopping.value = v,
                ),
                _divider(),
                _ToggleRow(
                  label: 'Tips & offers',
                  subtitle: 'Occasional product news (we keep it rare)',
                  value: ctrl.notifyTips.value,
                  onChanged: (v) => ctrl.notifyTips.value = v,
                ),
              ]),
              const SizedBox(height: 20),

              // ── ACCOUNT ─────────────────────────────────────────────
              _SectionLabel('ACCOUNT'),
              const SizedBox(height: 8),
              _Card(children: [
                _AccountRow(
                  label: 'Email',
                  trailing: Text(ctrl.email.value,
                      style: AppTextStyles.body3.copyWith(
                          color: AppColors.textSecondary)),
                ),
                _divider(),
                _AccountRow(
                  label: 'Change password',
                  showChevron: true,
                  onTap: () => _showChangePassword(context),
                ),
                _divider(),
                _AccountRow(
                  label: 'Manage subscription',
                  subtitle: 'Free trial: 7 days left',
                  showChevron: true,
                  onTap: () => Get.toNamed(AppRoutes.paywall),
                ),
                _divider(),
                _AccountRow(
                  label: 'Privacy Policy',
                  showChevron: true,
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
                _divider(),
                _AccountRow(
                  label: 'Contact us',
                  showChevron: true,
                  onTap: () => Get.toNamed(AppRoutes.contactUs),
                ),
                _divider(),
                _AccountRow(
                  label: 'About us',
                  showChevron: true,
                  onTap: () => Get.toNamed(AppRoutes.aboutUs),
                ),
                _divider(),
                _AccountRow(
                  label: 'Delete account',
                  labelColor: AppColors.error,
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Log out ─────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => _showLogoutDialog(context),
                  child: Container(
                    width: 361,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        top: BorderSide(
                          color: Color(0x1A1C1C1E),
                          width: 1,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('Log out',
                        style: AppTextStyles.sub2.copyWith(
                            color: AppColors.error)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          )),
        ),
      ]),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.border);
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.sub4.copyWith(
          color: AppColors.textSecondary, letterSpacing: 1.2));
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Text('Your name', style: AppTextStyles.sub2),
      const Spacer(),
      Text(name,
          style: AppTextStyles.sub2.copyWith(
              fontWeight: FontWeight.w700)),
    ]),
  );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.sub2),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!,
              style: AppTextStyles.body4.copyWith(
                  color: AppColors.textSecondary)),
        ],
      ]),
      const Spacer(),
      _StepBtn(icon: Icons.remove, onTap: onDec),
      SizedBox(
        width: 32,
        child: Center(
          child: Text('$value',
              style: AppTextStyles.sub1.copyWith(
                  fontWeight: FontWeight.w700)),
        ),
      ),
      _StepBtn(icon: Icons.add, onTap: onInc),
    ]),
  );
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.value,
    required this.onDec,
    required this.onInc,
  });
  final int value;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weekly budget', style: AppTextStyles.sub2),
        const SizedBox(height: 2),
        Text('Plans are built to land under this',
            style: AppTextStyles.body4.copyWith(
                color: AppColors.textSecondary)),
      ]),
      const Spacer(),
      _StepBtn(icon: Icons.remove, onTap: onDec),
      SizedBox(
        width: 44,
        child: Center(
          child: Text('\$ $value',
              style: AppTextStyles.sub1.copyWith(
                  fontWeight: FontWeight.w700)),
        ),
      ),
      _StepBtn(icon: Icons.add, onTap: onInc),
    ]),
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 16, color: AppColors.primary),
    ),
  );
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Text(label,
          style: AppTextStyles.body3.copyWith(
            color: selected ? AppColors.white : AppColors.primary,
          )),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(label, style: AppTextStyles.sub2),
          const SizedBox(height: 2),
          Text(subtitle,
              style: AppTextStyles.body4.copyWith(
                  color: AppColors.textSecondary)),
        ]),
      ),
      const SizedBox(width: 12),
      Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.brand,
        inactiveThumbColor: AppColors.white,
        inactiveTrackColor: AppColors.surfaceSubtle,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    ]),
  );
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
  });
  final String title;
  final String message;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    backgroundColor: AppColors.white,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.h5),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.body3.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text('Cancel',
                      style: AppTextStyles.sub2.copyWith(
                          color: AppColors.primary)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onAction,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: actionColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(actionLabel,
                      style: AppTextStyles.sub2.copyWith(
                          color: AppColors.white)),
                ),
              ),
            ),
          ]),
        ],
      ),
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.labelColor,
  });
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.sub2.copyWith(color: labelColor)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: AppTextStyles.body4.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (showChevron)
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textSecondary),
      ]),
    ),
  );
}
