import 'package:appflowy/workspace/application/panes/pane_node_cubit/cubit/pane_node_cubit.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/panes/panes_layout.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'flowy_pane.dart';

class FlowyPaneGroup extends StatelessWidget {
  final PaneNode node;
  final double groupWidth;
  final double groupHeight;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  final bool allowPaneDrag;

  const FlowyPaneGroup({
    super.key,
    required this.node,
    required this.groupWidth,
    required this.groupHeight,
    required this.layout,
    required this.delegate,
    required this.allowPaneDrag,
  });

  @override
  Widget build(BuildContext context) {
    if (node.children.isEmpty) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => context.read<PanesCubit>().setActivePane(node),
        child: FlowyPane(
          key: ValueKey(node.tabs.tabId),
          node: node,
          allowPaneDrag: allowPaneDrag,
          delegate: delegate,
          layout: layout,
          paneContext: context,
          size: Size(groupWidth, groupHeight),
        ),
      );
    }

    return BlocProvider(
      key: ValueKey(node.paneId),
      create: (context) => PaneNodeCubit(
        node.children.length,
        node.axis == Axis.horizontal ? groupHeight : groupWidth,
      ),
      child: BlocBuilder<PaneNodeCubit, PaneNodeState>(
        builder: (context, state) {
          return SizedBox(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    ...node.children.indexed.map((indexNode) {
                      final paneLayout = PaneLayout(
                        childPane: indexNode,
                        parentPane: node,
                        flex: state.flex,
                        parentPaneConstraints: constraints,
                      );
                      return Stack(
                        children: [
                          _resolveFlowyPanes(
                            paneLayout,
                            indexNode,
                            state.resizeOffset[indexNode.$1],
                          ),
                          _resizeBar(indexNode, context, paneLayout),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _resizeBar(
    (int, PaneNode) indexNode,
    BuildContext context,
    PaneLayout paneLayout,
  ) {
    if (indexNode.$1 == 0) {
      return const SizedBox.expand();
    }
    return Positioned(
      left: paneLayout.childPaneLPosition,
      top: paneLayout.childPaneTPosition,
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragUpdate: (details) {
          context
              .read<PaneNodeCubit>()
              .paneResized(indexNode.$1, details.delta.dx, groupWidth);
        },
        onVerticalDragUpdate: (details) {
          context
              .read<PaneNodeCubit>()
              .paneResized(indexNode.$1, details.delta.dy, groupHeight);
        },
        onHorizontalDragStart: (_) =>
            context.read<PaneNodeCubit>().resizeStart(),
        onVerticalDragStart: (_) => context.read<PaneNodeCubit>().resizeStart(),
        behavior: HitTestBehavior.translucent,
        child: FlowyHover(
          style: HoverStyle(
            backgroundColor: Theme.of(context).dividerColor,
            hoverColor: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.zero,
          ),
          cursor: paneLayout.resizeCursorType,
          child: SizedBox(
            width: paneLayout.resizerWidth,
            height: paneLayout.resizerHeight,
          ),
        ),
      ),
    );
  }

  Widget _resolveFlowyPanes(
    PaneLayout paneLayout,
    (int, PaneNode) indexNode,
    double position,
  ) {
    return Positioned(
      left: paneLayout.childPaneLPosition,
      top: paneLayout.childPaneTPosition,
      child: FlowyPaneGroup(
        node: indexNode.$2,
        groupWidth: paneLayout.childPaneWidth,
        groupHeight: paneLayout.childPaneHeight,
        delegate: delegate,
        layout: layout,
        allowPaneDrag: allowPaneDrag,
      ).constrained(
        width: paneLayout.childPaneWidth,
        height: paneLayout.childPaneHeight,
      ),
    );
  }
}
