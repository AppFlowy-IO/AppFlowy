import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dynamic_plugin_event.freezed.dart';

@freezed
class DynamicPluginEvent with _$DynamicPluginEvent {
  factory DynamicPluginEvent.addPlugin() = _AddPlugin;
}
