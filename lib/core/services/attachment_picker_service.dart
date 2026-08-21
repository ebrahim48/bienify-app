import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// What the sender chose to attach.
enum AttachmentSource { camera, gallery, video, document }

/// A file the user picked, with everything the server needs to store it.
///
/// The dimensions matter beyond decoration: a bubble reserves the right shape
/// before the image downloads, so a thread does not jump about as pictures
/// load in.
class PickedAttachment {
  const PickedAttachment({
    required this.file,
    required this.name,
    required this.mime,
    required this.size,
    this.width,
    this.height,
    this.durationMs,
  });

  final File file;
  final String name;
  final String mime;
  final int size;
  final int? width;
  final int? height;
  final int? durationMs;
}

/// Picks a file to send in a consultation.
///
/// Separate from [PhotoPickerService], which exists to capture *a photo for a
/// form field* and deliberately downscales and prefers the front camera. An
/// attachment is a different job: it may be a video or a PDF, and shrinking a
/// document the patient was asked to send would defeat the point.
class AttachmentPickerService {
  AttachmentPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Photos are still resized. A 12MP phone original is tens of megabytes,
  /// and nothing in a chat bubble can show that detail — but far more
  /// generous than a form's avatar, since a rash or a label has to stay
  /// legible when opened full screen.
  static const double _maxImageSide = 2400;
  static const int _imageQuality = 88;

  /// The server refuses anything larger, so catching it here saves the user
  /// waiting through an upload that was always going to be rejected.
  static const int maxBytes = 25 * 1024 * 1024;

  Future<PickedAttachment?> pick(AttachmentSource source) async {
    try {
      return switch (source) {
        AttachmentSource.camera => await _image(ImageSource.camera),
        AttachmentSource.gallery => await _image(ImageSource.gallery),
        AttachmentSource.video => await _video(),
        AttachmentSource.document => await _document(),
      };
    } on Exception catch (error) {
      // Cancelling, a refused permission and a missing camera all arrive here
      // and all mean the same thing to the caller: nothing to send.
      debugPrint('AttachmentPickerService: $error');
      return null;
    }
  }

  Future<PickedAttachment?> _image(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: _maxImageSide,
      maxHeight: _maxImageSide,
      imageQuality: _imageQuality,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    // Read back after resizing, not before: the decoded size is what the
    // bubble has to reserve space for.
    final decoded = await _decodedSize(file);

    return PickedAttachment(
      file: file,
      name: _nameOf(picked.path, fallback: 'photo.jpg'),
      mime: _mimeFor(picked.path, fallback: 'image/jpeg'),
      size: await file.length(),
      width: decoded?.$1,
      height: decoded?.$2,
    );
  }

  Future<PickedAttachment?> _video() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;

    final file = File(picked.path);
    return PickedAttachment(
      file: file,
      name: _nameOf(picked.path, fallback: 'video.mp4'),
      mime: _mimeFor(picked.path, fallback: 'video/mp4'),
      size: await file.length(),
    );
  }

  Future<PickedAttachment?> _document() async {
    // `pickFile`, not `pickFiles`: one attachment per message, and the
    // multi-select variant's `allowMultiple` is deprecated in this version.
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      // Narrower than the server's allowlist on purpose: these are the types
      // a consultation actually deals in, and offering everything invites a
      // pick the upload will refuse.
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );
    final path = picked?.path;
    if (picked == null || path == null) return null;

    final file = File(path);
    return PickedAttachment(
      file: file,
      name: picked.name,
      mime: _mimeFor(picked.name, fallback: 'application/octet-stream'),
      size: await file.length(),
    );
  }

  /// Decodes just the header to learn the image's dimensions.
  ///
  /// `instantiateImageCodec` rather than `decodeImageFromList`: the latter is
  /// callback-based and returns void. `getNextFrame` reads only what it needs
  /// to describe the frame, so this does not rasterise the whole picture.
  Future<(int, int)?> _decodedSize(File file) async {
    ui.Codec? codec;
    try {
      final bytes = await file.readAsBytes();
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      return size;
    } on Exception {
      // Not fatal — the bubble falls back to a default aspect ratio.
      return null;
    } finally {
      codec?.dispose();
    }
  }

  static String _nameOf(String path, {required String fallback}) {
    final segment = path.split(RegExp(r'[/\\]')).last;
    return segment.isEmpty ? fallback : segment;
  }

  /// Derived from the extension rather than sniffed: the server validates the
  /// type it is told, and a wrong guess is refused rather than mis-stored.
  static String _mimeFor(String path, {required String fallback}) {
    final ext = path.toLowerCase().split('.').last;
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      '3gp' => 'video/3gpp',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      'wav' => 'audio/wav',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      _ => fallback,
    };
  }
}
