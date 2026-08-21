import 'dart:io';

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
import '../../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/conversation.dart';

/// An attachment inside a bubble, drawn according to its kind.
class AttachmentBody extends StatelessWidget {
  const AttachmentBody({
    super.key,
    required this.message,
    required this.isMine,
    this.onCancelUpload,
  });

  final ChatMessage message;
  final bool isMine;
  final VoidCallback? onCancelUpload;

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachment;
    if (attachment == null) return const SizedBox.shrink();
    final progress = message.uploadProgress;

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: AppRadius.rMd,
          child: switch (message.kind) {
            MessageKind.image => _ImagePreview(attachment: attachment),
            MessageKind.video => _VideoPreview(attachment: attachment),
            MessageKind.audio || MessageKind.file => _FileRow(
              attachment: attachment,
              kind: message.kind,
              isMine: isMine,
            ),
            MessageKind.text => const SizedBox.shrink(),
          },
        ),
        // Progress sits on the bubble it belongs to, so a thread with two
        // uploads in flight can say which is which — a banner could not.
        if (progress != null)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.black.withValues(alpha: 0.45),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34.w,
                      height: 34.w,
                      child: CircularProgressIndicator(
                        // Indeterminate until the first byte reports, so a
                        // stalled start does not look like a finished upload.
                        value: progress == 0 ? null : progress,
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    ),
                    if (onCancelUpload != null) ...[
                      AppSpacing.gapV(AppSpacing.xs2),
                      GestureDetector(
                        onTap: onCancelUpload,
                        child: Text(
                          AppStrings.cancel.tr,
                          style: AppTextStyles.labelSmall.rc(AppColors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// From the network once sent, and from disk while still uploading.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.attachment});

  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final url = attachment.url;
    if (url == null || url.isEmpty) return const _Unavailable();

    return AspectRatio(
      aspectRatio: attachment.aspectRatio,
      child: url.startsWith('http')
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _Unavailable(),
            )
          // A local path while the upload runs, so the sender sees their own
          // picture immediately instead of a spinner over nothing.
          : Image.file(
              File(url),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _Unavailable(),
            ),
    );
  }
}

/// A video, shown as a play affordance over its filename.
///
/// Deliberately not a thumbnail: extracting one needs a native decode pass per
/// message, and a labelled play button is honest about what tapping does.
class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.attachment});

  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200.w,
      height: 120.h,
      color: AppColors.gray900,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 34.w,
            color: AppColors.white,
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
            child: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.rc(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// A document or voice note: an icon, its name and its size.
class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.attachment,
    required this.kind,
    required this.isMine,
  });

  final MessageAttachment attachment;
  final MessageKind kind;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final ink = isMine ? AppColors.white : AppColors.gray900;
    final muted = isMine ? AppColors.primary100 : AppColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          kind == MessageKind.audio
              ? Icons.graphic_eq_rounded
              : Icons.description_rounded,
          size: AppSizes.xl2.w,
          color: ink,
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                attachment.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.rc(ink),
              ),
              Text(
                attachment.sizeLabel,
                style: AppTextStyles.labelSmall.rc(muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown when the server could not sign a URL, rather than a broken image.
class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180.w,
      height: 100.h,
      color: AppColors.gray200,
      alignment: Alignment.center,
      child: Text(
        AppStrings.attachmentUnavailable.tr,
        textAlign: TextAlign.center,
        style: AppTextStyles.labelSmall.rc(AppColors.gray600),
      ),
    );
  }
}

/// The reader's face against the newest message they have read.
///
/// One marker on one bubble, as Messenger does — a "Seen" label on every
/// message would repeat the same fact all the way down the thread.
class SeenMarker extends StatelessWidget {
  const SeenMarker({super.key, this.name, this.photoUrl});

  final String? name;
  final String? photoUrl;

  static const double _size = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs2.h, right: AppSpacing.xs2.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.seenLabel.tr,
            style: AppTextStyles.labelSmall.rc(AppColors.gray400),
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          AppAvatar(imageUrl: photoUrl, name: name, size: _size),
        ],
      ),
    );
  }
}
