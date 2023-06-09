import 'package:flowy_infra/plugins/models/flowy_dynamic_plugin.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dynamic_plugin_event.freezed.dart';

@freezed
class DynamicPluginEvent with _$DynamicPluginEvent {
  factory DynamicPluginEvent.addPlugin() = _AddPlugin;
  factory DynamicPluginEvent.removePlugin({required String name}) =
      _RemovePlugin;
  factory DynamicPluginEvent.load() = _Load;
}
