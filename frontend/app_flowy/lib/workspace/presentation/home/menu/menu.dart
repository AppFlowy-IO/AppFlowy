export './app/header/header.dart';
export './app/menu_app.dart';

import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/plugins/trash/menu.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

import 'app/menu_app.dart';
import 'app/create_button.dart';
import 'menu_user.dart';

class HomeMenu extends StatefulWidget {
  final PublishNotifier<bool> _collapsedNotifier;
  final UserProfile user;
  final CurrentWorkspaceSetting workspaceSetting;

  const HomeMenu({
    Key? key,
    required this.user,
    required this.workspaceSetting,
    required PublishNotifier<bool> collapsedNotifier,
  })  : _collapsedNotifier = collapsedNotifier,
        super(key: key);

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  /// Maps the hashmap of the menu items to their index in reorderable list view.
  //TODO @gaganyadav80: Retain this map to persist on app restarts.
  final Map<int, int> _menuItemIndex = <int, int>{};

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuBloc>(
          create: (context) {
            final menuBloc = getIt<MenuBloc>(param1: widget.user, param2: widget.workspaceSetting.workspace.id);
            menuBloc.add(const MenuEvent.initial());
            return menuBloc;
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.plugin.pluginId != c.plugin.pluginId,
            listener: (context, state) {
              getIt<HomeStackManager>().setPlugin(state.plugin);
            },
          ),
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.isCollapse != c.isCollapse,
            listener: (context, state) {
              widget._collapsedNotifier.value = state.isCollapse;
            },
          )
        ],
        child: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) => _renderBody(context),
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    // nested column: https://siddharthmolleti.com/flutter-box-constraints-nested-column-s-row-s-3dfacada7361
    final theme = context.watch<AppTheme>();
    return Container(
      color: theme.bg1,
      child: ChangeNotifierProvider(
        create: (_) =>
            MenuSharedState(view: widget.workspaceSetting.hasLatestView() ? widget.workspaceSetting.latestView : null),
        child: Consumer(builder: (context, MenuSharedState sharedState, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const MenuTopBar(),
                    const VSpace(10),
                    _renderApps(context),
                  ],
                ).padding(horizontal: Insets.l),
              ),
              const VSpace(20),
              _renderTrash(context).padding(horizontal: Insets.l),
              const VSpace(20),
              _renderNewAppButton(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _renderApps(BuildContext context) {
    return ExpandableTheme(
      data: ExpandableThemeData(useInkWell: true, animationDuration: Durations.medium),
      child: Expanded(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: BlocSelector<MenuBloc, MenuState, List<Widget>>(
            selector: (state) {
              List<Widget> menuItems = [];
              // menuItems.add(MenuUser(user));
              List<MenuApp> appWidgets =
                  state.apps.foldRight([], (apps, _) => apps.map((app) => MenuApp(app)).toList());
              // menuItems.addAll(appWidgets);
              for (int i = 0; i < appWidgets.length; i++) {
                if (_menuItemIndex[appWidgets[i].key.hashCode] == null) {
                  _menuItemIndex[appWidgets[i].key.hashCode] = i;
                }

                menuItems.insert(_menuItemIndex[appWidgets[i].key.hashCode]!, appWidgets[i]);
              }

              return menuItems;
            },
            builder: (context, menuItems) {
              return ReorderableListView.builder(
                itemCount: menuItems.length,
                buildDefaultDragHandles: false,
                header: Padding(
                  padding: EdgeInsets.only(bottom: 20.0 - MenuAppSizes.appVPadding),
                  child: MenuUser(widget.user),
                ),
                onReorder: (oldIndex, newIndex) {
                  int index = newIndex > oldIndex ? newIndex - 1 : newIndex;

                  Widget menu = menuItems.removeAt(oldIndex);
                  menuItems.insert(index, menu);

                  final menuBloc = context.read<MenuBloc>();
                  menuBloc.state.apps.forEach((a) {
                    var app = a.removeAt(oldIndex);
                    a.insert(index, app);
                  });

                  _menuItemIndex[menu.key.hashCode] = index;
                },
                physics: StyledScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  //? @gaganyadav80: To mimic the ListView.separated behavior, we need to add a padding.
                  // EdgeInsets padding = EdgeInsets.zero;
                  // if (index == 0) {
                  //   padding = EdgeInsets.only(bottom: MenuAppSizes.appVPadding / 2);
                  // } else if (index == menuItems.length - 1) {
                  //   padding = EdgeInsets.only(top: MenuAppSizes.appVPadding / 2);
                  // } else {
                  //   padding = EdgeInsets.symmetric(vertical: MenuAppSizes.appVPadding / 2);
                  // }

                  return ReorderableDragStartListener(
                    key: ValueKey(menuItems[index].hashCode),
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: MenuAppSizes.appVPadding / 2),
                      child: menuItems[index],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _renderTrash(BuildContext context) {
    return const MenuTrash();
  }

  Widget _renderNewAppButton(BuildContext context) {
    return NewAppButton(
      press: (appName) => context.read<MenuBloc>().add(MenuEvent.createApp(appName, desc: "")),
    );
  }
}

class MenuSharedState extends ChangeNotifier {
  PublishNotifier<View> forcedOpenView = PublishNotifier();
  ValueNotifier<View?> selectedView = ValueNotifier<View?>(null);

  MenuSharedState({View? view}) {
    if (view != null) {
      selectedView.value = view;
    }

    forcedOpenView.addPublishListener((view) {
      selectedView.value = view;
    });
  }
}

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return SizedBox(
          height: HomeSizes.topBarHeight,
          child: Row(
            children: [
              (theme.isDark
                  ? svgWithSize("flowy_logo_dark_mode", const Size(92, 17))
                  : svgWithSize("flowy_logo_with_text", const Size(92, 17))),
              const Spacer(),
              FlowyIconButton(
                width: 28,
                onPressed: () => context.read<MenuBloc>().add(const MenuEvent.collapse()),
                iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                icon: svg("home/hide_menu", color: theme.iconColor),
              )
            ],
          ),
        );
      },
    );
  }
}
