import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

class PaneNode extends Equatable {
  final List<PaneNode> children;
  final PaneNode? parent;
  final Axis? axis;
  final String paneId;
  final TabsController tabsController;

  PaneNode({
    required this.paneId,
    required this.children,
    this.parent,
    this.axis,
    TabsController? tabsController,
  }) : tabsController = tabsController ?? TabsController();

  PaneNode copyWith({
    PaneNode? parent,
    List<PaneNode>? children,
    Axis? axis,
    String? paneId,
    TabsController? tabsController,
  }) {
    return PaneNode(
      parent: parent ?? this.parent,
      axis: axis ?? this.axis,
      children: children ?? this.children,
      paneId: paneId ?? this.paneId,
      tabsController: tabsController != null
          ? TabsController.reconstruct(tabsController)
          : TabsController.reconstruct(this.tabsController),
    );
  }

  factory PaneNode.initial() {
    return PaneNode(
      tabsController: TabsController(),
      children: const [],
      paneId: nanoid(),
      axis: null,
    );
  }
  @override
  List<Object?> get props => [paneId, axis, children, parent, tabsController];
}
