import 'package:appflowy/workspace/application/panes/size_cubit/cubit/size_controller.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PaneNode extends Equatable {
  final List<PaneNode> children;
  final PaneNode? parent;
  final Axis? axis;
  final String paneId;
  final Tabs tabs;
  final PaneSizeController sizeController;

  PaneNode({
    required this.paneId,
    required this.children,
    PaneSizeController? sizeController,
    this.parent,
    this.axis,
    Tabs? tabs,
  })  : sizeController = sizeController ??
            PaneSizeController(
              axis: axis,
              flex: [],
            ),
        tabs = tabs ?? Tabs();

  PaneNode copyWith({
    PaneNode? parent,
    List<PaneNode>? children,
    PaneSizeController? sizeController,
    Axis? axis,
    String? paneId,
    Tabs? tabs,
  }) {
    return PaneNode(
      parent: parent ?? this.parent,
      sizeController: sizeController ?? this.sizeController,
      axis: axis ?? this.axis,
      children: children ?? this.children,
      paneId: paneId ?? this.paneId,
      tabs: tabs ?? this.tabs,
    );
  }

  @override
  List<Object?> get props =>
      [paneId, axis, children, parent, tabs, sizeController];

  @override
  String toString() {
    return '${(paneId, axis)} =>  Children($children) \n';
  }
}

/// find a node that satisfies some condition
PaneNode? depthFirstSearch(
  PaneNode? node,
  bool Function(PaneNode n) predicate,
) {
  if (node == null) {
    return node;
  }
  if (predicate(node)) return node;
  for (int i = 0; i < node.children.length; i++) {
    final n = depthFirstSearch(node.children[i], predicate);
    if (n != null) return n;
  }

  return null;
}
