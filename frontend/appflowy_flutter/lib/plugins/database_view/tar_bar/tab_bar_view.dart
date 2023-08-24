import 'package:appflowy/plugins/database_view/application/tar_bar_bloc.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/database_controller.dart';
import '../grid/presentation/layout/sizes.dart';
import 'tab_bar_header.dart';

abstract class DatabaseTabBarItemBuilder {
  const DatabaseTabBarItemBuilder();

  /// Returns the content of the tab bar item. The content is shown when the tab
  /// bar item is selected. It can be any kind of database view.
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
  );

  /// Returns the setting bar of the tab bar item. The setting bar is shown on the
  /// top right conner when the tab bar item is selected.
  Widget settingBar(
    BuildContext context,
    DatabaseController controller,
  );

  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  );
}

class DatabaseTabBarView extends StatefulWidget {
  final ViewPB view;
  final bool shrinkWrap;
  const DatabaseTabBarView({
    required this.view,
    required this.shrinkWrap,
    super.key,
  });

  @override
  State<DatabaseTabBarView> createState() => _DatabaseTabBarViewState();
}

class _DatabaseTabBarViewState extends State<DatabaseTabBarView> {
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GridTabBarBloc>(
      create: (context) => GridTabBarBloc(view: widget.view)
        ..add(
          const GridTabBarEvent.initial(),
        ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<GridTabBarBloc, GridTabBarState>(
            listenWhen: (p, c) => p.selectedIndex != c.selectedIndex,
            listener: (context, state) {
              _pageController?.animateToPage(
                state.selectedIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
          ),
        ],
        child: Column(
          children: [
            BlocBuilder<GridTabBarBloc, GridTabBarState>(
              builder: (context, state) {
                return ValueListenableBuilder<bool>(
                  valueListenable: state
                      .tabBarControllerByViewId[state.parentView.id]!
                      .controller
                      .isLoading,
                  builder: (_, value, ___) {
                    if (value) {
                      return const SizedBox.shrink();
                    }
                    return SizedBox(
                      height: 30,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: GridSize.leadingHeaderPadding,
                        ),
                        child: const TabBarHeader(),
                      ),
                    );
                  },
                );
              },
            ),
            BlocBuilder<GridTabBarBloc, GridTabBarState>(
              builder: (context, state) {
                return pageSettingBarExtensionFromState(state);
              },
            ),
            Expanded(
              child: BlocBuilder<GridTabBarBloc, GridTabBarState>(
                builder: (context, state) {
                  return PageView(
                    pageSnapping: false,
                    physics: const NeverScrollableScrollPhysics(),
                    controller: _pageController,
                    children: pageContentFromState(state),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> pageContentFromState(GridTabBarState state) {
    return state.tabBars.map((tabBar) {
      final controller =
          state.tabBarControllerByViewId[tabBar.viewId]!.controller;
      return tabBar.builder.content(
        context,
        tabBar.view,
        controller,
        widget.shrinkWrap,
      );
    }).toList();
  }

  Widget pageSettingBarExtensionFromState(GridTabBarState state) {
    if (state.tabBars.length < state.selectedIndex) {
      return const SizedBox.shrink();
    }
    final tarBar = state.tabBars[state.selectedIndex];
    final controller =
        state.tabBarControllerByViewId[tarBar.viewId]!.controller;
    return tarBar.builder.settingBarExtension(
      context,
      controller,
    );
  }
}

class DatabaseTabBarViewPlugin extends Plugin {
  @override
  final ViewPluginNotifier notifier;
  final PluginType _pluginType;

  DatabaseTabBarViewPlugin({
    required ViewPB view,
    required PluginType pluginType,
  })  : _pluginType = pluginType,
        notifier = ViewPluginNotifier(view: view);

  @override
  PluginWidgetBuilder get widgetBuilder => DatabasePluginWidgetBuilder(
        notifier: notifier,
      );

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get pluginType => _pluginType;
}

class DatabasePluginWidgetBuilder extends PluginWidgetBuilder {
  final ViewPluginNotifier notifier;

  DatabasePluginWidgetBuilder({
    required this.notifier,
    Key? key,
  });

  @override
  Widget get leftBarItem => ViewLeftBarItem(view: notifier.view);

  @override
  Widget tabBarItem(String pluginId) => ViewTabBarItem(view: notifier.view);

  @override
  Widget buildWidget({PluginContext? context, required bool shrinkWrap}) {
    notifier.isDeleted.addListener(() {
      notifier.isDeleted.value.fold(() => null, (deletedView) {
        if (deletedView.hasIndex()) {
          context?.onDeleted(notifier.view, deletedView.index);
        }
      });
    });
    return DatabaseTabBarView(
      key: ValueKey(notifier.view.id),
      view: notifier.view,
      shrinkWrap: shrinkWrap,
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}
