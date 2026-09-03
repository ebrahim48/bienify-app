import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/profile.dart';
import '../controllers/account_controller.dart';

/// My Wallet: the balance card, two statistics, and the transaction history.
class WalletScreen extends GetView<AccountController> {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: AppStrings.myWallet.tr,
        trailing: _AddAccountPill(onTap: controller.openPaymentOptions),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => _BalanceCard(
              amount: controller.balanceLabel,
              isHidden: controller.isBalanceHidden.value,
              onToggle: controller.toggleBalanceVisibility,
              onAddMoney: controller.openTopUp,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          // Both totals are summed from the ledger, which arrives after the
          // first build — so they repaint rather than staying at the zeroes
          // they were drawn with.
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _StatCard(
                    label: AppStrings.totalSpent.tr,
                    value: controller.totalSpentLabel,
                    footnote: AppStrings.orderCount.trParams({
                      'count': '${controller.spentOrderCount}',
                    }),
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Obx(
                  () => _StatCard(
                    label: AppStrings.addedThisMonth.tr,
                    value: controller.addedThisMonthLabel,
                    footnote: AppStrings.activeSaver.tr,
                    footnoteInk: AppColors.saverAccent,
                    footnoteIcon: Icons.arrow_upward_rounded,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.transactionHistory.tr,
            style: AppTextStyles.labelLarge
                .rc(AppColors.gray400)
                .copyWith(letterSpacing: 0.6),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(() {
            final transactions = controller.transactions.toList();
            if (transactions.isEmpty) {
              return AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: AppStrings.noTransactionsYet.tr,
              );
            }
            // One card holding every row with hairlines between, which is how
            // the design groups them — not a card per transaction.
            return AppCard(
              hasShadow: false,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var index = 0; index < transactions.length; index++) ...[
                    if (index > 0) const _RowDivider(),
                    _TransactionRow(
                      transaction: transactions[index],
                      dateLabel: controller.transactionDateLabel(
                        transactions[index].occurredOn,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _AddAccountPill extends StatelessWidget {
  const _AddAccountPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs.h,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: AppSizes.xl.w,
                color: AppColors.actionLabel,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                AppStrings.addAccount.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Near-black card with two olive discs bleeding off opposite corners.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.amount,
    required this.isHidden,
    required this.onToggle,
    required this.onAddMoney,
  });

  final String amount;
  final bool isHidden;
  final VoidCallback onToggle;

  /// Adding money belongs next to the number it changes. The masthead pill
  /// stays "Add Account", which files a *card* — a different thing, and one
  /// this app has confused before.
  final VoidCallback onAddMoney;

  static const double _height = 178;
  static const double _bigDisc = 180;
  static const double _smallDisc = 130;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rXl2,
      child: Container(
        // A floor, not a fixed height. `.h` scales the card by screen height
        // while the type inside scales by width, so on a short, wide screen
        // the card shrank and the text did not — the doctor's tablet-shaped
        // emulator overflowed by seven pixels and struck the Add Money button
        // through with the yellow-and-black overflow bars. The card is allowed
        // to grow instead.
        constraints: BoxConstraints(minHeight: _height.h),
        color: AppColors.walletSurface,
        child: Stack(
          children: [
            // Clipped by the parent, so each disc only shows the arc that
            // falls inside the card.
            Positioned(
              right: -_bigDisc.w * 0.18,
              top: -_bigDisc.w * 0.30,
              child: _Disc(size: _bigDisc),
            ),
            Positioned(
              left: -_smallDisc.w * 0.25,
              bottom: -_smallDisc.w * 0.35,
              child: _Disc(size: _smallDisc),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.md.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.availableBalanceCaps.tr,
                    style: AppTextStyles.labelLarge
                        .rc(AppColors.gray400)
                        .copyWith(letterSpacing: 1.2),
                  ),
                  AppSpacing.gapV(AppSpacing.xs2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            maxLines: 1,
                            style: AppTextStyles.displaySmall.rc(
                              AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapH(AppSpacing.sm),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggle,
                        child: Icon(
                          isHidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: AppSizes.xl2.w,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  // Was a `Spacer`, which needs a bounded height and so
                  // cannot survive a card that sizes to its content.
                  AppSpacing.gapV(AppSpacing.md),
                  _AddMoneyButton(onTap: onAddMoney),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The way money gets into the wallet, on the card that shows how much is in
/// it. Until this existed the only inflows were the seed script, a refund and
/// a cash payment an admin confirmed.
class _AddMoneyButton extends StatelessWidget {
  const _AddMoneyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.rFull,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.walletSurface,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  AppStrings.addMoney.tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.walletSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size.w,
    height: size.w,
    decoration: const BoxDecoration(
      color: AppColors.walletAccent,
      shape: BoxShape.circle,
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.footnote,
    this.footnoteInk = AppColors.gray400,
    this.footnoteIcon,
  });

  final String label;
  final String value;
  final String footnote;
  final Color footnoteInk;
  final IconData? footnoteIcon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Row(
            children: [
              if (footnoteIcon != null) ...[
                Icon(footnoteIcon, size: AppSizes.lg.w, color: footnoteInk),
                AppSpacing.gapH(AppSpacing.xxs),
              ],
              Expanded(
                child: Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(footnoteInk),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      Container(height: AppSizes.borderWidth, color: AppColors.surfaceBorder);
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.dateLabel});

  final WalletTransaction transaction;
  final String dateLabel;

  static const double _badge = 36;

  bool get _isCredit => transaction.kind == TransactionKind.credit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: BoxDecoration(
              color: _isCredit
                  ? AppColors.creditSurface
                  : AppColors.debitSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              _isCredit ? Icons.add_rounded : Icons.remove_rounded,
              size: AppSizes.lg.w,
              color: _isCredit ? AppColors.creditInk : AppColors.debitInk,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  dateLabel,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(
            transaction.amountLabel,
            style: AppTextStyles.titleSmall.rc(
              _isCredit ? AppColors.creditInk : AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}
