import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_draggables.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/panes/draggable_pane_item.dart';
import 'package:appflowy/workspace/presentation/home/tabs/draggable_tab_item.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class FlowyPane extends StatelessWidget {
  final PaneNode node;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  final BuildContext paneContext;
  FlowyPane({
    super.key,
    required this.node,
    required this.layout,
    required this.delegate,
    required this.paneContext,
  });
  final pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final allowDrag = context.read<PanesCubit>().state.allowPaneDrag;
    return ChangeNotifierProvider<Tabs>(
      create: (context) => node.tabs,
      child: Consumer<Tabs>(
        builder: (context, value, child) {
          final horizontalController = ScrollController();
          final verticalController = ScrollController();
          return DraggablePaneItem(
            allowDrag: allowDrag,
            paneContext: paneContext,
            pane: CrossDraggablesEntity(draggable: node),
            feedback: (context) => node.tabs.currentPageManager.title(),
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
                        Padding(
                          padding: EdgeInsets.only(
                            left: layout.menuSpacing,
                          ),
                          child: TabsManager(
                            allowPaneDrag: allowDrag,
                            pane: node,
                            pageController: pageController,
                            tabs: value,
                          ),
                        ),
                        allowDrag
                            ? value.currentPageManager.stackTopBar(
                                layout: layout,
                                paneId: node.paneId,
                              )
                            : DraggableTabItem(
                                pageManager: value.currentPageManager,
                                tabContext: context,
                                tabs: value,
                                feedback: (context) => FlowyTab(
                                  paneNode: node,
                                  key: UniqueKey(),
                                  pageManager: value.currentPageManager,
                                  isCurrent: true,
                                ),
                                child: value.currentPageManager.stackTopBar(
                                  layout: layout,
                                  paneId: node.paneId,
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
                                    delegate: delegate,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ).constrained(
                      width: layout.homePageWidth,
                      height: layout.homePageHeight,
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
}
