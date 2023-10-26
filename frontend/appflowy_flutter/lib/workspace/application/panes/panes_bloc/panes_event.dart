part of 'panes_bloc.dart';

@freezed
class PanesEvent with _$PanesEvent {
  const factory PanesEvent.setActivePane({
    required PaneNode activePane,
  }) = SetActivePane;

  const factory PanesEvent.splitPane({
    required Plugin plugin,
    required SplitDirection splitDirection,
    String? targetPaneId,
  }) = SplitPane;

  const factory PanesEvent.closePane({
    required String paneId,
    @Default(false) bool closingToMove,
  }) = ClosePane;

  const factory PanesEvent.openTabInActivePane({
    required Plugin plugin,
  }) = OpenTabInActivePane;

  const factory PanesEvent.opnePluginInActivePane({
    required Plugin plugin,
  }) = OpenPluginInActivePane;

  const factory PanesEvent.selectTab({
    required int index,
    PaneNode? pane,
  }) = SelectTab;

  const factory PanesEvent.closeCurrentTab() = CloseCurrentTab;

  const factory PanesEvent.setDragStatus({
    required bool status,
  }) = SetDragStatus;

  const factory PanesEvent.movePane({
    required PaneNode from,
    required PaneNode to,
    required FlowyDraggableHoverPosition position,
  }) = MovePane;
}
