import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../models/country.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'app_text_field.dart';

/// Searchable dial-code picker presented from [AppPhoneField].
///
/// ```dart
/// final country = await CountryPickerSheet.show(context, selected: current);
/// ```
class CountryPickerSheet extends StatefulWidget {
  const CountryPickerSheet({super.key, required this.selected});

  final Country selected;

  /// Opens the sheet and resolves to the chosen country, or `null` if the
  /// user dismissed it.
  static Future<Country?> show(
    BuildContext context, {
    required Country selected,
  }) {
    return showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl3.r)),
      ),
      builder: (_) => CountryPickerSheet(selected: selected),
    );
  }

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _results = Countries.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) =>
      setState(() => _results = Countries.search(query));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.keyboardInset),
      child: FractionallySizedBox(
        heightFactor: 0.75,
        child: Column(
          children: [
            AppSpacing.gapV(AppSpacing.sm),
            Container(
              width: AppSizes.xl4.w,
              height: AppSizes.xs.h,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: AppRadius.rFull,
              ),
            ),
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.selectCountry.tr,
              style: AppTextStyles.titleMedium.rc(AppColors.authInk),
            ),
            AppSpacing.gapV(AppSpacing.base),
            Padding(
              padding: AppSpacing.pagePadding,
              child: AppTextField(
                controller: _searchController,
                hint: AppStrings.searchCountry.tr,
                onChanged: _search,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: AppSizes.xl2.w,
                  color: AppColors.fieldHint,
                ),
              ),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final country = _results[index];
                  return _CountryTile(
                    country: country,
                    isSelected: country == widget.selected,
                    onTap: () => Navigator.of(context).pop(country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.isSelected,
    required this.onTap,
  });

  final Country country;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding.w,
          vertical: AppSpacing.sm.h,
        ),
        child: Row(
          children: [
            Text(country.flagEmoji, style: TextStyle(fontSize: AppSizes.xl.sp)),
            AppSpacing.gapH(AppSpacing.sm),
            Expanded(
              child: Text(
                country.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
              ),
            ),
            Text(
              country.dialCode,
              style: AppTextStyles.bodyMedium.rc(AppColors.fieldHint),
            ),
            if (isSelected) ...[
              AppSpacing.gapH(AppSpacing.xs),
              Icon(
                Icons.check_rounded,
                size: AppSizes.xl.w,
                color: AppColors.primary800,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
