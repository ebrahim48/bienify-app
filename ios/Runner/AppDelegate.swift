import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Same key as android/app/src/main/AndroidManifest.xml's
    // com.google.android.geo.API_KEY. Without this, GMSServices aborts the
    // process the instant any screen renders a GoogleMap widget.
    GMSServices.provideAPIKey("AIzaSyDzIh16RvM4ajB6XGdl9adsVJJUGJP13wU")

    // google_maps_flutter renders nothing on iOS until the SDK is keyed, and
    // it fails quietly — the tracking screens came up blank rather than
    // erroring. The Android side carries the same key in AndroidManifest.xml;
    // both must stay on the billing-enabled project, or the map draws empty
    // again with REQUEST_DENIED.
    //
    // Must run before the registrant, which is where the maps plugin is
    // created.
    GMSServices.provideAPIKey("AIzaSyB83H_qMryFnxRWfWNJvmNBR6pCkxfJP0E")
    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
