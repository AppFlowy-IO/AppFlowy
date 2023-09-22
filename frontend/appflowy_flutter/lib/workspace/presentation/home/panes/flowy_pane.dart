import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_item.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_target.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class FlowyPane extends StatefulWidget {
  final PaneNode node;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  final BuildContext paneContext;
  final Size size;
  const FlowyPane({
    super.key,
    required this.node,
    required this.layout,
    required this.delegate,
    required this.paneContext,
    required this.size,
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
        builder: (context, value, child) {
          return DraggablePaneTarget(
            size: widget.size,
            paneContext: widget.paneContext,
            pane: CrossDraggablesEntity(draggable: widget.node),
            child: Scrollbar(
              controller: verticalController,
              child: SingleChildScrollView(
                controller: verticalController,
                child: Scrollbar(
                  controller: horizontalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DraggablePaneItem(
                          size: widget.size,
                          paneContext: widget.paneContext,
                          pane: CrossDraggablesEntity(draggable: widget.node),
                          feedback: (context) =>
                              widget.node.tabs.currentPageManager.title(),
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

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }
}
