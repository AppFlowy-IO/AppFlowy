import 'package:app_flowy/workspace/presentation/widgets/menu/widget/top_bar.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-core-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/workspace.pb.dart';
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
            listenWhen: (p, c) => p.stackContext != c.stackContext,
            listener: (context, state) {
              getIt<HomeStackManager>().setStack(state.stackContext);
            },
          ),
          BlocListener<MenuBloc, MenuState>(
            listenWhen: (p, c) => p.isCollapse != c.isCollapse,
            listener: (context, state) => _collapsedNotifier.value = state.isCollapse,
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
        create: (_) => MenuSharedState(view: workspaceSetting.hasLatestView() ? workspaceSetting.latestView : null),
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
              menuItems.add(MenuUser(user));
              List<MenuApp> appWidgets =
                  state.apps.foldRight([], (apps, _) => apps.map((app) => MenuApp(app)).toList());
              menuItems.addAll(appWidgets);
              return menuItems;
            },
            builder: (context, menuItems) => ListView.separated(
              itemCount: menuItems.length,
              separatorBuilder: (context, index) {
                if (index == 0) {
                  return const VSpace(20);
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
