import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Browses the device's files for a prescription or a report — the
/// "Attachment" / "Browse File" tiles, as opposed to "Camera".
///
/// One place owns `FilePicker`, mirroring [PhotoPickerService]. Cancelling
/// returns null; a plugin failure is swallowed into null too, for the same
/// reason: every caller treats "nothing picked" the same way.
class DocumentPickerService {
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  Future<File?> pick() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
      final path = file?.path;
      return path == null ? null : File(path);
    } on Exception catch (error) {
      debugPrint('DocumentPickerService: $error');
      return null;
    }
  }
}
