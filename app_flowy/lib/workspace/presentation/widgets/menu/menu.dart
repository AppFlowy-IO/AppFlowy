import 'package:app_flowy/workspace/presentation/widgets/menu/widget/top_bar.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/menu_user.dart';

import 'widget/app/menu_app.dart';
import 'widget/app/create_button.dart';
import 'widget/menu_trash.dart';

// [[diagram: HomeMenu's widget structure]]
//                                                                                    get user profile or modify user
//                                                                                   ┌──────┐
//                 ┌──────────┐                                                  ┌──▶│IUser │
//              ┌─▶│MenuTopBar│                     ┌────────┐  ┌─────────────┐  │   └──────┘
//              │  └──────────┘                 ┌───│MenuUser│─▶│MenuUserBloc │──┤
// ┌──────────┐ │                               │   └────────┘  └─────────────┘  │   ┌─────────────┐
// │ HomeMenu │─┤                               │                                └──▶│IUserListener│
// └──────────┘ │                               │                                    └─────────────┘
//              │                               │                                    listen workspace changes or user
//              │                         impl  │                                    profile changes
//              │  ┌──────────┐    ┌─────────┐  │
//              └─▶│ MenuList │───▶│MenuItem │◀─┤
//                 └──────────┘    └─────────┘  │                  ┌────────┐
//                                              │               ┌─▶│AppBloc │  fetch app's views or modify view
//                                              │               │  └────────┘
//                                              │   ┌────────┐  │
//                                              └───│MenuApp │──┤
//                                                  └────────┘

class HomeMenu extends StatelessWidget {
  final Function(HomeStackContext) pageContextChanged;
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
          create: (context) => getIt<MenuBloc>(param1: user, param2: workspaceId)..add(const MenuEvent.initial()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.context != c.context,
            listener: (context, state) => pageContextChanged(state.context),
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
      child: ChangeNotifierProvider(
        create: (_) => MenuSharedState(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _renderTopBar(context),
                  const VSpace(32),
                  _renderApps(context),
                ],
              ).padding(horizontal: Insets.l),
            ),
            const VSpace(20),
            _renderTrash(context).padding(horizontal: Insets.l),
            const VSpace(20),
            _renderNewAppButton(context),
          ],
        ),
      ),
    );
  }

  Widget _renderTopBar(BuildContext context) {
    return const MenuTopBar();
  }

  Widget _renderApps(BuildContext context) {
    final apps = context.read<MenuBloc>().state.apps;
    List<Widget> menuItems = [];
    menuItems.add(MenuUser(user));
    List<MenuApp> appWidgets = apps.foldRight([], (apps, _) => apps.map((app) => MenuApp(app)).toList());
    menuItems.addAll(appWidgets);

    return ExpandableTheme(
      data: ExpandableThemeData(useInkWell: true, animationDuration: Durations.medium),
      child: Expanded(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: ListView.separated(
            itemCount: menuItems.length,
            separatorBuilder: (context, index) {
              if (index == 0) {
                return const VSpace(29);
              } else {
                return VSpace(MenuAppSizes.appVPadding);
              }
            },
            physics: StyledScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return menuItems[index];
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
  View? _view;
  View? _forcedOpenView;

  void addForcedOpenViewListener(void Function(View) callback) {
    super.addListener(() {
      if (_forcedOpenView != null) {
        callback(_forcedOpenView!);
      }
    });
  }

  void addSelectedViewListener(void Function(View?) callback) {
    super.addListener(() {
      callback(_view);
    });
  }

  set forcedOpenView(View? view) {
    if (_forcedOpenView != view) {
      _forcedOpenView = view;
      selectedView = view;
      notifyListeners();
    }
    _forcedOpenView = null;
  }

  set selectedView(View? view) {
    if (_view != view) {
      _view = view;
      notifyListeners();
    }
  }

  View? get selecedtView => _view;
}
