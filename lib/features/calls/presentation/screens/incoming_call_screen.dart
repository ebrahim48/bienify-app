import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/call_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../widgets/call_stage.dart';
import '../widgets/closes_with_the_call.dart';

/// The full screen a ring arrives on.
///
/// Pushed by [CallService] over whatever the person happened to be looking at,
/// which is the point: a consultation call that announced itself in a corner
/// of the appointments list was one that got missed.
class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  static const Key acceptKey = ValueKey('call-accept');
  static const Key declineKey = ValueKey('call-decline');

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with ClosesWithTheCall<IncomingCallScreen> {
  @override
  Widget build(BuildContext context) {
    // Back must not silently leave the caller ringing into nothing. Declining
    // is what the gesture means, so that is what it does.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) calls.decline();
      },
      child: Obx(() {
        final peer = calls.peer.value;
        return CallStage(
          caption: AppStrings.incomingCallTitle.tr,
          name: peer?.name ?? '',
          photoUrl: peer?.avatarUrl,
          status: AppStrings.callRinging.tr,
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CallActionButton(
                key: IncomingCallScreen.declineKey,
                icon: Icons.call_end_rounded,
                color: AppColors.error500,
                label: AppStrings.callDecline.tr,
                onPressed: calls.decline,
              ),
              AppSpacing.gapH(AppSpacing.xl2),
              CallActionButton(
                key: IncomingCallScreen.acceptKey,
                icon: Icons.videocam_rounded,
                color: AppColors.success500,
                label: AppStrings.callAccept.tr,
                onPressed: calls.accept,
              ),
            ],
          ),
        );
      }),
    );
  }
}
