//
//  KeyboardEventHandler.swift
//  flowy_infra_ui
//
//  Created by Jaylen Bian on 7/17/21.
//

class KeyboardEventHandler: NSObject, FlutterStreamHandler {

    var isKeyboardShow: Bool = false
    var eventSink: FlutterEventSink?

    override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow),
            name: UIApplication.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardDidShow),
            name: UIApplication.keyboardDidShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIApplication.keyboardWillHideNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardDidHide),
            name: UIApplication.keyboardDidHideNotification,
            object: nil)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // MARK: Helper

    @objc
    private func handleKeyboardWillShow() {
        guard !isKeyboardShow else {
            return
        }
        isKeyboardShow = true
        eventSink?(NSNumber(booleanLiteral: true))
    }

    @objc
    private func handleKeyboardDidShow() {
        guard !isKeyboardShow else {
            return
        }
        isKeyboardShow = true
        eventSink?(NSNumber(booleanLiteral: true))
    }

    @objc
    private func handleKeyboardWillHide() {
        guard isKeyboardShow else {
            return
        }
        isKeyboardShow = false
        eventSink?(NSNumber(booleanLiteral: false))
    }

    @objc
    private func handleKeyboardDidHide() {
        guard isKeyboardShow else {
            return
        }
        isKeyboardShow = false
        eventSink?(NSNumber(booleanLiteral: false))
    }
}
