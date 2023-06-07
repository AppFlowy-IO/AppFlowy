import 'dart:io' show Platform;

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/trash/menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/menu/menu_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
// import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../navigation.dart';
import 'app/create_button.dart';
import 'app/menu_app.dart';
import 'menu_user.dart';

export './app/header/header.dart';
export './app/menu_app.dart';

class HomeMenu extends StatelessWidget {
  final UserProfilePB user;
  final WorkspaceSettingPB workspaceSetting;

  const HomeMenu({
    Key? key,
    required this.user,
    required this.workspaceSetting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MenuBloc>(
          create: (context) {
            final menuBloc = MenuBloc(
              user: user,
              workspace: workspaceSetting.workspace,
            );
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
        ],
        child: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) => _renderBody(context),
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    // nested column: https://siddharthmolleti.com/flutter-box-constraints-nested-column-s-row-s-3dfacada7361
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border:
            Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
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
          const MenuTrash(),
          const VSpace(20),
          _renderNewAppButton(context),
        ],
      ),
    );
  }

  Widget _renderApps(BuildContext context) {
    return ExpandableTheme(
      data: ExpandableThemeData(
        useInkWell: true,
        animationDuration: Durations.medium,
      ),
      child: Expanded(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: BlocSelector<MenuBloc, MenuState, List<Widget>>(
            selector: (state) => state.views
                .map((app) => MenuApp(app, key: ValueKey(app.id)))
                .toList(),
            builder: (context, menuItems) {
              return ReorderableListView.builder(
                itemCount: menuItems.length,
                buildDefaultDragHandles: false,
                header: Padding(
                  padding:
                      EdgeInsets.only(bottom: 20.0 - MenuAppSizes.appVPadding),
                  child: MenuUser(user),
                ),
                onReorder: (oldIndex, newIndex) {
                  // Moving item1 from index 0 to index 1
                  //  expect:   oldIndex: 0, newIndex: 1
                  //  receive:  oldIndex: 0, newIndex: 2
                  //  Workaround: if newIndex > oldIndex, we just minus one
                  final int index = newIndex > oldIndex ? newIndex - 1 : newIndex;
                  context
                      .read<MenuBloc>()
                      .add(MenuEvent.moveApp(oldIndex, index));
                },
                physics: StyledScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  return ReorderableDragStartListener(
                    key: ValueKey(menuItems[index].key),
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: MenuAppSizes.appVPadding / 2,
                      ),
                      child: menuItems[index],
                    ),
                  );
                },
                proxyDecorator: (child, index, animation) =>
                    Material(color: Colors.transparent, child: child),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _renderNewAppButton(BuildContext context) {
    return NewAppButton(
      press: (appName) =>
          context.read<MenuBloc>().add(MenuEvent.createApp(appName, desc: "")),
    );
  }
}

class MenuSharedState {
  final ValueNotifier<ViewPB?> _latestOpenView = ValueNotifier<ViewPB?>(null);

  MenuSharedState({ViewPB? view}) {
    _latestOpenView.value = view;
  }

  ViewPB? get latestOpenView => _latestOpenView.value;
  ValueNotifier<ViewPB?> get notifier => _latestOpenView;

  set latestOpenView(ViewPB? view) {
    if (_latestOpenView.value != view) {
      _latestOpenView.value = view;
    }
  }

  VoidCallback addLatestViewListener(void Function(ViewPB?) callback) {
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
    return (Theme.of(context).brightness == Brightness.dark
        ? svgWidget("flowy_logo_dark_mode", size: const Size(92, 17))
        : svgWidget("flowy_logo_with_text", size: const Size(92, 17)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      builder: (context, state) {
        return SizedBox(
          height: HomeSizes.topBarHeight,
          child: MoveWindowDetector(
            child: Row(
              children: [
                renderIcon(context),
                const Spacer(),
                Tooltip(
                  richMessage: sidebarTooltipTextSpan(
                    context,
                    LocaleKeys.sideBar_closeSidebar.tr(),
                  ),
                  child: FlowyIconButton(
                    width: 28,
                    hoverColor: Colors.transparent,
                    onPressed: () => context
                        .read<HomeSettingBloc>()
                        .add(const HomeSettingEvent.collapseMenu()),
                    iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                    icon: svgWidget(
                      "home/hide_menu",
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
