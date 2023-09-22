import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes_service.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_target.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

import '../panes.dart';

part 'panes_state.dart';

enum SplitDirection { left, right, up, down, none }

class PanesCubit extends Cubit<PanesState> {
  final PanesService panesService;
  PanesCubit({required double offset})
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

    emit(
      state.copyWith(
        root: root,
        count: state.count + 1,
      ),
    );
    setActivePane(state.root.children.last);
  }

  void closePane({required String paneId}) {
    emit(
      state.copyWith(
        root: panesService.closePaneHandler(
          node: state.root,
          targetPaneId: paneId,
        ),
        count: state.count - 1,
      ),
    );

    final children = state.root.children;
    setActivePane(children.isEmpty ? state.root : children.last);
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

  void movePane(
    PaneNode from,
    PaneNode to,
    FlowyDraggableHoverPosition position,
  ) {
    final direction = [
      FlowyDraggableHoverPosition.top,
      FlowyDraggableHoverPosition.left
    ].contains(position)
        ? Direction.back
        : Direction.front;

    final axis = [
      FlowyDraggableHoverPosition.left,
      FlowyDraggableHoverPosition.right
    ].contains(position)
        ? Axis.vertical
        : Axis.horizontal;

    emit(
      state.copyWith(
        root: panesService.splitHandler(
          node: state.root,
          targetPaneId: to.paneId,
          direction: direction,
          axis: axis,
          fromNode: from,
        ),
        count: state.count + 1,
      ),
    );
    closePane(paneId: from.paneId);
  }
}
