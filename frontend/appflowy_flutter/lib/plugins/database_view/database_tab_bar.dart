import 'package:appflowy/plugins/database_view/application/tar_bar_bloc.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/left_bar_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/database_controller.dart';
import 'database_setting_menu.dart';
import 'grid/presentation/layout/sizes.dart';

abstract class DatabaseTabBarItemBuilder {
  const DatabaseTabBarItemBuilder();

  Widget render(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
  );

  Widget renderMenu(
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
  }

  @override
  Widget build(BuildContext context) {
    // DatabaseViewSettingMenu
    return BlocProvider<GridTabBarBloc>(
      create: (context) => GridTabBarBloc(view: widget.view)
        ..add(
          const GridTabBarEvent.initial(),
        ),
      child: MultiBlocListener(
        listeners: [
          BlocListener<GridTabBarBloc, GridTabBarState>(
            listenWhen: (p, c) => p.selectedTabBarView != c.selectedTabBarView,
            listener: (context, state) {
              _pageController?.animateToPage(
                state.selectedViewIndex,
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
                      child: DatabaseTabBar(),
                    );
                  },
                ),
                BlocBuilder<GridTabBarBloc, GridTabBarState>(
                  buildWhen: (p, c) =>
                      p.selectedTabBarView.view.id !=
                      c.selectedTabBarView.view.id,
                  builder: (context, state) {
                    return SizedBox(
                      width: 300,
                      child:
                          state.selectedTabBarView.view.tarBarItem().renderMenu(
                                context,
                                state.selectedTabBarView.controller,
                              ),
                    );
                  },
                ),
              ],
            ),
            BlocBuilder<GridTabBarBloc, GridTabBarState>(
              builder: (context, state) {
                return DatabaseViewSettingBar(
                  viewId: widget.view.id,
                  databaseController: state.selectedTabBarView.controller,
                );
              },
            ),
            Expanded(
              child: BlocBuilder<GridTabBarBloc, GridTabBarState>(
                builder: (context, state) {
                  return PageView(
                    controller: _pageController,
                    children: state.tabBarViews.map((view) {
                      return view.view.tarBarItem().render(
                            context,
                            view.view,
                            view.controller,
                          );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
    bool listenOnViewChanged = false,
  })  : _pluginType = pluginType,
        notifier = ViewPluginNotifier(
          view: view,
          listenOnViewChanged: listenOnViewChanged,
        );

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

class DatabaseTabBar extends StatelessWidget {
  const DatabaseTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridTabBarBloc, GridTabBarState>(
      builder: (context, state) {
        final children = state.tabBarViews.map((tabBarView) {
          return DatabaseTabBarItem(
            view: tabBarView.view,
            isSelected: false,
            onTap: (selectedView) {},
          );
        }).toList();

        return Row(
          children: [
            ...children,
            AddDatabaseViewButton(
              onTap: () {},
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
            FlowyButton(
              radius: Corners.s5Border,
              hoverColor: AFThemeExtension.of(context).greyHover,
              onTap: () => onTap(view),
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
            ),
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

class AddDatabaseViewButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddDatabaseViewButton({
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      iconPadding: const EdgeInsets.all(4),
      hoverColor: AFThemeExtension.of(context).greyHover,
      onPressed: onTap,
      icon: svgWidget(
        'home/add',
        color: Theme.of(context).colorScheme.tertiary,
      ),
    );
  }
}
