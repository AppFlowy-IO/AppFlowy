import 'dart:html';

import 'package:flutter/services.dart';

import '../keyboard_platform_interface.dart';

// ignore: constant_identifier_names
const INFRA_UI_KEYBOARD_EVENT_CHANNEL_NAME = "flowy_infra_ui_event/keyboard";

class MethodChannelKeyboard extends KeyboardPlatform {
  final EventChannel _keyboardChannel = const EventChannel(INFRA_UI_KEYBOARD_EVENT_CHANNEL_NAME);

  late final Stream<bool> _onKeyboardChange = _keyboardChannel.receiveBroadcastStream().map((event) => event as bool);

  @override
  Stream<bool> get onKeyboardChange => _onKeyboardChange;
}
