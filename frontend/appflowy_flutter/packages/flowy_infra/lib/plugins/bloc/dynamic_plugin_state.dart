import 'package:freezed_annotation/freezed_annotation.dart';

import '../service/models/flowy_dynamic_plugin.dart';

part 'dynamic_plugin_state.freezed.dart';

@freezed
class DynamicPluginState with _$DynamicPluginState {
  const factory DynamicPluginState.uninitialized() = _Uninitialized;
  const factory DynamicPluginState.ready({
    required Iterable<FlowyDynamicPlugin> plugins,
  }) = Ready;
  const factory DynamicPluginState.processing() = _Processing;
  const factory DynamicPluginState.compilationFailure(
      {required String errorMessage}) = _CompilationFailure;
  const factory DynamicPluginState.deletionFailure({
    required String path,
  }) = _DeletionFailure;
  const factory DynamicPluginState.deletionSuccess() = _DeletionSuccess;
  const factory DynamicPluginState.compilationSuccess() = _CompilationSuccess;
}
