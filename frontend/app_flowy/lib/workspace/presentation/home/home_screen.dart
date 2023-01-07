import 'package:app_flowy/plugins/blank/blank.dart';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_service.dart';
import 'package:app_flowy/workspace/application/home/home_setting_bloc.dart';

import 'package:app_flowy/workspace/presentation/home/hotkeys.dart';
import 'package:app_flowy/workspace/application/view/view_ext.dart';
import 'package:app_flowy/workspace/presentation/widgets/edit_panel/panel_animation.dart';
import 'package:app_flowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../widgets/edit_panel/edit_panel.dart';

import 'home_layout.dart';
import 'home_stack.dart';
import 'menu/menu.dart';

class HomeScreen extends StatefulWidget {
  final UserProfilePB user;
  final WorkspaceSettingPB workspaceSetting;
  const HomeScreen(this.user, this.workspaceSetting, {Key? key})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) {
            return HomeBloc(widget.user, widget.workspaceSetting)
              ..add(const HomeEvent.initial());
          },
        ),
        BlocProvider<HomeSettingBloc>(
          create: (context) {
            return HomeSettingBloc(widget.user, widget.workspaceSetting)
              ..add(const HomeSettingEvent.initial());
          },
        ),
      ],
      child: HomeHotKeys(
          child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (p, c) => p.unauthorized != c.unauthorized,
              listener: (context, state) {
                if (state.unauthorized) {
                  Log.error("Push to login screen when user token was invalid");
                }
              },
            ),
            BlocListener<HomeBloc, HomeState>(
              listenWhen: (p, c) => p.latestView != c.latestView,
              listener: (context, state) {
                final view = state.latestView;
                if (view != null) {
                  // Only open the last opened view if the [HomeStackManager] current opened plugin is blank and the last opened view is not null.
                  // All opened widgets that display on the home screen are in the form of plugins. There is a list of built-in plugins defined in the [PluginType] enum, including board, grid and trash.
                  if (getIt<HomeStackManager>().plugin.ty == PluginType.blank) {
                    final plugin = makePlugin(
                      pluginType: view.pluginType,
                      data: view,
                    );
                    getIt<HomeStackManager>().setPlugin(plugin);
                    getIt<MenuSharedState>().latestOpenView = view;
                  }
                }
              },
            ),
          ],
          child: BlocBuilder<HomeSettingBloc, HomeSettingState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              final collapsedNotifier =
                  getIt<HomeStackManager>().collapsedNotifier;
              collapsedNotifier.addPublishListener((isCollapsed) {
                context
                    .read<HomeSettingBloc>()
                    .add(HomeSettingEvent.forceCollapse(isCollapsed));
              });
              return FlowyContainer(
                Theme.of(context).colorScheme.surface,
                // Colors.white,
                child: _buildBody(context),
              );
            },
          ),
        ),
      )),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final layout = HomeLayout(context, constraints);
        final homeStack = HomeStack(
          layout: layout,
          delegate: HomeScreenStackAdaptor(
            buildContext: context,
          ),
        );
        final menu = _buildHomeMenu(
          layout: layout,
          context: context,
        );
        final homeMenuResizer = _buildHomeMenuResizer(context: context);
        final editPanel = _buildEditPanel(
          layout: layout,
          context: context,
        );
        const bubble = QuestionBubble();
        return _layoutWidgets(
          layout: layout,
          homeStack: homeStack,
          homeMenu: menu,
          editPanel: editPanel,
          bubble: bubble,
          homeMenuResizer: homeMenuResizer,
        );
      },
    );
  }

  Widget _buildHomeMenu({
    required HomeLayout layout,
    required BuildContext context,
  }) {
    final workspaceSetting = widget.workspaceSetting;
    final homeMenu = HomeMenu(
      user: widget.user,
      workspaceSetting: workspaceSetting,
      collapsedNotifier: getIt<HomeStackManager>().collapsedNotifier,
    );

    return FocusTraversalGroup(child: RepaintBoundary(child: homeMenu));
  }

  Widget _buildEditPanel({
    required BuildContext context,
    required HomeLayout layout,
  }) {
    final homeBloc = context.read<HomeSettingBloc>();
    return BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (previous, current) =>
          previous.panelContext != current.panelContext,
      builder: (context, state) {
        return state.panelContext.fold(
          () => const SizedBox(),
          (panelContext) => FocusTraversalGroup(
            child: RepaintBoundary(
              child: EditPanel(
                panelContext: panelContext,
                onEndEdit: () =>
                    homeBloc.add(const HomeSettingEvent.dismissEditPanel()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeMenuResizer({
    required BuildContext context,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart: (details) => context
              .read<HomeSettingBloc>()
              .add(const HomeSettingEvent.editPanelResizeStart()),
          onHorizontalDragUpdate: (details) => context
              .read<HomeSettingBloc>()
              .add(HomeSettingEvent.editPanelResized(details.localPosition.dx)),
          onHorizontalDragEnd: (details) => context
              .read<HomeSettingBloc>()
              .add(const HomeSettingEvent.editPanelResizeEnd()),
          onHorizontalDragCancel: () => context
              .read<HomeSettingBloc>()
              .add(const HomeSettingEvent.editPanelResizeEnd()),
          behavior: HitTestBehavior.translucent,
          child: SizedBox(
            width: 10,
            height: MediaQuery.of(context).size.height,
          )),
    );
  }

  Widget _layoutWidgets({
    required HomeLayout layout,
    required Widget homeMenu,
    required Widget homeStack,
    required Widget editPanel,
    required Widget bubble,
    required Widget homeMenuResizer,
  }) {
    return Stack(
      children: [
        homeStack
            .constrained(minWidth: 500)
            .positioned(
                left: layout.homePageLOffset,
                right: layout.homePageROffset,
                bottom: 0,
                top: 0,
                animate: true)
            .animate(layout.animDuration, Curves.easeOut),
        bubble
            .positioned(
              right: 20,
              bottom: 16,
              animate: true,
            )
            .animate(layout.animDuration, Curves.easeOut),
        editPanel
            .animatedPanelX(
              duration: layout.animDuration.inMilliseconds * 0.001,
              closeX: layout.editPanelWidth,
              isClosed: !layout.showEditPanel,
            )
            .positioned(
                right: 0, top: 0, bottom: 0, width: layout.editPanelWidth),
        homeMenu
            .animatedPanelX(
              closeX: -layout.menuWidth,
              isClosed: !layout.showMenu,
            )
            .positioned(
                left: 0,
                top: 0,
                width: layout.menuWidth,
                bottom: 0,
                animate: true)
            .animate(layout.animDuration, Curves.easeOut),
        homeMenuResizer
            .positioned(left: layout.homePageLOffset - 5)
            .animate(layout.animDuration, Curves.easeOut),
      ],
    );
  }
}

class HomeScreenStackAdaptor extends HomeStackDelegate {
  final BuildContext buildContext;

  HomeScreenStackAdaptor({
    required this.buildContext,
  });

  @override
  void didDeleteStackWidget(ViewPB view, int? index) {
    final homeService = HomeService();
    homeService.readApp(appId: view.appId).then((result) {
      result.fold(
        (appPB) {
          final List<ViewPB> views = appPB.belongings.items;
          if (views.isNotEmpty) {
            var lastView = views.last;
            if (index != null && index != 0 && views.length > index - 1) {
              lastView = views[index - 1];
            }

            final plugin = makePlugin(
              pluginType: lastView.pluginType,
              data: lastView,
            );
            getIt<MenuSharedState>().latestOpenView = lastView;
            getIt<HomeStackManager>().setPlugin(plugin);
          } else {
            getIt<MenuSharedState>().latestOpenView = null;
            getIt<HomeStackManager>().setPlugin(BlankPagePlugin());
          }
        },
        (err) => Log.error(err),
      );
    });
  }
}
