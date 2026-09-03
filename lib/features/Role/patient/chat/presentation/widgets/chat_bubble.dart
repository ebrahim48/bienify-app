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
import '../../domain/entities/conversation.dart';
import 'message_attachment_view.dart';
import 'reaction_picker.dart';

/// One message bubble: white on the left for the doctor, `primary600` on the
/// right for the patient, each with a timestamp underneath the text.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.isLastSeenByPeer = false,
    this.peerName,
    this.peerPhotoUrl,
    this.myUserId,
    this.onReact,
    this.onEdit,
    this.onCancelUpload,
    this.onOpenMedia,
  });

  final ChatMessage message;

  /// The newest of my messages the other side has read. Messenger marks that
  /// one bubble with the reader's face rather than ticking every bubble.
  final bool isLastSeenByPeer;
  final String? peerName;
  final String? peerPhotoUrl;

  /// Whose reaction counts as mine, for highlighting it in the row and in the
  /// picker.
  final String? myUserId;

  /// Called with the chosen emoji, or with an empty string to clear.
  final void Function(String emoji)? onReact;

  /// Offered only while the message is still inside the edit window, so the
  /// menu never shows a choice the server would refuse.
  final VoidCallback? onEdit;
  final VoidCallback? onCancelUpload;

  /// Opens this bubble's attachment full screen. Null on a text message, and
  /// on one whose upload has not finished — there is nothing to open yet.
  final VoidCallback? onOpenMedia;

  /// Bubbles stop well short of the opposite edge so the thread stays
  /// readable as a conversation.
  static const double _maxWidthFactor = 0.76;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final ink = isMine ? AppColors.white : AppColors.gray900;

    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            // Long press rather than a visible button: a reaction control on every
            // bubble would crowd the thread, and long-press is the gesture people
            // already reach for.
            onLongPress: _hasActions ? () => _openActions(context) : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.xs.h + 2,
                ),
                decoration: BoxDecoration(
                  color: isMine ? AppColors.primary600 : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  border: isMine
                      ? null
                      : Border.all(
                          color: AppColors.surfaceBorder,
                          width: AppSizes.borderWidth,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.hasAttachment) ...[
                      // Only the attachment opens the viewer, not the whole
                      // bubble — a tap on the caption should not leave the
                      // thread. Long press is not claimed here, so it still
                      // reaches the outer recognizer and offers reactions.
                      GestureDetector(
                        onTap: message.uploadProgress == null
                            ? onOpenMedia
                            : null,
                        child: AttachmentBody(
                          message: message,
                          isMine: isMine,
                          onCancelUpload: onCancelUpload,
                        ),
                      ),
                      if (message.hasText) AppSpacing.gapV(AppSpacing.xs),
                    ],
                    // A caption is optional on an attachment, so an empty body draws
                    // nothing rather than an empty line.
                    if (message.hasText)
                      Text(
                        message.text,
                        style: AppTextStyles.bodyLarge.rc(ink),
                      ),
                    AppSpacing.gapV(AppSpacing.xs2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          // Marked beside the clock, as Messenger does: a
                          // reader who saw the first version is owed the fact
                          // that these are not the words that were sent.
                          message.wasEdited
                              ? '${message.timeLabel} · ${AppStrings.messageEdited.tr}'
                              : message.timeLabel,
                          style: AppTextStyles.bodyMedium.rc(
                            isMine
                                ? AppColors.primary100
                                : AppColors.textSecondary,
                          ),
                        ),
                        // Only on our own bubbles: the other side's arrival is its
                        // own receipt, so a tick there would mean nothing.
                        if (isMine) ...[
                          AppSpacing.gapH(AppSpacing.xs2),
                          _DeliveryTicks(state: message.deliveryState),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (message.reactions.isNotEmpty)
          ReactionRow(reactions: message.reactions, myUserId: myUserId),
        if (isLastSeenByPeer)
          SeenMarker(name: peerName, photoUrl: peerPhotoUrl),
      ],
    );
  }

  bool get _hasActions => onReact != null || onEdit != null;

  /// What long-press offers.
  ///
  /// Reacting alone still goes straight to the picker, which is the gesture
  /// this app already had; a menu in front of it would put a tap between
  /// every reaction and the thread. The sheet appears only once there is a
  /// second thing to choose.
  Future<void> _openActions(BuildContext context) async {
    if (onEdit == null) return _pickReaction(context);

    final choice = await showModalBottomSheet<_MessageAction>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (_) => const _MessageActionSheet(),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _MessageAction.react:
        await _pickReaction(context);
      case _MessageAction.edit:
        onEdit?.call();
    }
  }

  /// The quick row, with the full emoji keyboard one tap behind it.
  Future<void> _pickReaction(BuildContext context) async {
    final mine = message.reactions
        .where((r) => r.userId == myUserId)
        .firstOrNull
        ?.emoji;

    final chosen = await ReactionPicker.show(context, selected: mine);
    // Null is a dismissed sheet and must change nothing; the empty string is a
    // deliberate "take mine back", which the controller sends as a clear.
    if (chosen != null) onReact?.call(chosen);
  }
}

/// The sent → delivered → read indicator on an outgoing bubble.
///
/// A clock while the server has not confirmed, one tick once it has, two once
/// the other device holds it, and two tinted once they have opened the thread.
/// Drawn from [DeliveryState] rather than from raw timestamps so the bubble
/// cannot disagree with the model about what has happened.
class _DeliveryTicks extends StatelessWidget {
  const _DeliveryTicks({required this.state});

  final DeliveryState state;

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.lg.w;

    if (state == DeliveryState.sending) {
      return Icon(
        Icons.schedule_rounded,
        size: size,
        color: AppColors.primary100,
      );
    }

    final isRead = state == DeliveryState.read;
    final colour = isRead ? AppColors.success400 : AppColors.primary100;

    return Icon(
      state == DeliveryState.sent
          ? Icons.check_rounded
          : Icons.done_all_rounded,
      size: size,
      color: colour,
    );
  }
}

/// What long-press offers on a message.
enum _MessageAction { react, edit }

class _MessageActionSheet extends StatelessWidget {
  const _MessageActionSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.all(AppSpacing.base.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_reaction_outlined),
              title: Text(
                AppStrings.reactToMessage.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              ),
              onTap: () =>
                  Navigator.of(context).pop(_MessageAction.react),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(
                AppStrings.editMessage.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              ),
              onTap: () => Navigator.of(context).pop(_MessageAction.edit),
            ),
          ],
        ),
      ),
    );
  }
}
