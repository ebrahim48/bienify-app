import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../services/attachment_picker_service.dart';
import 'api_client.dart';

/// What the server needs to be told about a file already in the bucket.
class UploadedAttachment {
  const UploadedAttachment({
    required this.key,
    required this.name,
    required this.mime,
    required this.size,
    this.width,
    this.height,
    this.durationMs,
  });

  final String key;
  final String name;
  final String mime;
  final int size;
  final int? width;
  final int? height;
  final int? durationMs;

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'mime': mime,
    'size': size,
    'width': ?width,
    'height': ?height,
    'durationMs': ?durationMs,
  };
}

/// Puts a picked file into the bucket and reports what to attach to a message.
///
/// Two steps, because the bytes never pass through the API: the server issues
/// a presigned PUT, and the device uploads straight to S3 with it. Proxying a
/// video through the backend would hold a request open for the whole transfer.
///
/// Uses a bare [Dio], not the app's [ApiClient]: the presigned URL carries its
/// own signature, and attaching the app's `Authorization` header to an S3
/// request makes the signature invalid.
class AttachmentUploader {
  AttachmentUploader(this._api, {Dio? storage})
    : _storage = storage ?? Dio();

  final ApiClient _api;
  final Dio _storage;

  /// Uploads [attachment], reporting progress from 0 to 1.
  ///
  /// [cancelToken] lets a caller abandon a large file — a patient who picked
  /// the wrong video should not have to wait for it to finish before sending
  /// the right one.
  Future<UploadedAttachment> upload({
    required String appointmentId,
    required PickedAttachment attachment,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (attachment.size > AttachmentPickerService.maxBytes) {
      throw ValidationException(
        'That file is too large to send',
        const {},
      );
    }

    final issued = await _api.postMap(
      ApiConstants.postConsultationsAttachmentUploadUrl(appointmentId),
      body: {'contentType': attachment.mime, 'fileName': attachment.name},
    );

    final url = '${issued['url'] ?? ''}';
    final key = '${issued['key'] ?? ''}';
    if (url.isEmpty || key.isEmpty) {
      throw UnknownException('The server did not issue an upload location');
    }

    await putBytes(
      url: url,
      file: attachment.file,
      mime: attachment.mime,
      size: attachment.size,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );

    return UploadedAttachment(
      key: key,
      name: attachment.name,
      mime: attachment.mime,
      size: attachment.size,
      width: attachment.width,
      height: attachment.height,
      durationMs: attachment.durationMs,
    );
  }

  /// PUTs a file at a presigned URL, whoever issued it.
  ///
  /// Shared with the medical vault, which uploads through a different
  /// endpoint but into the same bucket by the same rules. Duplicating this
  /// would mean two places to get the streaming, the headers and the expiry
  /// handling right.
  Future<void> putBytes({
    required String url,
    required File file,
    required String mime,
    required int size,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _storage.put<void>(
        url,
        // Streamed rather than loaded whole: a 25MB file read into memory on
        // a mid-range phone is a real risk of being killed by the OS.
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentTypeHeader: mime,
            Headers.contentLengthHeader: size,
          },
        ),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) rethrow;
      // The signature expires after five minutes, so a slow connection can
      // fail here having done nothing wrong.
      throw UnknownException('The upload did not complete. Try again.');
    }
  }
}
