part of 'pane_node_bloc.dart';

@freezed
class PaneNodeEvent with _$PaneNodeEvent {
  const factory PaneNodeEvent.resizeStart() = ResizeStart;
  const factory PaneNodeEvent.resizeUpdate({
    required int targetIndex,
    required double offset,
    required double availableWidth,
  }) = ResizeUpdate;
}
