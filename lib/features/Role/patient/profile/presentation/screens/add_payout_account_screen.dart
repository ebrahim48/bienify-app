import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/account_controller.dart';

/// "Add Account" for a bank or mobile-money destination.
///
/// The counterpart of the card form on the other side of the Wallet's Payment
/// Options step. Before this existed that step led to the card form whichever
/// method was chosen, so choosing Bank Transfer collected a card number, an
/// expiry and a CVV and filed the result to `/wallet/cards` — which is how
/// money is taken *in*. A courier who added their bank here was then told by
/// the payout sheet to add a payout account, because none had ever been
/// created.
///
/// The kind is decided by the method picked on the step before and arrives as
/// the route argument, so it is not asked for twice.
class AddPayoutAccountScreen extends StatefulWidget {
  const AddPayoutAccountScreen({super.key});

  @override
  State<AddPayoutAccountScreen> createState() => _AddPayoutAccountScreenState();
}

class _AddPayoutAccountScreenState extends State<AddPayoutAccountScreen> {
  final AccountController _controller = Get.find<AccountController>();

  /// Held on the state rather than the controller, so leaving the screen
  /// forgets a half-typed account.
  String _name = '';
  String _number = '';
  String _bank = '';

  /// `bank` or `mobile_money` — the server's own spelling, and the whole enum
  /// `/wallet/payout-accounts` accepts. Falls back to a bank account when the
  /// screen is reached without one, which is the commoner of the two.
  String get _kind {
    final argument = Get.arguments;
    return argument is String && argument.isNotEmpty ? argument : 'bank';
  }

  bool get _isBank => _kind == 'bank';

  Future<void> _save() async {
    final saved = await _controller.savePayoutAccount(
      kind: _kind,
      displayName: _name,
      accountNumber: _number,
      // Only a bank account has one.
      bankName: _isBank ? _bank : null,
    );
    if (saved && mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: _isBank
            ? AppStrings.payoutKindBank.tr
            : AppStrings.payoutKindMobileMoney.tr,
      ),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Expanded(
            child: SingleChildScrollView(
              child: AppCard(
                hasShadow: false,
                padding: EdgeInsets.all(AppSpacing.base.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Says what this account is for, so it is not read as
                    // another way to pay. The two lists are separate on the
                    // server and were indistinguishable in the app.
                    Text(
                      AppStrings.payoutAccountPurpose.tr,
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                    ),
                    AppSpacing.gapV(AppSpacing.sm),
                    AppTextField(
                      hint: AppStrings.payoutAccountName.tr,
                      onChanged: (value) => _name = value,
                    ),
                    AppSpacing.gapV(AppSpacing.sm),
                    AppTextField(
                      hint: AppStrings.payoutAccountNumber.tr,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _number = value,
                    ),
                    // A mobile-money number has no bank behind it, so it is
                    // not asked for one.
                    if (_isBank) ...[
                      AppSpacing.gapV(AppSpacing.sm),
                      AppTextField(
                        hint: AppStrings.payoutBankName.tr,
                        onChanged: (value) => _bank = value,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Obx(
            () => AppButton(
              label: AppStrings.save.tr,
              isEnabled: !_controller.isSavingPayoutAccount.value,
              onPressed: _save,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}
