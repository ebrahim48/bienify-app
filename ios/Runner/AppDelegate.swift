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
    // com.google.android.geo.API_KEY. google_maps_flutter renders nothing on
    // iOS until the SDK is keyed, and it fails quietly — the tracking screens
    // came up blank rather than erroring. Both platforms must stay on the
    // billing-enabled project, or the map draws empty again with
    // REQUEST_DENIED.
    //
    // Must run before the registrant, which is where the maps plugin is
    // created. The registrant runs later, from
    // didInitializeImplicitFlutterEngine.
    GMSServices.provideAPIKey("AIzaSyB83H_qMryFnxRWfWNJvmNBR6pCkxfJP0E")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // The only place plugins get registered. Registering here *and* in
  // didFinishLaunchingWithOptions hits the duplicate-key assertion in
  // -[FlutterEngine registrarForPlugin:] and aborts the process at launch.
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
