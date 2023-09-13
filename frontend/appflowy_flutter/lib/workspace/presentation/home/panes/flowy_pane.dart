import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_layout.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class FlowyPane extends StatelessWidget {
  final PaneNode node;
  final HomeLayout layout;
  final HomeStackDelegate delegate;
  const FlowyPane({
    super.key,
    required this.node,
    required this.layout,
    required this.delegate,
  });

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();
    return ChangeNotifierProvider<Tabs>(
      create: (context) => node.tabs,
      child: Consumer<Tabs>(
        builder: (context, value, child) {
          final horizontalController = ScrollController();
          final verticalController = ScrollController();
          return BlocBuilder<HomeSettingBloc, HomeSettingState>(
            builder: (context, state) {
              return Scrollbar(
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
                          TabsManager(
                            pane: node,
                            pageController: pageController,
                            tabs: value,
                          ),
                          value.currentPageManager
                              .stackTopBar(layout: layout, paneId: node.paneId),
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
                        width: MediaQuery.of(context).size.width -
                            (state.isMenuCollapsed
                                ? 0
                                : (state.resizeOffset + Sizes.sideBarWidth)),
                        height: MediaQuery.of(context).size.height,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
