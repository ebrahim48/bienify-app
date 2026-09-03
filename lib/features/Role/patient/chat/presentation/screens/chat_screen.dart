import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/utils/time_format.dart';
import '../controllers/chat_controller.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_day_separator.dart';
import '../widgets/chat_header.dart';
import '../widgets/typing_bubble.dart';

/// A message thread — with a doctor during a consultation, or with the
/// courier carrying a delivery. Same screen, same machinery, different peer.
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
            // Presence and typing are read inside the `Obx` so the header
            // repaints when they change; handing the controller down would
            // leave nothing for it to track.
            Obx(
              () => ChatHeader(
                peer: controller.peer,
                onBack: Get.back<void>,
                isOnline: controller.peerPresence.value?.isOnline,
                lastSeen: controller.peerPresence.value?.lastSeen,
                isTyping: controller.isPeerTyping.value,
                // Absent on a courier thread, which has no room to call into.
                onVideoCall: controller.canCall
                    ? controller.startVideoCall
                    : null,
              ),
            ),
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
                    // One past the end while they are writing, for the dots.
                    itemCount:
                        controller.messages.length +
                        (controller.isPeerTyping.value ? 1 : 0),
                    separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == controller.messages.length) {
                        return const TypingBubble();
                      }
                      final message = controller.messages[index];
                      final previous = index == 0
                          ? null
                          : controller.messages[index - 1];
                      // The first bubble of each day carries the date above
                      // it. Without that a thread spanning two days reads as
                      // out of order, since a bubble prints only a clock.
                      final startsADay =
                          previous == null ||
                          TimeFormat.daysBetween(
                                previous.sentAt,
                                message.sentAt,
                              ) !=
                              0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (startsADay) ChatDaySeparator(at: message.sentAt),
                          ChatBubble(
                          message: controller.messages[index],
                          // Messenger draws the reader's face against one
                          // bubble, not a tick on every one.
                          isLastSeenByPeer:
                              controller.messages[index].id ==
                              controller.lastReadByPeerId,
                          peerName: controller.peer.name,
                          peerPhotoUrl: controller.peer.photoUrl,
                          onReact: (kind) =>
                              controller.react(controller.messages[index], kind),
                          // Absent once the window has closed, so long-press
                          // never offers an edit the server would refuse.
                          onEdit: controller.canEdit(message)
                              ? () => controller.beginEdit(message)
                              : null,
                          onCancelUpload: () => controller.cancelUpload(
                            controller.messages[index],
                          ),
                          onOpenMedia: () =>
                              controller.openMedia(controller.messages[index]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            // Says which message the composer is about to change, and how to
            // back out — without it, edit mode is a text box that has silently
            // stopped sending new messages.
            Obx(
              () => controller.editing.value == null
                  ? const SizedBox.shrink()
                  : _EditingBanner(onCancel: controller.cancelEdit),
            ),
            Obx(
              () => ChatComposer(
                controller: controller.inputController,
                canSend: controller.canSend.value,
                onSend: controller.send,
                // Ask what to attach first: one paperclip that only ever
                // picked a photo made sending a PDF impossible.
                onAttach: () async {
                  final source = await AttachmentSheet.show(context);
                  if (source != null) await controller.attach(source);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The strip above the composer while a message is being rewritten.
class _EditingBanner extends StatelessWidget {
  const _EditingBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary50,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 16.w, color: AppColors.primary600),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Text(
              AppStrings.editingMessage.tr,
              style: AppTextStyles.bodyMedium.rc(AppColors.primary600),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close, size: 18.w, color: AppColors.primary600),
            tooltip: AppStrings.cancel.tr,
          ),
        ],
      ),
    );
  }
}
