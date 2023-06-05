import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/home/home_bloc.dart';
import 'package:appflowy/workspace/application/home/home_service.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/widgets/edit_panel/panel_animation.dart';
import 'package:appflowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flowy_infra_ui/style_widget/container.dart';
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
  const HomeScreen(this.user, this.workspaceSetting, {final Key? key})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(final BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (final context) {
            return HomeBloc(widget.user, widget.workspaceSetting)
              ..add(const HomeEvent.initial());
          },
        ),
        BlocProvider<HomeSettingBloc>(
          create: (final context) {
            return HomeSettingBloc(
              widget.user,
              widget.workspaceSetting,
              context.read<AppearanceSettingsCubit>(),
            )..add(const HomeSettingEvent.initial());
          },
        ),
      ],
      child: HomeHotKeys(
        child: Scaffold(
          body: MultiBlocListener(
            listeners: [
              BlocListener<HomeBloc, HomeState>(
                listenWhen: (final p, final c) => p.unauthorized != c.unauthorized,
                listener: (final context, final state) {
                  if (state.unauthorized) {
                    Log.error(
                      "Push to login screen when user token was invalid",
                    );
                  }
                },
              ),
              BlocListener<HomeBloc, HomeState>(
                listenWhen: (final p, final c) => p.latestView != c.latestView,
                listener: (final context, final state) {
                  final view = state.latestView;
                  if (view != null) {
                    // Only open the last opened view if the [HomeStackManager] current opened plugin is blank and the last opened view is not null.
                    // All opened widgets that display on the home screen are in the form of plugins. There is a list of built-in plugins defined in the [PluginType] enum, including board, grid and trash.
                    if (getIt<HomeStackManager>().plugin.ty ==
                        PluginType.blank) {
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
              buildWhen: (final previous, final current) => previous != current,
              builder: (final context, final state) {
                return FlowyContainer(
                  Theme.of(context).colorScheme.surface,
                  child: _buildBody(context),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
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
    required final HomeLayout layout,
    required final BuildContext context,
  }) {
    final workspaceSetting = widget.workspaceSetting;
    final homeMenu = HomeMenu(
      user: widget.user,
      workspaceSetting: workspaceSetting,
    );

    return FocusTraversalGroup(child: RepaintBoundary(child: homeMenu));
  }

  Widget _buildEditPanel({
    required final BuildContext context,
    required final HomeLayout layout,
  }) {
    final homeBloc = context.read<HomeSettingBloc>();
    return BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (final previous, final current) =>
          previous.panelContext != current.panelContext,
      builder: (final context, final state) {
        return state.panelContext.fold(
          () => const SizedBox(),
          (final panelContext) => FocusTraversalGroup(
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
    required final BuildContext context,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (final details) => context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.editPanelResizeStart()),
        onHorizontalDragUpdate: (final details) => context
            .read<HomeSettingBloc>()
            .add(HomeSettingEvent.editPanelResized(details.localPosition.dx)),
        onHorizontalDragEnd: (final details) => context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.editPanelResizeEnd()),
        onHorizontalDragCancel: () => context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.editPanelResizeEnd()),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          width: 10,
          height: MediaQuery.of(context).size.height,
        ),
      ),
    );
  }

  Widget _layoutWidgets({
    required final HomeLayout layout,
    required final Widget homeMenu,
    required final Widget homeStack,
    required final Widget editPanel,
    required final Widget bubble,
    required final Widget homeMenuResizer,
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
              animate: true,
            )
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
              right: 0,
              top: 0,
              bottom: 0,
              width: layout.editPanelWidth,
            ),
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
              animate: true,
            )
            .animate(layout.animDuration, Curves.easeOut),
        homeMenuResizer
            .positioned(left: layout.menuWidth - 5)
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
  void didDeleteStackWidget(final ViewPB view, final int? index) {
    final homeService = HomeService();
    homeService.readApp(appId: view.appId).then((final result) {
      result.fold(
        (final appPB) {
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
        (final err) => Log.error(err),
      );
    });
  }
}
