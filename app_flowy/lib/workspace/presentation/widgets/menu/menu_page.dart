import 'package:app_flowy/workspace/presentation/widgets/menu/menu_new_app.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_top_bar.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_watch.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/app/app_page.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_user.dart';

import 'menu_list.dart';

class HomeMenu extends StatelessWidget {
  final Function(HomeStackView?) pageContextChanged;
  final Function(bool) isCollapseChanged;
  final UserProfile user;
  final String workspaceId;

  const HomeMenu({
    Key? key,
    required this.pageContextChanged,
    required this.isCollapseChanged,
    required this.user,
    required this.workspaceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuBloc>(
            create: (context) => getIt<MenuBloc>(param1: user, param2: workspaceId)..add(const MenuEvent.initial())),
        BlocProvider(
            create: (context) =>
                getIt<MenuWatchBloc>(param1: user, param2: workspaceId)..add(const MenuWatchEvent.started())),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.stackView != c.stackView,
            listener: (context, state) => pageContextChanged(state.stackView),
          ),
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.isCollapse != c.isCollapse,
            listener: (context, state) => isCollapseChanged(state.isCollapse),
          )
        ],
        child: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) => _renderBody(context),
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    // nested cloumn: https://siddharthmolleti.com/flutter-box-constraints-nested-column-s-row-s-3dfacada7361
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _renderTopBar(context),
                const VSpace(32),
                _renderMenuList(context),
              ],
            ).padding(horizontal: Insets.l),
          ),
          _renderNewAppButton(context),
        ],
      ),
    );
  }

  Widget _renderMenuList(BuildContext context) {
    return BlocBuilder<MenuWatchBloc, MenuWatchState>(
      builder: (context, state) {
        return state.map(
          initial: (_) => MenuList(
            menuItems: menuItemsWithApps(context.read<MenuBloc>().state.apps),
          ),
          loadApps: (s) => MenuList(
            menuItems: menuItemsWithApps(some(s.apps)),
          ),
          loadFail: (s) => FlowyErrorPage(s.error.toString()),
        );
      },
    );
  }

  Widget _renderNewAppButton(BuildContext context) {
    return NewAppButton(
      press: (appName) => context.read<MenuBloc>().add(MenuEvent.createApp(appName, desc: "")),
    );
  }

  Widget _renderTopBar(BuildContext context) {
    return const MenuTopBar();
  }

  List<MenuItem> menuItemsWithApps(Option<List<App>> someApps) {
    return MenuItemBuilder().withUser(user).withApps(someApps).build();
  }
}

class MenuItemBuilder {
  List<MenuItem> items = [];

  MenuItemBuilder();

  MenuItemBuilder withUser(UserProfile user) {
    items.add(MenuUser(user));
    return this;
  }

  MenuItemBuilder withApps(Option<List<App>> someApps) {
    List<MenuItem> appWidgets = someApps.foldRight(
      [],
      (apps, _) => apps.map((app) => AppPage(AppPageContext(app))).toList(),
    );
    items.addAll(appWidgets);
    return this;
  }

  List<MenuItem> build() {
    return items;
  }
}
