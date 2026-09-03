import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/call_stage.dart';
import '../widgets/closes_with_the_call.dart';

/// What the caller looks at while the other side rings.
///
/// It says `Connecting…` until the server has actually opened the call, and
/// only then `Ringing…`. The distinction matters: a screen that says "ringing"
/// before the invite has been accepted by the server is claiming a phone is
/// ringing somewhere when nothing may have left the device.
class OutgoingCallScreen extends StatefulWidget {
  const OutgoingCallScreen({super.key});

  static const Key cancelKey = ValueKey('call-cancel');

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with ClosesWithTheCall<OutgoingCallScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) calls.cancel();
      },
      child: Obx(() {
        final peer = calls.peer.value;
        return CallStage(
          caption: AppStrings.outgoingCallTitle.tr,
          name: peer?.name ?? '',
          photoUrl: peer?.avatarUrl,
          status: calls.active.value == null
              ? AppStrings.callConnecting.tr
              : AppStrings.callRinging.tr,
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CallActionButton(
                key: OutgoingCallScreen.cancelKey,
                icon: Icons.call_end_rounded,
                color: AppColors.error500,
                label: AppStrings.callDecline.tr,
                onPressed: calls.cancel,
              ),
            ],
          ),
        );
      }),
    );
  }
}
