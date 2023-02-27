import 'package:flowy_infra_ui_platform_interface/flowy_infra_ui_platform_interface.dart';
import 'package:flutter/services.dart';

// ignore_for_file: constant_identifier_names
const INFRA_UI_METHOD_CHANNEL_NAME = 'flowy_infra_ui_method';
const INFRA_UI_KEYBOARD_EVENT_CHANNEL_NAME = 'flowy_infra_ui_event/keyboard';
const INFRA_UI_METHOD_GET_PLATFORM_VERSION = 'getPlatformVersion';

class MethodChannelFlowyInfraUI extends FlowyInfraUIPlatform {
  final MethodChannel _methodChannel =
      const MethodChannel(INFRA_UI_METHOD_CHANNEL_NAME);
  final EventChannel _keyboardChannel =
      const EventChannel(INFRA_UI_KEYBOARD_EVENT_CHANNEL_NAME);

  late final Stream<bool> _onKeyboardVisibilityChange =
      _keyboardChannel.receiveBroadcastStream().map((event) => event as bool);

  @override
  Stream<bool> get onKeyboardVisibilityChange => _onKeyboardVisibilityChange;

  @override
  Future<String> getPlatformVersion() async {
    String? version = await _methodChannel
        .invokeMethod<String>(INFRA_UI_METHOD_GET_PLATFORM_VERSION);
    return version ?? 'unknow';
  }
}
