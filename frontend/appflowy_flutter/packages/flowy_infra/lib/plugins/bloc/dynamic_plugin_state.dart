import 'package:freezed_annotation/freezed_annotation.dart';

part 'dynamic_plugin_state.freezed.dart';

@freezed
class DynamicPluginState with _$DynamicPluginState {
  const factory DynamicPluginState.ready() = _Ready;
  const factory DynamicPluginState.processing() = _Processing;
  const factory DynamicPluginState.compilationFailure({
    required String path,
  }) = _CompilationFailure;
  const factory DynamicPluginState.compilationSuccess() = _CompilationSuccess;
}
