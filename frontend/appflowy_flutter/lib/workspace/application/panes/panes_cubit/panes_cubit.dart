import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes_service.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_target.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../panes.dart';

part 'panes_state.dart';

enum SplitDirection { left, right, up, down, none }

class PanesCubit extends Cubit<PanesState> {
  final PanesService panesService;
  PanesCubit()
      : panesService = PanesService(),
        super(PanesState.initial());

  void setActivePane(PaneNode activePane) {
    emit(state.copyWith(activePane: activePane));
    state.activePane.tabs.setLatestOpenView();
  }

  void split({
    required Plugin plugin,
    required SplitDirection splitDirection,
    String? targetPaneId,
  }) {
    if (state.count >= 4) {
      return;
    }
    final direction =
        [SplitDirection.right, SplitDirection.down].contains(splitDirection)
            ? Direction.front
            : Direction.back;

    final axis =
        [SplitDirection.down, SplitDirection.up].contains(splitDirection)
            ? Axis.horizontal
            : Axis.vertical;

    final root = panesService.splitHandler(
      node: state.root,
      targetPaneId: targetPaneId ?? state.activePane.paneId,
      plugin: plugin,
      direction: direction,
      axis: axis,
    );

    final firstLeafNode = panesService.findFirstLeaf(node: root);

    emit(
      state.copyWith(
        root: root,
        count: state.count + 1,
        firstLeafNode: firstLeafNode,
      ),
    );
    setActivePane(root.children.last);
  }

  void closePane({
    required String paneId,
  }) {
    final root = panesService.closePaneHandler(
      node: state.root,
      targetPaneId: paneId,
      closingToMove: false,
    );

    final firstLeafNode = panesService.findFirstLeaf(node: root);

    emit(
      state.copyWith(
        root: root,
        firstLeafNode: firstLeafNode,
        count: state.count - 1,
      ),
    );

    final children = root.children;
    setActivePane(children.isEmpty ? root : children.last);
  }

  void openTab({required Plugin plugin}) {
    state.activePane.tabs.openView(plugin);
  }

  void openPlugin({required Plugin plugin}) {
    state.activePane.tabs.openPlugin(plugin: plugin);
  }

  void selectTab({required int index, PaneNode? pane}) {
    if (pane != null) emit(state.copyWith(activePane: pane));
    state.activePane.tabs.selectTab(index: index);
  }

  void closeCurrentTab() {
    state.activePane.tabs.closeView(
      state.activePane.tabs.currentPageManager.plugin.id,
    );
  }

  void setDragStatus(bool status) {
    emit(state.copyWith(allowPaneDrag: status));
  }

  void movePane(
    PaneNode from,
    PaneNode to,
    FlowyDraggableHoverPosition position,
  ) {
    final direction = [
      FlowyDraggableHoverPosition.top,
      FlowyDraggableHoverPosition.left,
    ].contains(position)
        ? Direction.back
        : Direction.front;

    final axis = [
      FlowyDraggableHoverPosition.left,
      FlowyDraggableHoverPosition.right,
    ].contains(position)
        ? Axis.vertical
        : Axis.horizontal;

    final root = panesService.movePaneHandler(
      toNode: to,
      direction: direction,
      axis: axis,
      root: state.root,
      fromNode: from,
    );

    final firstLeafNode = panesService.findFirstLeaf(node: root);

    emit(
      state.copyWith(
        root: root,
        firstLeafNode: firstLeafNode,
      ),
    );

    final children = state.root.children;
    setActivePane(children.isEmpty ? state.root : children.last);
  }
}
