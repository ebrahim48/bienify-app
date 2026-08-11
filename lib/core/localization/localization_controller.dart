import 'dart:ui';

import 'package:get/get.dart';

import '../services/storage_service.dart';

/// A language the app can run in, as offered by the onboarding toggle.
enum AppLanguage {
  english('en', 'US', 'En'),
  spanish('es', 'ES', 'Spa');

  const AppLanguage(this.languageCode, this.countryCode, this.shortLabel);

  final String languageCode;
  final String countryCode;

  /// Two-to-three letter label rendered inside the segmented toggle.
  final String shortLabel;

  Locale get locale => Locale(languageCode, countryCode);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
    (language) => language.languageCode == code,
    orElse: () => AppLanguage.english,
  );
}

/// Owns the active locale and persists it across launches.
///
/// Registered permanently in `DependencyInjection` so any screen can call
/// `Get.find<LocalizationController>().change(AppLanguage.spanish)`.
class LocalizationController extends GetxController {
  LocalizationController(this._storage);

  final StorageService _storage;

  final Rx<AppLanguage> current = AppLanguage.english.obs;

  /// Locale to hand to `GetMaterialApp` at startup.
  Locale get initialLocale => AppLanguage.fromCode(
    _storage.getString(StorageKeys.selectedLanguage),
  ).locale;

  @override
  void onInit() {
    super.onInit();
    current.value = AppLanguage.fromCode(
      _storage.getString(StorageKeys.selectedLanguage),
    );
  }

  bool isSelected(AppLanguage language) => current.value == language;

  Future<void> change(AppLanguage language) async {
    if (current.value == language) return;
    current.value = language;
    Get.updateLocale(language.locale);
    await _storage.setString(
      StorageKeys.selectedLanguage,
      language.languageCode,
    );
  }
}
