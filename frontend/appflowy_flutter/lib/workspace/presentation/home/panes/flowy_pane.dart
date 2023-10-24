import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_item.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_target.dart';
import 'package:appflowy/workspace/presentation/home/panes/panes_layout.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class FlowyPane extends StatefulWidget {
  final PaneNode node;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  final BuildContext paneContext;
  final PaneLayout paneLayout;
  final bool allowPaneDrag;

  const FlowyPane({
    super.key,
    required this.node,
    required this.layout,
    required this.delegate,
    required this.paneContext,
    required this.paneLayout,
    required this.allowPaneDrag,
  });

  @override
  State<FlowyPane> createState() => _FlowyPaneState();
}

class _FlowyPaneState extends State<FlowyPane> {
  final pageController = PageController();

  final horizontalController = ScrollController();

  final verticalController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TabsController>(
      create: (context) => widget.node.tabs,
      child: Consumer<TabsController>(
        builder: (_, value, __) {
          return DraggablePaneTarget(
            size: Size(
              widget.paneLayout.childPaneWidth,
              widget.paneLayout.childPaneHeight,
            ),
            paneContext: widget.paneContext,
            pane: CrossDraggablesEntity(draggable: widget.node),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SingleChildScrollView(
                controller: verticalController,
                scrollDirection: Axis.vertical,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _proportionalScroll,
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(scrollbars: true),
                    child: SingleChildScrollView(
                      controller: horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          DraggablePaneItem(
                            allowPaneDrag: widget.allowPaneDrag,
                            size: Size(
                              widget.paneLayout.childPaneWidth,
                              widget.paneLayout.childPaneHeight,
                            ),
                            paneContext: widget.paneContext,
                            pane: CrossDraggablesEntity(draggable: widget.node),
                            feedback: (context) =>
                                _buildPaneDraggableFeedback(context),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: widget.layout.menuSpacing,
                                  ),
                                  child: TabsManager(
                                    pane: widget.node,
                                    pageController: pageController,
                                    tabs: value,
                                  ),
                                ),
                                value.currentPageManager.stackTopBar(
                                  layout: widget.layout,
                                  paneId: widget.node.paneId,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PageView(
                              physics: const NeverScrollableScrollPhysics(),
                              controller: pageController,
                              children: value.pageManagers
                                  .map(
                                    (pm) => PageStack(
                                      pageManager: pm,
                                      delegate: widget.delegate,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ).constrained(
                        width: widget.paneLayout.homePageWidth,
                        height: widget.paneLayout.homePageHeight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaneDraggableFeedback(BuildContext context) {
    return FlowyContainer(
      Theme.of(context).colorScheme.onSecondaryContainer,
      child: widget.node.tabs.currentPageManager.title(),
    ).padding(all: 4);
  }

  bool _proportionalScroll(ScrollNotification notification) {
    final axis = notification.metrics.axis;

    if (notification is ScrollUpdateNotification && axis == Axis.vertical) {
      final innerScrollPosition = notification.metrics.pixels;
      final innerScrollMax = notification.metrics.maxScrollExtent;
      final outerScrollMax = verticalController.position.maxScrollExtent;

      if (innerScrollMax != 0) {
        final innerScrollPercentage = innerScrollPosition / innerScrollMax;
        final targetOuterScrollPosition =
            outerScrollMax * innerScrollPercentage;

        verticalController.jumpTo(targetOuterScrollPosition);
      }
    }
    return false;
  }

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (widget.node != getIt<PanesCubit>().state.activePane) {
      FocusScope.of(context).unfocus();
    }
    super.didChangeDependencies();
  }
}
