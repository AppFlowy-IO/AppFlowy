import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

enum Direction { front, back }

class PanesService {
  PaneNode splitHandler({
    required PaneNode node,
    required String targetPaneId,
    required Direction direction,
    required Axis axis,
    PaneNode? fromNode,
    Plugin? plugin,
  }) {
    /// This is a recursive handler, following condition checks if passed node
    /// is our target node
    if (node.paneId == targetPaneId) {
      /// We create a holder node which would replace current target and add
      /// target node + new node as its children
      final newHolderNode = PaneNode(
        paneId: nanoid(),
        children: const [],
        axis: axis,
        tabsController: null,
      );

      final oldChildNode = node.copyWith(
        paneId: nanoid(),
        parent: newHolderNode,
        axis: null,
        children: const [],
      );

      final newChildNode = fromNode?.copyWith(
            paneId: nanoid(),
            parent: newHolderNode,
            axis: null,
            children: const [],
          ) ??
          PaneNode(
            paneId: nanoid(),
            children: const [],
            parent: newHolderNode,
            tabsController: TabsController()..openPlugin(plugin: plugin!),
          );

      final ret = newHolderNode.copyWith(
        children: direction == Direction.front
            ? [
                oldChildNode,
                newChildNode,
              ]
            : [
                newChildNode,
                oldChildNode,
              ],
      );

      return ret.copyWith(
        children: ret.children.map((e) => e.copyWith(parent: ret)).toList(),
      );
    }

    /// If we haven't found our target node there is a possibility that our
    /// target node is a child of an already existing holder node, we do a
    /// quick lookup at children of current node, if we find target in
    /// children, we just append a new child at correct location and return
    if (node.axis == axis) {
      for (int i = 0; i < node.children.length; i++) {
        if (node.children[i].paneId == targetPaneId) {
          final newNode = fromNode?.copyWith(paneId: nanoid(), parent: node) ??
              PaneNode(
                paneId: nanoid(),
                children: const [],
                parent: node,
                tabsController: TabsController()..openPlugin(plugin: plugin!),
              );

          final list = [...node.children];

          if (direction == Direction.front) {
            if (i == node.children.length) {
              list.add(newNode);
            } else {
              list.insert(i + 1, newNode);
            }
          } else {
            list.insert(i, newNode);
          }

          /// copyWith is called to assign new paneId and children with updated/
          /// reconstructed tabscontroller to trigger build of consecutive
          /// widget else it won't reflect on ui.
          final parent = node.copyWith(
            paneId: nanoid(),
            children: list.map((e) => e.copyWith()).toList(),
          );

          return parent.copyWith(
            children: list.map((e) => e.copyWith(parent: parent)).toList(),
          );
        }
      }
    }

    /// If we couldn't find target in children of current node or if current
    /// node isn't right holder we proceed recursively to dfs remaining
    /// children
    final newChildren = node.children
        .map(
          (childNode) => splitHandler(
            node: childNode,
            targetPaneId: targetPaneId,
            plugin: plugin,
            direction: direction,
            axis: axis,
            fromNode: fromNode,
          ),
        )
        .toList();

    return node.copyWith(children: newChildren);
  }

  PaneNode closePaneHandler({
    required PaneNode node,
    required String targetPaneId,
    required bool closingToMove,
  }) {
    if (node.paneId == targetPaneId) {
      return node;
    }

    for (var i = 0; i < node.children.length; i++) {
      final element = node.children[i];
      if (element.paneId == targetPaneId) {
        if (!closingToMove) {
          element.tabsController.closeAllViews();
        }

        node.children.remove(element);
        final list = List<PaneNode>.from(node.children)..remove(element);

        if (node.children.length == 1) {
          return node.children.first.copyWith(
            paneId: closingToMove ? node.children.first.paneId : nanoid(),
            parent: node.parent,
          );
        }

        final parent = node.copyWith(
          paneId: closingToMove ? node.paneId : nanoid(),
          children: list.map((e) => e.copyWith()).toList(),
        );

        return parent.copyWith(
          children: list.map((e) => e.copyWith(parent: parent)).toList(),
        );
      }
    }

    final newChildren = node.children
        .map(
          (childNode) => closePaneHandler(
            node: childNode,
            targetPaneId: targetPaneId,
            closingToMove: closingToMove,
          ),
        )
        .toList();

    return node.copyWith(
      paneId: closingToMove ? node.paneId : nanoid(),
      children: newChildren,
    );
  }

  PaneNode movePaneHandler({
    required PaneNode root,
    required Direction direction,
    required Axis axis,
    required PaneNode fromNode,
    required PaneNode toNode,
  }) {
    final response = splitHandler(
      node: closePaneHandler(
        node: root,
        targetPaneId: fromNode.paneId,
        closingToMove: true,
      ),
      targetPaneId: toNode.paneId,
      direction: direction,
      axis: axis,
      fromNode: fromNode,
    );

    return response.copyWith(paneId: nanoid());
  }

  PaneNode findFirstLeaf({required PaneNode node}) =>
      node.children.isEmpty ? node : findFirstLeaf(node: node.children[0]);
}
