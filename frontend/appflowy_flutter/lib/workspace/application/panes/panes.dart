import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PaneNode extends Equatable {
  final List<PaneNode> children;
  final PaneNode? parent;
  final Axis? axis;
  final String paneId;
  final ViewPB? view;

  const PaneNode({
    required this.paneId,
    required this.children,
    this.parent,
    this.view,
    this.axis,
  });

  PaneNode copyWith({
    PaneNode? parent,
    List<PaneNode>? children,
    Axis? axis,
    String? paneId,
    ViewPB? view,
  }) {
    return PaneNode(
      parent: parent ?? this.parent,
      axis: axis ?? this.axis,
      children: children ?? this.children,
      paneId: paneId ?? this.paneId,
    );
  }

  @override
  List<Object?> get props => [view, paneId, axis, children, parent];

  @override
  String toString() {
    return '${(paneId, axis)} =>  Children($children) \n/n';
  }
}

// find a node that satisfies some condition
PaneNode? depthFirstSearch(
  PaneNode? node,
  bool Function(PaneNode n) predicate,
) {
  if (node == null) {
    return node;
  }
  if (predicate(node)) return node;
  for (var i = 0; i < node.children.length; i++) {
    final n = depthFirstSearch(node.children[i], predicate);
    if (n != null) return n;
  }
  return null;
}
