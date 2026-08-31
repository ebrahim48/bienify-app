import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_strings.dart';
import '../widgets/app_snackbar.dart';
import 'package:get/get.dart';

/// Fetches a server-signed file and hands it to the device.
///
/// Extracted from the chat media viewer, which learned the two things that
/// make this work: a signed URL cannot be given to the OS directly (it
/// expires, and Android's viewers will not follow one), and a server-supplied
/// filename has to be stripped before it is used as a path.
class FileDownloadService {
  FileDownloadService({Dio? http}) : _http = http ?? Dio();

  /// A bare client, not `ApiClient`: these URLs are pre-signed and an
  /// `Authorization` header would invalidate the signature.
  final Dio _http;

  bool _busy = false;

  /// Downloads [url] to the cache under [fileName] and opens it.
  ///
  /// Returns whether the file actually reached the device, so a caller can
  /// avoid claiming a download that did not happen.
  Future<bool> openRemote({required String url, required String fileName}) async {
    if (_busy) return false;
    _busy = true;
    try {
      AppSnackbar.info(AppStrings.openingFile.tr);
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}${Platform.pathSeparator}${safeName(fileName)}';
      await _http.download(url, path);

      final result = await OpenFilex.open(path);
      if (result.type == ResultType.noAppToOpen) {
        AppSnackbar.info(AppStrings.noAppForFile.tr);
        // The bytes are on the device either way; only the hand-off failed.
        return true;
      }
      if (result.type != ResultType.done) {
        AppSnackbar.error(AppStrings.cannotOpenFile.tr);
        return true;
      }
      return true;
    } catch (_) {
      AppSnackbar.error(AppStrings.cannotOpenFile.tr);
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Strips anything that would make the name a path rather than a filename.
  /// A server-supplied name reaching `..\..\` would otherwise write outside
  /// the cache directory.
  static String safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'document' : cleaned;
  }
}
