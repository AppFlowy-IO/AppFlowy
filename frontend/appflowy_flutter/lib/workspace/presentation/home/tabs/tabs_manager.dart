import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/tabs/draggable_tab_item.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class TabsManager extends StatefulWidget {
  const TabsManager({
    super.key,
    required this.tabs,
    required this.pageController,
    required this.pane,
  });

  final TabsController tabs;
  final PageController pageController;
  final PaneNode pane;

  @override
  State<TabsManager> createState() => _TabsManagerState();
}

class _TabsManagerState extends State<TabsManager> with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      vsync: this,
      initialIndex: widget.tabs.currentIndex,
      length: widget.tabs.pages,
    );
    widget.tabs.addListener(navigateToPage);
  }

  void navigateToPage() {
    if (_controller.length != widget.tabs.pages) {
      _controller.dispose();
      _controller = TabController(
        vsync: this,
        initialIndex: widget.tabs.currentIndex,
        length: widget.tabs.pages,
      );
    }

    if (widget.tabs.currentIndex != widget.pageController.page) {
      // Unfocus editor to hide selection toolbar
      FocusScope.of(context).unfocus();

      widget.pageController.animateToPage(
        widget.tabs.currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.length == 1) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.bottomLeft,
      height: HomeSizes.tabBarHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: TabBar(
        dragStartBehavior: DragStartBehavior.down,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          border: Border.all(width: 0, color: Colors.transparent),
        ),
        indicatorWeight: 0,
        dividerColor: Colors.transparent,
        isScrollable: true,
        controller: _controller,
        onTap: (newIndex) => context.read<PanesBloc>().add(
              SelectTab(pane: widget.pane, index: newIndex),
            ),
        tabs: widget.tabs.pageManagers
            .map(
              (pm) => SizedBox(
                width: HomeSizes.tabWidth,
                key: ValueKey(pm.plugin.id),
                child: DraggableTabItem(
                  tabs: widget.tabs,
                  pageManager: pm,
                  child: FlowyTab(
                    paneNode: widget.pane,
                    pageManager: pm,
                    isCurrent: widget.tabs.currentPageManager == pm,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.tabs.removeListener(navigateToPage);
    super.dispose();
  }
}
