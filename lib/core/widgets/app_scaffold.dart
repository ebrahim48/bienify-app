import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// Page shell for every auth / onboarding screen.
///
/// Handles the four things every screen would otherwise repeat:
/// * the `gray50` background and dark status-bar icons,
/// * `SafeArea` on both ends,
/// * the 16pt horizontal gutter,
/// * tap-outside-to-dismiss for the keyboard.
///
/// The body scrolls only when it has to, so short screens keep the designed
/// top alignment while tall content (or an open keyboard) never overflows.
///
/// ```dart
/// AppScaffold(
///   topBar: AppTopBar(title: AppStrings.login.tr),
///   child: Column(children: [...]),
/// )
/// ```
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.topBar,
    this.bottomBar,
    this.backgroundColor = AppColors.authBackground,
    this.padded = true,
    this.scrollable = true,
    this.resizeToAvoidBottomInset = true,
    this.maxContentWidth = 520,
  });

  final Widget child;

  /// Usually an [AppTopBar]; kept outside the scroll view so it stays put.
  final Widget? topBar;

  /// Pinned to the bottom above the safe area (used by the success screens).
  final Widget? bottomBar;

  final Color backgroundColor;

  /// Applies the shared 16pt horizontal gutter to [child].
  final bool padded;

  final bool scrollable;
  final bool resizeToAvoidBottomInset;

  /// On tablets the content column stops growing and centres instead of
  /// stretching a 358pt design across 1000pt of glass.
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle.copyWith(
        systemNavigationBarColor: backgroundColor,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (topBar != null)
                      Padding(
                        padding: AppSpacing.pagePadding,
                        child: topBar,
                      ),
                    Expanded(child: _body()),
                    if (bottomBar != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding.w,
                          AppSpacing.base.h,
                          AppSpacing.screenPadding.w,
                          AppSpacing.base.h,
                        ),
                        child: bottomBar,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final content = Padding(
      padding: padded ? AppSpacing.pagePadding : EdgeInsets.zero,
      child: child,
    );

    if (!scrollable) return content;

    // The child gets at least the viewport height so a trailing `Spacer`
    // still pushes content down, then scrolls once it grows past it.
    //
    // Deliberately no `IntrinsicHeight` here: these pages contain rows of
    // `Expanded` children (gender cards, the phone field) and `RenderFlex`
    // cannot report an intrinsic height for those.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: content,
        ),
      ),
    );
  }
}

/// Convenience for the top gap every inner screen uses between the app bar
/// and its first element.
class ScreenTopGap extends StatelessWidget {
  const ScreenTopGap({super.key, this.value = AppSpacing.screenTop});

  final double value;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: context.isCompactHeight ? (value * 0.7).h : value.h);
}

/// A fixed-height spacer that collapses gracefully on short devices, so a
/// design drawn at 876pt still fits a 640pt screen without overflowing.
class FlexibleGap extends StatelessWidget {
  const FlexibleGap(this.value, {super.key, this.minimum = AppSizes.lg});

  final double value;
  final double minimum;

  @override
  Widget build(BuildContext context) {
    final scale = context.isCompactHeight ? 0.6 : 1.0;
    return SizedBox(height: (value * scale).clamp(minimum, value).h);
  }
}
