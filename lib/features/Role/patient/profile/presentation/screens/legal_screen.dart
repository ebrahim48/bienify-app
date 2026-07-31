import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../data/static/legal_copy.dart';
import '../../domain/entities/profile.dart';

/// About Us, Terms & Conditions and Privacy Policy.
///
/// One screen for all three: the designs are identical apart from the title
/// and the body, so the document arrives as the route argument rather than as
/// three near-copies.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, this.document});

  /// Falls back to About Us when opened without an argument, so a deep link
  /// with a missing extra still renders something sensible.
  final LegalDocument? document;

  LegalDocument get _document =>
      document ??
      (Get.arguments is LegalDocument
          ? Get.arguments as LegalDocument
          : LegalDocument.aboutUs);

  String get _title => switch (_document) {
    LegalDocument.aboutUs => AppStrings.aboutUs.tr,
    LegalDocument.terms => AppStrings.termsAndConditions.tr,
    LegalDocument.privacy => AppStrings.privacyPolicy.tr,
  };

  /// Not a `.tr` lookup: these are whole documents, not interface labels.
  /// See `LegalCopy`.
  String get _body => switch (_document) {
    LegalDocument.aboutUs => LegalCopy.aboutUs,
    LegalDocument.terms => LegalCopy.terms,
    LegalDocument.privacy => LegalCopy.privacy,
  };

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: _title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          Text(_body, style: AppTextStyles.bodyLarge.rc(AppColors.gray600)),
          AppSpacing.gapV(AppSpacing.xl2),
        ],
      ),
    );
  }
}
