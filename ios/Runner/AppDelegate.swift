import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps SDK API key — used by google_maps_flutter for the
    // Suppliers/Community Marketplace map view. Must be provided before
    // GeneratedPluginRegistrant registers, or map views will render blank.
    GMSServices.provideAPIKey("AIzaSyChvBqHrWLf19LU9W3KiAg4bFsOvKwdJdU")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
