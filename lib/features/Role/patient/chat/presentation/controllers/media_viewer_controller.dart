import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../screens/media_viewer_screen.dart';

/// Drives the full-screen media viewer: which item is showing, how the reader
/// wants it scaled, and handing a file off to the device.
class MediaViewerController extends GetxController {
  MediaViewerController({required this.items, int initialIndex = 0, Dio? http})
    : index = initialIndex.obs,
      pages = PageController(initialPage: initialIndex),
      _http = http ?? Dio();

  final List<MediaItem> items;
  final RxInt index;
  final PageController pages;

  /// A bare client, not `ApiClient`. These URLs are pre-signed by the server
  /// and an `Authorization` header would invalidate the signature — the same
  /// reason the uploader does not use it either.
  final Dio _http;

  final Rx<MediaFit> fit = MediaFit.contain.obs;

  /// Guards against a second tap while a download is still running, which
  /// would otherwise fetch the same file twice.
  bool _opening = false;

  MediaItem get current => items[index.value];

  void onPageChanged(int value) {
    index.value = value;
    // Each picture is judged on its own; carrying a "fill screen" choice onto
    // the next one crops a portrait photo the reader never asked to crop.
    fit.value = MediaFit.contain;
  }

  /// Downloads the current item to the cache and asks the platform to open it.
  ///
  /// A signed URL cannot simply be handed to the OS: it expires, and Android's
  /// document viewers will not follow one. Writing the bytes to a real file
  /// first is what makes the hand-off work.
  Future<void> openExternally() async {
    if (_opening) return;
    _opening = true;
    try {
      final item = current;
      final path = item.isLocal ? item.url : await _download(item);
      if (path == null) return;

      final result = await OpenFilex.open(path);
      if (result.type == ResultType.noAppToOpen) {
        AppSnackbar.info(AppStrings.noAppForFile.tr);
      } else if (result.type != ResultType.done) {
        AppSnackbar.error(AppStrings.cannotOpenFile.tr);
      }
    } catch (_) {
      AppSnackbar.error(AppStrings.cannotOpenFile.tr);
    } finally {
      _opening = false;
    }
  }

  Future<String?> _download(MediaItem item) async {
    AppSnackbar.info(AppStrings.openingFile.tr);
    final directory = await getTemporaryDirectory();
    // Named by the attachment rather than by id, so the app the file opens in
    // shows the sender's filename instead of an opaque key.
    final path = '${directory.path}${Platform.pathSeparator}${_safe(item.name)}';

    await _http.download(item.url, path);
    return path;
  }

  /// Strips anything that would make the name a path rather than a filename.
  /// A server-supplied name reaching `..\..\` would otherwise write outside
  /// the cache directory.
  static String _safe(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'attachment' : cleaned;
  }

  @override
  void onClose() {
    pages.dispose();
    _http.close();
    super.onClose();
  }
}
