import 'package:app_flowy/workspace/application/menu/menu_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_watch.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/app/app_widget.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/create_app_dialog.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/user_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'menu_list.dart';

class HomeMenu extends StatelessWidget {
  final Function(HomeStackView?) pageContextChanged;
  final Function(bool) isCollapseChanged;
  final String workspaceId;

  const HomeMenu(
      {Key? key,
      required this.pageContextChanged,
      required this.isCollapseChanged,
      required this.workspaceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuBloc>(
            create: (context) => getIt<MenuBloc>(param1: workspaceId)
              ..add(const MenuEvent.initial())),
        BlocProvider(
            create: (context) => getIt<MenuWatchBloc>(param1: workspaceId)
              ..add(const MenuWatchEvent.started())),
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
          initial: (_) => BlocBuilder<MenuBloc, MenuState>(
            builder: (context, s) => MenuList(
              menuItems: menuItemsWithApps(s.apps),
            ),
          ),
          loadApps: (s) => MenuList(menuItems: menuItemsWithApps(some(s.apps))),
          loadFail: (s) => FlowyErrorPage(s.error.toString()),
        );
      },
    );
  }

  Widget _renderNewAppButton(BuildContext context) {
    return NewAppButton(
      press: (appName) =>
          context.read<MenuBloc>().add(MenuEvent.createApp(appName, desc: "")),
    );
  }

  Widget _renderTopBar(BuildContext context) {
    return SizedBox(
      height: HomeSizes.menuTopBarHeight,
      child: const MenuTopBar(),
    );
  }

  List<MenuItem> menuItemsWithApps(Option<List<App>> someApps) {
    List<MenuItem> menuItems = [
      const UserProfile(),
    ];

    // apps
    List<MenuItem> appWidgets = someApps.fold(
      () => [],
      (apps) => apps.map((app) => AppWidget(app)).toList(),
    );

    menuItems.addAll(appWidgets);
    return menuItems;
  }
}

class MenuTopBar extends StatelessWidget {
  const MenuTopBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return Row(
          children: [
            const Image(
                fit: BoxFit.cover,
                width: 25,
                height: 25,
                image: AssetImage('assets/images/app_flowy_logo.jpg')),
            const HSpace(8),
            const Text(
              'AppFlowy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_left),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.zero,
              onPressed: () =>
                  context.read<MenuBloc>().add(const MenuEvent.collapse()),
            ),
          ],
        );
      },
    );
  }
}

class NewAppButton extends StatelessWidget {
  final Function(String)? press;

  const NewAppButton({this.press, Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
      ),
      height: HomeSizes.menuAddButtonHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.add_circle_rounded, size: 30),
          TextButton(
            onPressed: () async => await _showCreateAppDialog(context),
            child: const Text(
              'New App',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          )
        ],
      ).padding(horizontal: Insets.l),
    );
  }

  Future<void> _showCreateAppDialog(BuildContext context) async {
    await Dialogs.showWithContext(CreateAppDialogContext(
      confirm: (appName) {
        if (appName.isNotEmpty && press != null) {
          press!(appName);
        }
      },
    ), context);
  }
}
