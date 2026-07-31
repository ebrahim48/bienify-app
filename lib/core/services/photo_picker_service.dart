import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Where a photo came from.
enum PhotoSource { camera, gallery }

/// Captures a photo from the camera or the gallery.
///
/// One place owns the `ImagePicker`, so every upload box in the app behaves
/// the same and the plugin is only referenced here. Cancelling returns null;
/// a plugin failure (no camera, permission refused) is swallowed into null
/// too, because every caller treats "no photo" the same way and a
/// `PlatformException` reaching the UI would be a crash rather than a choice.
class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Shrinks what the camera hands back: a 12MP original is 20× larger than
  /// anything these forms display, and the whole file gets uploaded.
  static const int _maxSide = 1600;
  static const int _quality = 85;

  Future<File?> pick(PhotoSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxSide.toDouble(),
        maxHeight: _maxSide.toDouble(),
        imageQuality: _quality,
        preferredCameraDevice: CameraDevice.front,
      );
      return file == null ? null : File(file.path);
    } on Exception catch (error) {
      debugPrint('PhotoPickerService: $error');
      return null;
    }
  }
}
