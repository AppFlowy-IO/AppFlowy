import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/tar_bar_bloc.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/database_controller.dart';
import '../grid/presentation/layout/sizes.dart';
import 'tar_bar_add_button.dart';

abstract class DatabaseTabBarItemBuilder {
  const DatabaseTabBarItemBuilder();

  /// Returns the content of the tab bar item. The content is shown when the tab
  /// bar item is selected. It can be any kind of database view.
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
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
  const DatabaseTabBarView({
    required this.view,
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
            Row(
              children: [
                BlocBuilder<GridTabBarBloc, GridTabBarState>(
                  builder: (context, state) {
                    return const Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(left: 50),
                        child: DatabaseTabBar(),
                      ),
                    );
                  },
                ),
                BlocBuilder<GridTabBarBloc, GridTabBarState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: 300,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 50),
                        child: pageSettingBarFromState(state),
                      ),
                    );
                  },
                ),
              ],
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
      );
    }).toList();
  }

  Widget pageSettingBarFromState(GridTabBarState state) {
    if (state.tabBars.length < state.selectedIndex) {
      return const SizedBox.shrink();
    }
    final tarBar = state.tabBars[state.selectedIndex];
    final controller =
        state.tabBarControllerByViewId[tarBar.viewId]!.controller;
    return tarBar.builder.settingBar(
      context,
      controller,
    );
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
  Widget buildWidget({PluginContext? context}) {
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
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];
}

class DatabaseTabBar extends StatefulWidget {
  const DatabaseTabBar({super.key});

  @override
  State<DatabaseTabBar> createState() => _DatabaseTabBarState();
}

class _DatabaseTabBarState extends State<DatabaseTabBar> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridTabBarBloc, GridTabBarState>(
      builder: (context, state) {
        final children = state.tabBars.indexed.map((indexed) {
          final isSelected = state.selectedIndex == indexed.$1;
          final tabBar = indexed.$2;
          return DatabaseTabBarItem(
            key: ValueKey(tabBar.viewId),
            view: tabBar.view,
            isSelected: isSelected,
            onTap: (selectedView) {
              context.read<GridTabBarBloc>().add(
                    GridTabBarEvent.selectView(selectedView.id),
                  );
            },
          );
        }).toList();

        return Row(
          children: [
            Flexible(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: IntrinsicWidth(
                  child: Row(children: children),
                ),
              ),
            ),
            AddDatabaseViewButton(
              onTap: (action) async {
                context.read<GridTabBarBloc>().add(
                      GridTabBarEvent.createView(action),
                    );
              },
            ),
          ],
        );
      },
    );
  }
}

class DatabaseTabBarItem extends StatelessWidget {
  final bool isSelected;
  final ViewPB view;
  final Function(ViewPB) onTap;
  const DatabaseTabBarItem({
    required this.view,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 160),
      child: IntrinsicWidth(
        child: Column(
          children: [
            TabBarItemButton(
              view: view,
              onTap: () => onTap(view),
            ),
            if (isSelected)
              Divider(
                height: 1,
                thickness: 2,
                color: Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

class TabBarItemButton extends StatelessWidget {
  final ViewPB view;
  final VoidCallback onTap;
  const TabBarItemButton({
    required this.view,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<TabBarViewAction>(
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: TabBarViewAction.values,
      buildChild: (controller) {
        return FlowyButton(
          radius: Corners.s5Border,
          hoverColor: AFThemeExtension.of(context).greyHover,
          onTap: onTap,
          onSecondaryTap: () {
            controller.show();
          },
          text: FlowyText.medium(
            view.name,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          margin: GridSize.cellContentInsets,
          leftIcon: svgWidget(
            view.iconName,
            color: Theme.of(context).iconTheme.color,
          ),
        );
      },
      onSelected: (action, controller) {
        switch (action) {
          case TabBarViewAction.rename:
            NavigatorTextFieldDialog(
              title: LocaleKeys.menuAppHeader_renameDialog.tr(),
              value: view.name,
              confirm: (newValue) {
                context.read<GridTabBarBloc>().add(
                      GridTabBarEvent.renameView(view.id, newValue),
                    );
              },
            ).show(context);
            break;
          case TabBarViewAction.delete:
            NavigatorAlertDialog(
              title: LocaleKeys.grid_deleteView.tr(),
              confirm: () {
                context.read<GridTabBarBloc>().add(
                      GridTabBarEvent.deleteView(view.id),
                    );
              },
            ).show(context);

            break;
        }
        controller.close();
      },
    );
  }
}

enum TabBarViewAction implements ActionCell {
  rename,
  delete;

  @override
  String get name {
    switch (this) {
      case TabBarViewAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case TabBarViewAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
    }
  }

  Widget icon(Color iconColor) {
    switch (this) {
      case TabBarViewAction.rename:
        return const FlowySvg(name: 'editor/edit');
      case TabBarViewAction.delete:
        return const FlowySvg(name: 'editor/delete');
    }
  }

  @override
  Widget? leftIcon(Color iconColor) => icon(iconColor);

  @override
  Widget? rightIcon(Color iconColor) => null;
}
