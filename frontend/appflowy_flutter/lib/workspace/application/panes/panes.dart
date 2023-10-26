import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

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
      tabs: tabs != null
          ? TabsController.reconstruct(tabs)
          : TabsController.reconstruct(this.tabs),
    );
  }

  factory PaneNode.initial() {
    return PaneNode(
      tabs: TabsController(),
      children: const [],
      paneId: nanoid(),
      axis: null,
    );
  }
  @override
  List<Object?> get props => [paneId, axis, children, parent, tabs];
}
