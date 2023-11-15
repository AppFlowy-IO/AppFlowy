import 'package:appflowy/workspace/application/panes/pane_node_bloc/pane_node_bloc.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';

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
  const FlowyPaneGroup({
    super.key,
    required this.node,
    required this.paneLayout,
    required this.layout,
    required this.delegate,
    required this.allowPaneDrag,
  });

  final PaneNode node;
  final PaneLayout paneLayout;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  final bool allowPaneDrag;

  @override
  Widget build(BuildContext context) {
    if (node.children.isEmpty) {
      final activePaneGestureRecognizerFactory =
          GestureRecognizerFactoryWithHandlers<AllowMultipleTap>(
        () => AllowMultipleTap(),
        (AllowMultipleTap instance) {
          instance.onTap = () =>
              context.read<PanesBloc>().add(SetActivePane(activePane: node));
        },
      );
      return RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          AllowMultipleTap: activePaneGestureRecognizerFactory,
        },
        child: FlowyPane(
          key: ValueKey(node.paneId + node.tabsController.tabId),
          node: node,
          allowPaneDrag: allowPaneDrag,
          delegate: delegate,
          layout: layout,
          paneContext: context,
          paneLayout: paneLayout,
        ),
      );
    }

    return BlocProvider(
      key: ValueKey(node.paneId + node.tabsController.tabId),
      create: (context) => PaneNodeBloc(
        node.children.length,
        node.axis == Axis.horizontal
            ? paneLayout.childPaneHeight
            : paneLayout.childPaneWidth,
      ),
      child: BlocBuilder<PaneNodeBloc, PaneNodeState>(
        builder: (context, state) {
          return SizedBox(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    ...node.children.indexed.map((indexNode) {
                      final paneLayout = PaneLayout(
                        homeLayout: layout,
                        childPane: indexNode,
                        parentPane: node,
                        flex: state.flex,
                        parentPaneConstraints: constraints,
                      );

                      return Stack(
                        children: [
                          _resolveFlowyPanes(paneLayout, indexNode),
                          _resizeBar(
                            indexNode,
                            context,
                            paneLayout,
                            constraints,
                          ),
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
    BoxConstraints parentConstraints,
  ) {
    if (indexNode.$1 == 0) {
      return const SizedBox.expand();
    }

    return Positioned(
      left: paneLayout.childPaneLPosition,
      top: paneLayout.childPaneTPosition,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          context.read<PaneNodeBloc>().add(
                ResizeUpdate(
                  targetIndex: indexNode.$1,
                  offset: details.delta.dx,
                  availableWidth: parentConstraints.maxWidth,
                ),
              );
        },
        onVerticalDragUpdate: (details) {
          context.read<PaneNodeBloc>().add(
                ResizeUpdate(
                  targetIndex: indexNode.$1,
                  offset: details.delta.dy,
                  availableWidth: parentConstraints.maxHeight,
                ),
              );
        },
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

  Widget _resolveFlowyPanes(PaneLayout paneLayout, (int, PaneNode) indexNode) {
    return Positioned(
      left: paneLayout.childPaneLPosition,
      top: paneLayout.childPaneTPosition,
      child: FlowyPaneGroup(
        node: indexNode.$2,
        paneLayout: paneLayout,
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

class AllowMultipleTap extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) => acceptGesture(pointer);
}
