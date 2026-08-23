import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Held by the delegate so it outlives registration: it owns the audio
  /// session and the meter timer for as long as the app is running.
  private let captureRecorder = CaptureRecorder()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    captureRecorder.register(
      with: engineBridge.pluginRegistry.registrar(forPlugin: "CaptureRecorder")!
    )
  }
}
