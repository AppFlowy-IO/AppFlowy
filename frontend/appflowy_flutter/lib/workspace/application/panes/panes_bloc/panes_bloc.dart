import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_service.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_target.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'panes_bloc.freezed.dart';
part 'panes_event.dart';
part 'panes_state.dart';

enum SplitDirection { left, right, up, down, none }

class PanesBloc extends Bloc<PanesEvent, PanesState> {
  final PanesService panesService = PanesService();

  PanesBloc() : super(PanesState.initial()) {
    on<PanesEvent>(
      (event, emit) {
        event.map(
          setActivePane: (e) {
            emit(state.copyWith(activePane: e.activePane));
            state.activePane.tabsController.setLatestOpenView();
          },
          splitPane: (e) {
            if (state.count >= 4) {
              return;
            }

            final direction = [
              SplitDirection.right,
              SplitDirection.down,
            ].contains(e.splitDirection)
                ? Direction.front
                : Direction.back;

            final axis = [
              SplitDirection.down,
              SplitDirection.up,
            ].contains(e.splitDirection)
                ? Axis.horizontal
                : Axis.vertical;

            final root = panesService.splitHandler(
              node: state.root,
              targetPaneId: e.targetPaneId ?? state.activePane.paneId,
              plugin: e.plugin,
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
            add(SetActivePane(activePane: root.children.last));
          },
          closePane: (e) {
            final root = panesService.closePaneHandler(
              node: state.root,
              targetPaneId: e.paneId,
              closingToMove: e.closingToMove,
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
            add(
              SetActivePane(
                activePane: children.isEmpty ? root : children.last,
              ),
            );
          },
          openTabInActivePane: (e) => state.activePane.tabsController.openView(e.plugin),
          opnePluginInActivePane: (e) => state.activePane.tabsController.openPlugin(plugin: e.plugin),
          selectTab: (e) {
            if (e.pane != null) {
              emit(state.copyWith(activePane: e.pane!));
            }

            state.activePane.tabsController.selectTab(index: e.index);
          },
          closeCurrentTab: (e) => state.activePane.tabsController.closeView(
            state.activePane.tabsController.currentPageManager.plugin.id,
          ),
          setDragStatus: (e) => emit(state.copyWith(allowPaneDrag: e.status)),
          movePane: (e) {
            final direction = [
              FlowyDraggableHoverPosition.top,
              FlowyDraggableHoverPosition.left,
            ].contains(e.position)
                ? Direction.back
                : Direction.front;

            final axis = [
              FlowyDraggableHoverPosition.left,
              FlowyDraggableHoverPosition.right,
            ].contains(e.position)
                ? Axis.vertical
                : Axis.horizontal;

            final root = panesService.movePaneHandler(
              root: state.root,
              toNode: e.to,
              direction: direction,
              axis: axis,
              fromNode: e.from,
            );

            final firstLeafNode = panesService.findFirstLeaf(node: root);

            emit(
              state.copyWith(
                root: root,
                firstLeafNode: firstLeafNode,
                count: state.count,
              ),
            );
          },
        );
      },
    );
  }
}
