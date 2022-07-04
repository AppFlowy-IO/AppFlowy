export './app/header/header.dart';
export './app/menu_app.dart';

import 'dart:io' show Platform;
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/plugins/trash/menu.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/core/frameless_window.dart';
// import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

import 'app/menu_app.dart';
import 'app/create_button.dart';
import 'menu_user.dart';

class HomeMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuBloc>(
          create: (context) {
            final menuBloc = getIt<MenuBloc>(param1: user, param2: workspaceSetting.workspace.id);
            menuBloc.add(const MenuEvent.initial());
            return menuBloc;
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.plugin.id != c.plugin.id,
            listener: (context, state) {
              getIt<HomeStackManager>().setPlugin(state.plugin);
            },
          ),
          BlocListener<HomeBloc, HomeState>(
            listenWhen: (p, c) => p.isMenuCollapsed != c.isMenuCollapsed,
            listener: (context, state) {
              _collapsedNotifier.value = state.isMenuCollapsed;
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
      child: Column(
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
          const MenuTrash().padding(horizontal: Insets.l),
          const VSpace(20),
          _renderNewAppButton(context),
        ],
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
            selector: (state) => state.apps.map((app) => MenuApp(app, key: ValueKey(app.id))).toList(),
            builder: (context, menuItems) {
              return ReorderableListView.builder(
                itemCount: menuItems.length,
                buildDefaultDragHandles: false,
                header: Padding(
                  padding: EdgeInsets.only(bottom: 20.0 - MenuAppSizes.appVPadding),
                  child: MenuUser(user),
                ),
                onReorder: (oldIndex, newIndex) {
                  // Moving item1 from index 0 to index 1
                  //  expect:   oldIndex: 0, newIndex: 1
                  //  receive:  oldIndex: 0, newIndex: 2
                  //  Workaround: if newIndex > oldIndex, we just minus one
                  int index = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  context.read<MenuBloc>().add(MenuEvent.moveApp(oldIndex, index));
                },
                physics: StyledScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return ReorderableDragStartListener(
                    key: ValueKey(menuItems[index].key),
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

  Widget _renderNewAppButton(BuildContext context) {
    return NewAppButton(
      press: (appName) => context.read<MenuBloc>().add(MenuEvent.createApp(appName, desc: "")),
    );
  }
}

class MenuSharedState {
  final ValueNotifier<View?> _latestOpenView = ValueNotifier<View?>(null);

  MenuSharedState({View? view}) {
    _latestOpenView.value = view;
  }

  View? get latestOpenView => _latestOpenView.value;

  set latestOpenView(View? view) {
    _latestOpenView.value = view;
  }

  VoidCallback addLatestViewListener(void Function(View?) callback) {
    listener() {
      callback(_latestOpenView.value);
    }

    _latestOpenView.addListener(listener);
    return listener;
  }

  void removeLatestViewListener(VoidCallback listener) {
    _latestOpenView.removeListener(listener);
  }
}

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);

  Widget renderIcon(BuildContext context) {
    if (Platform.isMacOS) {
      return Container();
    }
    final theme = context.watch<AppTheme>();
    return (theme.isDark
        ? svgWithSize("flowy_logo_dark_mode", const Size(92, 17))
        : svgWithSize("flowy_logo_with_text", const Size(92, 17)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return SizedBox(
          height: HomeSizes.topBarHeight,
          child: MoveWindowDetector(
              child: Row(
            children: [
              renderIcon(context),
              const Spacer(),
              FlowyIconButton(
                width: 28,
                onPressed: () => context.read<HomeBloc>().add(const HomeEvent.collapseMenu()),
                iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                icon: svgWidget("home/hide_menu", color: theme.iconColor),
              )
            ],
          )),
        );
      },
    );
  }
}
