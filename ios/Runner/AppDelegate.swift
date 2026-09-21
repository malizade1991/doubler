import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Mirrors `MainActivity.kt`: app-private key/value storage for the BYOK key.
  /// `PlatformKeyStore` degrades to memory when this handler is absent.
  private let storeChannelName = "com.doubler.doubler/store"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    let channel = FlutterMethodChannel(
      name: storeChannelName,
      binaryMessenger: controller?.binaryMessenger
    )
    channel?.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard
      let args = call.arguments as? [String: Any]
      guard let key = args?["key"] as? String else {
        result(FlutterError(code: "badArgs", message: "missing 'key' argument", details: nil))
        return
      }
      switch call.method {
      case "read":
        result(defaults.string(forKey: key))
      case "write":
        guard let value = args?["value"] as? String else {
          result(FlutterError(code: "badArgs", message: "missing 'value' argument", details: nil))
          return
        }
        defaults.set(value, forKey: key)
        result(true)
      case "remove":
        defaults.removeObject(forKey: key)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
