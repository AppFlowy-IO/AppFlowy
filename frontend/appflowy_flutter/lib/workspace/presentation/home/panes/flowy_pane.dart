import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_item.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_target.dart';
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
  final Size size;
  final bool allowPaneDrag;

  const FlowyPane({
    super.key,
    required this.node,
    required this.layout,
    required this.delegate,
    required this.paneContext,
    required this.size,
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
        builder: (context, value, __) {
          return DraggablePaneTarget(
            size: widget.size,
            paneContext: widget.paneContext,
            pane: CrossDraggablesEntity(draggable: widget.node),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: true),
              child: SingleChildScrollView(
                controller: verticalController,
                scrollDirection: Axis.vertical,
                child: NotificationListener<ScrollNotification>(
                  onNotification: _proportionalScroll,
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DraggablePaneItem(
                          allowPaneDrag: widget.allowPaneDrag,
                          size: widget.size,
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
                      width: widget.layout.homePageWidth,
                      height: widget.layout.homePageHeight,
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

    if (notification is ScrollEndNotification && axis == Axis.vertical) {
      final pixelsMoved = notification.metrics.pixels;
      final extent = notification.metrics.maxScrollExtent;

      final scrollPercentage = pixelsMoved / extent;

      final outerScrollExtent = scrollPercentage * widget.size.height;

      verticalController.animateTo(
        outerScrollExtent,
        duration: const Duration(milliseconds: 10),
        curve: Curves.easeInOut,
      );
    }
    return false;
  }

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }
}
