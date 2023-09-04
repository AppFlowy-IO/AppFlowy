import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/home/home_bloc.dart';
import 'package:appflowy/workspace/application/home/home_service.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar.dart';
import 'package:appflowy/workspace/presentation/widgets/edit_panel/panel_animation.dart';
import 'package:appflowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
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
        BlocProvider<PanesCubit>.value(value: getIt<PanesCubit>()),
        BlocProvider<HomeBloc>(
          create: (context) {
            return HomeBloc(widget.user, widget.workspaceSetting)
              ..add(const HomeEvent.initial());
          },
        ),
        BlocProvider<HomeSettingBloc>(
          create: (context) {
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
                listenWhen: (p, c) => p.latestView != c.latestView,
                listener: (context, state) {
                  final view = state.latestView;
                  if (view != null) {
                    // Only open the last opened view if the [TabsState.currentPageManager] current opened plugin is blank and the last opened view is not null.
                    // All opened widgets that display on the home screen are in the form of plugins. There is a list of built-in plugins defined in the [PluginType] enum, including board, grid and trash.
                    final currentPageManager = context
                        .read<PanesCubit>()
                        .state
                        .activePane
                        .tabs
                        .currentPageManager;

                    if (currentPageManager.plugin.pluginType ==
                        PluginType.blank) {
                      getIt<PanesCubit>().openPlugin(
                        plugin: view.plugin(listenOnViewChanged: true),
                      );
                    }
                  }
                },
              ),
            ],
            child: BlocBuilder<HomeSettingBloc, HomeSettingState>(
              buildWhen: (previous, current) => previous != current,
              builder: (context, state) {
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
        final menu = _buildHomeSidebar(
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

  Widget _buildHomeSidebar({
    required HomeLayout layout,
    required BuildContext context,
  }) {
    final workspaceSetting = widget.workspaceSetting;
    final homeMenu = HomeSideBar(
      user: widget.user,
      workspaceSetting: workspaceSetting,
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
        ),
      ),
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
        homeMenuResizer.positioned(left: layout.menuWidth - 5)
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
    homeService.readApp(appId: view.parentViewId).then((result) {
      result.fold(
        (parentView) {
          final List<ViewPB> views = parentView.childViews;
          if (views.isNotEmpty) {
            ViewPB lastView = views.last;
            if (index != null && index != 0 && views.length > index - 1) {
              lastView = views[index - 1];
            }
            getIt<PanesCubit>()
                .openPlugin(plugin: lastView.plugin(listenOnViewChanged: true));
          } else {
            getIt<PanesCubit>().openPlugin(plugin: BlankPagePlugin());
          }
        },
        (err) => Log.error(err),
      );
    });
  }
}
