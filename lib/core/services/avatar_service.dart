import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../exceptions/app_exceptions.dart';
import '../widgets/app_snackbar.dart';
import '../services/photo_picker_service.dart';
import '../widgets/photo_upload_box.dart';
import '../../features/Role/patient/profile/domain/repositories/account_repository.dart';

/// Changing the account photo, for whichever role is asking.
///
/// One place rather than four. Every role's profile screen had a "change
/// photo" control and all four called `edit()` — they opened the edit form,
/// which has no photo field, so the control did nothing at all. The endpoints
/// (`POST /users/me/avatar/upload-url` then `/confirm`) had existed since the
/// user module was written with no caller, so every avatar in the app was
/// whatever the seed had put there.
class AvatarService {
  AvatarService({AccountRepository? account})
    : _account = account ?? Get.find<AccountRepository>();

  final AccountRepository _account;

  /// 0–1 while an upload runs, null when idle.
  final RxnDouble progress = RxnDouble();

  bool get isUploading => progress.value != null;

  /// Asks for a photo, uploads it, and returns the new URL.
  ///
  /// Null when the person backed out of the picker or the upload failed — the
  /// caller then leaves the avatar as it was rather than blanking it.
  Future<String?> change(BuildContext context) async {
    if (isUploading) return null;

    // The one caller that is photographing a face rather than a document.
    final file = await pickPhoto(context, facing: PhotoFacing.front);
    if (file == null) return null;

    progress.value = 0;
    try {
      final url = await _account.uploadAvatar(
        path: file.path,
        mimeType: _mimeOf(file.path),
        onProgress: (value) => progress.value = value,
      );
      AppSnackbar.success(AppStrings.photoUpdated.tr);
      return url;
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return null;
    } finally {
      progress.value = null;
    }
  }

  /// The picker hands back whatever the camera or gallery produced. The server
  /// signs three image types; a phone camera produces the first.
  static String _mimeOf(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

/// Gives a profile controller a working "change photo" action.
///
/// Each role keeps its profile in a different entity, none of which has a
/// `copyWith`, so the new photo is picked up by re-reading the profile rather
/// than by patching four shapes. The read is one request and it also catches
/// anything else that changed while the person was in the picker.
mixin AvatarChanging on GetxController {
  AvatarService get avatars => Get.find<AvatarService>();

  /// Re-read this role's profile. Usually the controller's own `load`.
  Future<void> reloadProfile();

  Future<void> changePhotoWith(BuildContext context) async {
    final url = await avatars.change(context);
    if (url != null && url.isNotEmpty) await reloadProfile();
  }
}
