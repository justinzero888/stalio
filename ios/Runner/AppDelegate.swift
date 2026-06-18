import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register a method channel so Dart can trigger UIPasteboard.hasStrings
    // from the Dart side after Flutter is running. The call blocks the platform
    // thread (main thread) for 200-600ms on first invocation, warming the OS
    // privacy-check cache so all subsequent TextField focus events are instant.
    guard let registrar = engineBridge.pluginRegistry
            .registrar(forPlugin: "ClipboardPrewarm") else { return }
    FlutterMethodChannel(name: "stalio/prewarm", binaryMessenger: registrar.messenger())
      .setMethodCallHandler { (_, result) in
        // Skip on simulator: iOS 26+ sims with clipboard content block hasStrings
        // indefinitely. On real devices this takes 200-600ms max and warms the cache.
        #if !targetEnvironment(simulator)
        _ = UIPasteboard.general.hasStrings
        #endif
        result(nil)
      }
  }
}
