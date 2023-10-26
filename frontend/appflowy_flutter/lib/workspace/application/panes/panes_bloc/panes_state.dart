part of 'panes_bloc.dart';

@freezed
class PanesState with _$PanesState {
  const factory PanesState({
    required PaneNode activePane,
    required PaneNode root,
    required int count,
    required bool allowPaneDrag,
    required PaneNode firstLeafNode,
  }) = _PaneState;

  factory PanesState.initial() {
    final pane = PaneNode.initial();
    return PanesState(
      activePane: pane,
      root: pane,
      count: 1,
      allowPaneDrag: false,
      firstLeafNode: pane,
    );
  }
}
