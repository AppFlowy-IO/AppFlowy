import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

enum Direction { front, back }

class PanesService {
  PaneNode splitHandler(
    PaneNode node,
    String targetPaneId,
    Plugin? plugin,
    Direction direction,
    Axis axis,
    void Function(PaneNode) activePane,
    PaneNode? fromNode,
  ) {
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
        tabs: Tabs(
          currentIndex: node.tabs.currentIndex,
          pageManagers: node.tabs.pageManagers,
        ),
      );
      final newChildNode = fromNode?.copyWith(
            parent: newHolderNode,
            paneId: nanoid(),
            children: const [],
            axis: null,
            tabs: Tabs(
              currentIndex: fromNode.tabs.currentIndex,
              pageManagers: fromNode.tabs.pageManagers,
            ),
          ) ??
          PaneNode(
            paneId: nanoid(),
            children: const [],
            parent: newHolderNode,
            axis: null,
            tabs: Tabs(
              pageManagers: [PageManager()..setPlugin(plugin!)],
            ),
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
      activePane(ret.children[0]);
      return ret;
    }

    /// if we haven't found our target node there is a possibility that our
    /// target node is a child of an already existing holder node, we do a quick lookup at children of current node, if we find target in children, we just append a new child at correct location and return
    if (node.axis == axis) {
      for (int i = 0; i < node.children.length; i++) {
        if (node.children[i].paneId == targetPaneId) {
          final newNode = fromNode?.copyWith(
                paneId: nanoid(),
                tabs: Tabs(
                  currentIndex: fromNode.tabs.currentIndex,
                  pageManagers: fromNode.tabs.pageManagers,
                ),
              ) ??
              PaneNode(
                paneId: nanoid(),
                children: const [],
                parent: node.parent,
                tabs: Tabs(
                  pageManagers: [PageManager()..setPlugin(plugin!)],
                ),
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
            tabs: Tabs(),
            children: node.children
                .map(
                  (e) => e.copyWith(
                    tabs: Tabs(
                      currentIndex: e.tabs.currentIndex,
                      pageManagers: e.tabs.pageManagers,
                    ),
                  ),
                )
                .toList(),
          );
          activePane(ret.children[i]);
          return ret;
        }
      }
    }

    ///if we couldn't find target in children of current node or if current
    ///node isn't right holder we proceed recursively to dfs remaining
    ///children
    final newChildren = node.children
        .map(
          (e) => splitHandler(
            e,
            targetPaneId,
            plugin,
            direction,
            axis,
            activePane,
            fromNode,
          ),
        )
        .toList();
    return node.copyWith(children: newChildren);
  }

  PaneNode closePaneHandler(
    PaneNode node,
    String targetPaneId,
    Function(PaneNode) setActiveNode,
  ) {
    if (node.paneId == targetPaneId) {
      return node;
    }
    for (final element in node.children) {
      if (element.paneId == targetPaneId) {
        node.children.remove(element);
        setActiveNode(node);
        if (node.children.length == 1) {
          setActiveNode(node.children.first);
          return node.children.first.copyWith(
            paneId: nanoid(),
            parent: node.parent,
            tabs: Tabs(
              currentIndex: node.children.first.tabs.currentIndex,
              pageManagers: node.children.first.tabs.pageManagers,
            ),
          );
        }
        return node.copyWith(
          paneId: nanoid(),
          tabs: Tabs(
            currentIndex: node.tabs.currentIndex,
            pageManagers: node.tabs.pageManagers,
          ),
        );
      }
    }

    final newChildren = node.children.map((e) {
      return closePaneHandler(
        e,
        targetPaneId,
        setActiveNode,
      );
    }).toList();

    return node.copyWith(children: newChildren);
  }

  int countNodeHandler(PaneNode root) {
    if (root.children.isEmpty) {
      return 1;
    }
    int totalCount = 1;
    for (final child in root.children) {
      totalCount += countNodeHandler(child);
    }

    return totalCount;
  }
}
