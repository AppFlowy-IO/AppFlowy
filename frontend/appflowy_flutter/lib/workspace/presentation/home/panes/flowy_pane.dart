import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
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
  const FlowyPane({
    super.key,
    required this.node,
    required this.layout,
    required this.delegate,
    required this.paneContext,
    required this.paneLayout,
    required this.allowPaneDrag,
  });

  final PaneNode node;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  final BuildContext paneContext;
  final PaneLayout paneLayout;
  final bool allowPaneDrag;

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
      create: (context) => widget.node.tabsController,
      child: Consumer<TabsController>(
        builder: (_, value, __) {
          double topHeight = value.pages == 1
              ? HomeSizes.topBarHeight
              : HomeSizes.topBarHeight + HomeSizes.tabBarHeight;

          if (value.currentPageManager.readOnly) {
            topHeight += HomeSizes.readOnlyBannerHeight;
          }

          return DraggablePaneTarget(
            size: Size(
              widget.paneLayout.childPaneWidth,
              widget.paneLayout.childPaneHeight,
            ),
            paneContext: widget.paneContext,
            pane: CrossDraggablesEntity(draggable: widget.node),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: CustomScrollView(
                controller: verticalController,
                scrollDirection: Axis.vertical,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyHeaderDelegate(
                      height: topHeight,
                      child: DraggablePaneItem(
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
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _proportionalScroll,
                      child: ScrollConfiguration(
                        behavior:
                            const ScrollBehavior().copyWith(scrollbars: true),
                        child: SingleChildScrollView(
                          controller: horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
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
                            height:
                                widget.paneLayout.homePageHeight - topHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
      child: widget.node.tabsController.currentPageManager.title(),
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
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StickyHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      SizedBox(height: height, child: child);

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}
