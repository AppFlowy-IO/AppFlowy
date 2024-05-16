import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/tabs/flowy_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TabsManager extends StatefulWidget {
  const TabsManager({super.key, required this.pageController});

  final PageController pageController;

  @override
  State<TabsManager> createState() => _TabsManagerState();
}

class _TabsManagerState extends State<TabsManager>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(vsync: this, length: 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TabsBloc>.value(
      value: BlocProvider.of<TabsBloc>(context),
      child: BlocListener<TabsBloc, TabsState>(
        listener: (context, state) {
          if (_controller.length != state.pages) {
            _controller.dispose();
            _controller = TabController(
              vsync: this,
              initialIndex: state.currentIndex,
              length: state.pages,
            );
          }

          if (state.currentIndex != widget.pageController.page) {
            // Unfocus editor to hide selection toolbar
            FocusScope.of(context).unfocus();

            widget.pageController.animateToPage(
              state.currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: BlocBuilder<TabsBloc, TabsState>(
          builder: (context, state) {
            if (_controller.length == 1) {
              return const SizedBox.shrink();
            }

            return Container(
              alignment: Alignment.bottomLeft,
              height: HomeSizes.tabBarHeight,
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
                onTap: (newIndex) =>
                    context.read<TabsBloc>().add(TabsEvent.selectTab(newIndex)),
                tabs: state.pageManagers
                    .map(
                      (pm) => FlowyTab(
                        key: UniqueKey(),
                        pageManager: pm,
                        isCurrent: state.currentPageManager == pm,
                      ),
                    )
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
