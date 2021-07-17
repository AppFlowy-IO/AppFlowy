import Flutter
import UIKit

public class SwiftFlowyInfraUiPlugin: NSObject, FlutterPlugin {

    enum Constant {
        static let infraUIMethodChannelName = "flowy_infra_ui_method"
        static let infraUIKeyboardEventChannelName = "flowy_infra_ui_event/keyboard"
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlowyInfraUiPlugin()

        let methodChannel = FlutterMethodChannel(
            name: Constant.infraUIMethodChannelName,
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let keyboardEventChannel = FlutterEventChannel(
            name: Constant.infraUIKeyboardEventChannelName,
            binaryMessenger: registrar.messenger())
        keyboardEventChannel.setStreamHandler(KeyboardEventHandler())
    }

    // MARK: - Method Channel

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        default:
            assertionFailure("Unsupported method \(call.method)")
        }
    }

}
