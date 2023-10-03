import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy_backend/log.dart';
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
        encoding: node.encoding,
      );
      final oldChildEncoding = [direction == Direction.front ? 0 : 1];
      final newChildEncoding = [direction == Direction.front ? 1 : 0];
      final oldChildNode = node.copyWith(
        parent: newHolderNode,
        axis: null,
        tabs: TabsController(
          pageManagers: node.tabs.pageManagers,
          encoding: oldChildEncoding.toString(),
        ),
        encoding: [direction == Direction.front ? 0 : 1],
      );

      final newChildNode = fromNode?.copyWith(
            parent: newHolderNode,
            paneId: nanoid(),
            children: const [],
            axis: null,
            tabs: TabsController(
                pageManagers: fromNode.tabs.pageManagers,
                encoding: newChildEncoding.toString()),
            encoding: newChildEncoding,
          ) ??
          PaneNode(
            paneId: nanoid(),
            children: const [],
            parent: newHolderNode,
            axis: null,
            tabs: TabsController(encoding: newChildEncoding.toString())
              ..openPlugin(plugin: plugin!),
            encoding: newChildEncoding,
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
          final encode = node.encoding.toString() +
              (direction == Direction.front ? "${i + 1}" : "$i");
          final newNode = fromNode?.copyWith(
                paneId: nanoid(),
                parent: node.parent,
                tabs: TabsController(
                  pageManagers: fromNode.tabs.pageManagers,
                  encoding: encode,
                ),
              ) ??
              PaneNode(
                paneId: nanoid(),
                children: const [],
                parent: node.parent,
                tabs: TabsController(encoding: encode)
                  ..openPlugin(plugin: plugin!),
              );
          if (direction == Direction.front) {
            node = node.copyWith(
              children: insertAndEncode(node.children, i + 1, newNode),
            );
          } else {
            node = node.copyWith(
              children: insertAndEncode(node.children, i, newNode),
            );
          }
          final ret = node.copyWith(
            paneId: nanoid(),
            tabs: TabsController(encoding: node.tabs.encoding),
            children: node.children
                .map(
                  (e) => e.copyWith(
                    tabs: TabsController(
                      encoding: e.tabs.encoding,
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
        element.tabs.closeAllViews();
        node = node.copyWith(children: removeAndEncode(node.children, i));
        if (node.children.length == 1) {
          final ret = node.children.first.copyWith(
            paneId: nanoid(),
            parent: node.parent,
            encoding: node.parent == null ? [] : [...node.parent!.encoding, 0],
            tabs: TabsController(
              pageManagers: node.children.first.tabs.pageManagers,
              encoding: "[]",
            ),
          );
          return ret;
        }

        final ret = node.copyWith(
          children: node.children
              .map(
                (e) => e.copyWith(
                  tabs: TabsController(
                    encoding: e.tabs.encoding,
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

List<PaneNode> insertAndEncode(List<PaneNode> list, int index, PaneNode node) {
  if (index <= 0) index = 0;
  if (index >= list.length) index = list.length - 1;

  List<PaneNode> ret = [...list, node];
  for (int i = ret.length - 1; i > index; i--) {
    ret[i] = ret[i - 1].copyWith(
      encoding: node.parent == null ? [i] : [...node.parent!.encoding, i],
    );
  }
  ret[index] = node.copyWith(
    encoding: node.parent == null ? [index] : [...node.parent!.encoding, index],
  );
  return ret;
}

List<PaneNode> removeAndEncode(List<PaneNode> list, int index) {
  List<PaneNode> ret = [];
  for (int i = 0; i < list.length; i++) {
    if (i < index) {
      ret.add(list[i]);
    }
    if (i > index) {
      ret.add(
        list[i].copyWith(
          encoding: list[i].parent == null
              ? [i - 1]
              : [...list[i].parent!.encoding, i - 1],
        ),
      );
    }
  }
  return ret;
}
