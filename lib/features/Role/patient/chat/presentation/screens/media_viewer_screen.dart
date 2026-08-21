import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/media_viewer_controller.dart';

/// One attachment, opened full screen from its bubble.
///
/// Reached by tapping any image, video or document in a thread. The thread
/// hands over every viewable attachment it holds rather than only the one that
/// was tapped, so the viewer can page sideways through the conversation's
/// media the way a gallery does.
class MediaViewerArgs {
  const MediaViewerArgs({required this.items, this.initialIndex = 0});

  final List<MediaItem> items;
  final int initialIndex;
}

/// An attachment reduced to what the viewer needs to draw it.
class MediaItem {
  const MediaItem({
    required this.kind,
    required this.name,
    required this.url,
    this.mime = '',
    this.aspectRatio = 4 / 3,
  });

  /// Built from a chat message, which is the only source today. Returns null
  /// for a message with nothing to show — plain text, or an attachment the
  /// server could not sign a URL for.
  static MediaItem? fromMessage(ChatMessage message) {
    final attachment = message.attachment;
    final url = attachment?.url;
    if (attachment == null || url == null || url.isEmpty) return null;
    if (message.kind == MessageKind.text) return null;

    return MediaItem(
      kind: message.kind,
      name: attachment.name,
      url: url,
      mime: attachment.mime,
      aspectRatio: attachment.aspectRatio,
    );
  }

  final MessageKind kind;
  final String name;
  final String url;
  final String mime;
  final double aspectRatio;

  /// A local path while an upload is still running; anything else is signed
  /// by the server and fetched over the network.
  bool get isLocal => !url.startsWith('http');
}

/// How the picture is scaled to the screen, chosen by the reader.
///
/// The request was to "see it in different ratio by choosing it": rather than
/// distorting the media to fixed ratios, the choice is over how it fills the
/// viewport, which is the same control a photo app offers and never lies about
/// the picture's real shape (except [BoxFit.fill], which is offered explicitly
/// and labelled "Stretch").
enum MediaFit {
  contain(BoxFit.contain, AppStrings.fitContain, Icons.fit_screen_outlined),
  cover(BoxFit.cover, AppStrings.fitCover, Icons.crop_free_rounded),
  fitWidth(BoxFit.fitWidth, AppStrings.fitWidth, Icons.swap_horiz_rounded),
  fitHeight(BoxFit.fitHeight, AppStrings.fitHeight, Icons.swap_vert_rounded),
  fill(BoxFit.fill, AppStrings.fitFill, Icons.aspect_ratio_rounded);

  const MediaFit(this.boxFit, this.label, this.icon);

  final BoxFit boxFit;
  final String label;
  final IconData icon;
}

class MediaViewerScreen extends StatelessWidget {
  const MediaViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MediaViewerController>();

    // Black rather than the app surface: a photo viewer's chrome should not
    // compete with the picture, and a light frame around a dark image reads as
    // a rendering fault.
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Obx(
          () => Text(
            controller.current.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.rc(AppColors.white),
          ),
        ),
        actions: [
          // Only images honour a fit: a video is drawn by its own surface and
          // a document never renders here at all, so offering the control on
          // those would be a button that does nothing.
          Obx(
            () => controller.current.kind == MessageKind.image
                ? _FitMenu(controller: controller)
                : const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: AppStrings.openWith.tr,
            onPressed: controller.openExternally,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: PageView.builder(
        controller: controller.pages,
        onPageChanged: controller.onPageChanged,
        itemCount: controller.items.length,
        itemBuilder: (_, index) {
          final item = controller.items[index];
          return switch (item.kind) {
            MessageKind.image => Obx(
              () => _ImageStage(item: item, fit: controller.fit.value),
            ),
            MessageKind.video => _VideoStage(item: item),
            _ => _DocumentStage(item: item, onOpen: controller.openExternally),
          };
        },
      ),
    );
  }
}

/// The fit choices, as a menu rather than a cycling button so the reader can
/// see which one is active and pick directly.
class _FitMenu extends StatelessWidget {
  const _FitMenu({required this.controller});

  final MediaViewerController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MediaFit>(
      icon: const Icon(Icons.aspect_ratio_rounded),
      onSelected: (value) => controller.fit.value = value,
      itemBuilder: (_) => [
        for (final option in MediaFit.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Icon(option.icon, size: AppSizes.xl.w),
                AppSpacing.gapH(AppSpacing.sm),
                Text(option.label.tr),
                if (controller.fit.value == option) ...[
                  const Spacer(),
                  Icon(Icons.check_rounded, size: AppSizes.xl.w),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// A picture, pinch-zoomable and pannable.
class _ImageStage extends StatelessWidget {
  const _ImageStage({required this.item, required this.fit});

  final MediaItem item;
  final MediaFit fit;

  @override
  Widget build(BuildContext context) {
    final image = item.isLocal
        ? Image.file(File(item.url), fit: fit.boxFit)
        : Image.network(
            item.url,
            fit: fit.boxFit,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
            errorBuilder: (_, _, _) => _Failed(message: item.name),
          );

    return InteractiveViewer(
      // Room to read a prescription photographed at arm's length, without
      // letting a stray pinch throw the picture off screen entirely.
      minScale: 1,
      maxScale: 5,
      child: SizedBox.expand(child: image),
    );
  }
}

/// A video with a play/pause control and a scrub bar.
///
/// Stateful and per-page: a [VideoPlayerController] owns a platform texture,
/// so one is created when its page is built and disposed when it leaves —
/// paging through ten videos must not leave ten decoders running.
class _VideoStage extends StatefulWidget {
  const _VideoStage({required this.item});

  final MediaItem item;

  @override
  State<_VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<_VideoStage> {
  VideoPlayerController? _player;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final item = widget.item;
    final player = item.isLocal
        ? VideoPlayerController.file(File(item.url))
        : VideoPlayerController.networkUrl(Uri.parse(item.url));

    try {
      await player.initialize();
      // The page may have been swiped away while the decoder was starting.
      if (!mounted) {
        await player.dispose();
        return;
      }
      await player.play();
      setState(() => _player = player);
    } catch (_) {
      await player.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _Failed(message: widget.item.name);

    final player = _player;
    if (player == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.white));
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: player.value.aspectRatio,
            child: GestureDetector(
              onTap: () => setState(
                () => player.value.isPlaying ? player.pause() : player.play(),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(player),
                  // Only while paused: an overlay on a playing video would sit
                  // on top of the picture for the whole run time.
                  if (!player.value.isPlaying)
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: 64.w,
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                ],
              ),
            ),
          ),
          VideoProgressIndicator(
            player,
            allowScrubbing: true,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: AppSpacing.md.h,
            ),
          ),
        ],
      ),
    );
  }
}

/// A document, which this app deliberately does not try to render.
///
/// PDFs, spreadsheets and Word files each need their own renderer, and an
/// in-app viewer that handles one format and fails on the rest is worse than
/// handing the file to whatever the reader already has installed. The button
/// downloads it and asks the platform to open it.
class _DocumentStage extends StatelessWidget {
  const _DocumentStage({required this.item, required this.onOpen});

  final MediaItem item;
  final Future<void> Function() onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.kind == MessageKind.audio
                  ? Icons.graphic_eq_rounded
                  : Icons.description_rounded,
              size: 72.w,
              color: AppColors.white,
            ),
            AppSpacing.gapV(AppSpacing.md),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.rc(AppColors.white),
            ),
            AppSpacing.gapV(AppSpacing.lg),
            FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(AppStrings.openWith.tr),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the media itself will not load, naming the file so the reader
/// knows which one failed.
class _Failed extends StatelessWidget {
  const _Failed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 56.w,
              color: AppColors.gray400,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            Text(
              AppStrings.attachmentUnavailable.tr,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
            ),
            AppSpacing.gapV(AppSpacing.xs2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.rc(AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }
}
