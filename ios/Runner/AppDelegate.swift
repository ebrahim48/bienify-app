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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
