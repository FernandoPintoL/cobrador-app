import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurar Google Maps para iOS
    // API Key desde .env: GOOGLE_MAPS_API_KEY_IOS
    // IMPORTANTE: Esta API key debe tener Maps SDK for iOS habilitado
    GMSServices.provideAPIKey("AIzaSyDu3Gw25vNkS9VFu-ZItz5TrU8qvVn446s")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
