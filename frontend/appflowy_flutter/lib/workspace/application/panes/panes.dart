import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PaneNode extends Equatable {
  final List<PaneNode> children;
  final PaneNode? parent;
  final Axis? axis;
  final String paneId;
  final TabsController tabs;

  PaneNode({
    required this.paneId,
    required this.children,
    this.parent,
    this.axis,
    TabsController? tabs,
  }) : tabs = tabs ?? TabsController();

  PaneNode copyWith({
    PaneNode? parent,
    List<PaneNode>? children,
    Axis? axis,
    String? paneId,
    TabsController? tabs,
  }) {
    return PaneNode(
      parent: parent ?? this.parent,
      axis: axis ?? this.axis,
      children: children ?? this.children,
      paneId: paneId ?? this.paneId,
      tabs: tabs ?? this.tabs,
    );
  }

  @override
  List<Object?> get props => [paneId, axis, children, parent, tabs];

  @override
  String toString() {
    return '${(paneId, axis)} =>  Children($children) \n';
  }
}
