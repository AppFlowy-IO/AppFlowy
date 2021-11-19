import Flutter
import UIKit

public class SwiftFlowyInfraUiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flowy_infra_ui", binaryMessenger: registrar.messenger())
    let instance = SwiftFlowyInfraUiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
