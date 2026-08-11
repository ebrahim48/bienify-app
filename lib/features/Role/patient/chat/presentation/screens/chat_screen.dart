import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_header.dart';

/// A message thread with a doctor.
class ChatScreen extends GetView<ChatController> {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The header is a saturated blue, so the status bar needs light icons
      // here even though the rest of the app is light-on-dark.
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        body: Column(
          children: [
            ChatHeader(peer: controller.peer, onBack: Get.back<void>),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Obx(
                  () => ListView.separated(
                    controller: controller.scrollController,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding.w,
                      vertical: AppSpacing.base.h,
                    ),
                    itemCount: controller.messages.length,
                    separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        ChatBubble(message: controller.messages[index]),
                  ),
                ),
              ),
            ),
            Obx(
              () => ChatComposer(
                controller: controller.inputController,
                canSend: controller.canSend.value,
                onSend: controller.send,
                onAttach: controller.attach,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
