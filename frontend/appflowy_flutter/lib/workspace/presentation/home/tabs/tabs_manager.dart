import 'package:appflowy/workspace/application/panes/cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TabsManager extends StatefulWidget {
  final PageController pageController;
  final Tabs tabs;
  final PaneNode pane;
  const TabsManager({
    super.key,
    required this.tabs,
    required this.pageController,
    required this.pane,
  });

  @override
  State<TabsManager> createState() => _TabsManagerState();
}

class _TabsManagerState extends State<TabsManager>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      vsync: this,
      initialIndex: widget.tabs.currentIndex,
      length: widget.tabs.pages,
    );
    widget.tabs.addListener(() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.length == 1) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.bottomLeft,
      height: HomeSizes.tabBarHeigth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),

      /// TODO(Xazin): Custom Reorderable TabBar
      child: TabBar(
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        indicator: BoxDecoration(
          border: Border.all(width: 0, color: Colors.transparent),
        ),
        indicatorWeight: 0,
        dividerColor: Colors.transparent,
        isScrollable: true,
        controller: _controller,
        onTap: (newIndex) => context
            .read<PanesCubit>()
            .selectTab(pane: widget.pane, index: newIndex),
        tabs: widget.tabs.pageManagers
            .map(
              (pm) => FlowyTab(
                paneNode: widget.pane,
                key: UniqueKey(),
                pageManager: pm,
                isCurrent: widget.tabs.currentPageManager == pm,
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.tabs.dispose();
    super.dispose();
  }
}
