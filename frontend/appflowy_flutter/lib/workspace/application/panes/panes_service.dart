import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
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
      ///we create a holder node which would replace current target and add
      ///target node + new node as its children
      final newHolderNode = PaneNode(
        paneId: nanoid(),
        children: const [],
        axis: axis,
        tabs: null,
      );
      final oldChildNode = node.copyWith(
        paneId: nanoid(),
        parent: newHolderNode,
        axis: null,
        tabs: TabsController(
          pageManagers: node.tabs.pageManagers,
        ),
      );
      final newChildNode = fromNode?.copyWith(
            parent: newHolderNode,
            paneId: nanoid(),
            children: const [],
            axis: null,
            tabs: TabsController(
              pageManagers: fromNode.tabs.pageManagers,
            ),
          ) ??
          PaneNode(
            paneId: nanoid(),
            children: const [],
            parent: newHolderNode,
            axis: null,
            tabs: TabsController(pageManagers: [PageManager()])
              ..openPlugin(plugin: plugin!),
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
      return ret;
    }

    /// if we haven't found our target node there is a possibility that our
    /// target node is a child of an already existing holder node, we do a quick lookup at children of current node, if we find target in children, we just append a new child at correct location and return
    if (node.axis == axis) {
      for (int i = 0; i < node.children.length; i++) {
        if (node.children[i].paneId == targetPaneId) {
          final newNode = fromNode?.copyWith(
                paneId: nanoid(),
                tabs: TabsController(
                  pageManagers: fromNode.tabs.pageManagers,
                ),
              ) ??
              PaneNode(
                paneId: nanoid(),
                children: const [],
                parent: node.parent,
                tabs: TabsController(pageManagers: [PageManager()])
                  ..openPlugin(plugin: plugin!),
              );
          if (direction == Direction.front) {
            if (i == node.children.length) {
              node.children.add(newNode);
            } else {
              node.children.insert(i + 1, newNode);
            }
          } else {
            node.children.insert(i, newNode);
          }
          final ret = node.copyWith(
            paneId: nanoid(),
            tabs: TabsController(),
            children: node.children
                .map(
                  (e) => e.copyWith(
                    tabs: TabsController(
                      pageManagers: e.tabs.pageManagers,
                    ),
                  ),
                )
                .toList(),
          );
          return ret;
        }
      }
    }

    ///if we couldn't find target in children of current node or if current
    ///node isn't right holder we proceed recursively to dfs remaining
    ///children
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
  }) {
    if (node.paneId == targetPaneId) {
      return node;
    }
    for (var i = 0; i < node.children.length; i++) {
      final element = node.children[i];
      if (element.paneId == targetPaneId) {
        node.children.remove(element..tabs.closeAllViews);
        if (node.children.length == 1) {
          final ret = node.children.first.copyWith(
            paneId: nanoid(),
            parent: node.parent,
            tabs: TabsController(
              pageManagers: node.children.first.tabs.pageManagers,
            ),
          );
          return ret;
        }

        final ret = node.copyWith(
          children: node.children
              .map(
                (e) => e.copyWith(
                  tabs: TabsController(
                    pageManagers: e.tabs.pageManagers,
                  ),
                ),
              )
              .toList(),
          paneId: nanoid(),
        );

        return ret;
      }
    }

    final newChildren = node.children.map((childNode) {
      return closePaneHandler(
        node: childNode,
        targetPaneId: targetPaneId,
      );
    }).toList();

    return node.copyWith(children: newChildren);
  }
}
