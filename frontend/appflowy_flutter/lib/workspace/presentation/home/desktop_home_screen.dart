import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/memory_leak_detector.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/home/home_bloc.dart';
import 'package:appflowy/workspace/application/home/home_service.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar.dart';
import 'package:appflowy/workspace/presentation/widgets/edit_panel/panel_animation.dart';
import 'package:appflowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart'
    show UserProfilePB;
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sized_context/sized_context.dart';
import 'package:styled_widget/styled_widget.dart';

import '../widgets/edit_panel/edit_panel.dart';

import 'home_layout.dart';
import 'home_stack.dart';

class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({super.key});

  static const routeName = '/DesktopHomeScreen';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FolderEventGetCurrentWorkspaceSetting().send(),
        getIt<AuthService>().getUser(),
      ]),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return _buildLoading();
        }

        final workspaceSetting = snapshots.data?[0].fold(
          (workspaceSettingPB) => workspaceSettingPB as WorkspaceSettingPB,
          (error) => null,
        );
        final userProfile = snapshots.data?[1].fold(
          (userProfilePB) => userProfilePB as UserProfilePB,
          (error) => null,
        );

        // In the unlikely case either of the above is null, eg.
        // when a workspace is already open this can happen.
        if (workspaceSetting == null || userProfile == null) {
          return const WorkspaceFailedScreen();
        }

        return MultiBlocProvider(
          key: ValueKey(userProfile.id),
          providers: [
            BlocProvider<ReminderBloc>.value(value: getIt<ReminderBloc>()),
            BlocProvider<TabsBloc>.value(value: getIt<TabsBloc>()),
            BlocProvider<HomeBloc>(
              create: (_) =>
                  HomeBloc(workspaceSetting)..add(const HomeEvent.initial()),
            ),
            BlocProvider<HomeSettingBloc>(
              create: (_) => HomeSettingBloc(
                workspaceSetting,
                context.read<AppearanceSettingsCubit>(),
                context.widthPx,
              )..add(const HomeSettingEvent.initial()),
            ),
            BlocProvider<FavoriteBloc>(
              create: (context) =>
                  FavoriteBloc()..add(const FavoriteEvent.initial()),
            ),
          ],
          child: HomeHotKeys(
            child: Scaffold(
              floatingActionButton: enableMemoryLeakDetect
                  ? const FloatingActionButton(
                      onPressed: dumpMemoryLeak,
                      child: Icon(Icons.memory),
                    )
                  : null,
              body: BlocListener<HomeBloc, HomeState>(
                listenWhen: (p, c) => p.latestView != c.latestView,
                listener: (context, state) {
                  final view = state.latestView;
                  if (view != null) {
                    // Only open the last opened view if the [TabsState.currentPageManager] current opened plugin is blank and the last opened view is not null.
                    // All opened widgets that display on the home screen are in the form of plugins. There is a list of built-in plugins defined in the [PluginType] enum, including board, grid and trash.
                    final currentPageManager =
                        context.read<TabsBloc>().state.currentPageManager;

                    if (currentPageManager.plugin.pluginType ==
                        PluginType.blank) {
                      getIt<TabsBloc>().add(
                        TabsEvent.openPlugin(plugin: view.plugin()),
                      );
                    }
                  }
                },
                child: BlocBuilder<HomeSettingBloc, HomeSettingState>(
                  buildWhen: (previous, current) => previous != current,
                  builder: (context, state) => FlowyContainer(
                    Theme.of(context).colorScheme.surface,
                    child: _buildBody(context, userProfile, workspaceSetting),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() =>
      const Center(child: CircularProgressIndicator.adaptive());

  Widget _buildBody(
    BuildContext context,
    UserProfilePB userProfile,
    WorkspaceSettingPB workspaceSetting,
  ) {
    final layout = HomeLayout(context);
    final homeStack = HomeStack(
      layout: layout,
      delegate: DesktopHomeScreenStackAdaptor(context),
    );
    final menu = _buildHomeSidebar(
      context,
      layout: layout,
      userProfile: userProfile,
      workspaceSetting: workspaceSetting,
    );
    final homeMenuResizer = _buildHomeMenuResizer(context, layout: layout);
    final editPanel = _buildEditPanel(context, layout: layout);

    return _layoutWidgets(
      layout: layout,
      homeStack: homeStack,
      homeMenu: menu,
      editPanel: editPanel,
      bubble: const QuestionBubble(),
      homeMenuResizer: homeMenuResizer,
    );
  }

  Widget _buildHomeSidebar(
    BuildContext context, {
    required HomeLayout layout,
    required UserProfilePB userProfile,
    required WorkspaceSettingPB workspaceSetting,
  }) {
    final homeMenu = HomeSideBar(
      userProfile: userProfile,
      workspaceSetting: workspaceSetting,
    );
    return FocusTraversalGroup(child: RepaintBoundary(child: homeMenu));
  }

  Widget _buildEditPanel(
    BuildContext context, {
    required HomeLayout layout,
  }) {
    final homeBloc = context.read<HomeSettingBloc>();
    return BlocBuilder<HomeSettingBloc, HomeSettingState>(
      buildWhen: (previous, current) =>
          previous.panelContext != current.panelContext,
      builder: (context, state) {
        final panelContext = state.panelContext;
        if (panelContext == null) {
          return const SizedBox.shrink();
        }

        return FocusTraversalGroup(
          child: RepaintBoundary(
            child: EditPanel(
              panelContext: panelContext,
              onEndEdit: () => homeBloc.add(
                const HomeSettingEvent.dismissEditPanel(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeMenuResizer(
    BuildContext context, {
    required HomeLayout layout,
  }) {
    if (!layout.showMenu) {
      return const SizedBox.shrink();
    }

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
            .animate(layout.animDuration, Curves.easeOutQuad),
        bubble
            .positioned(right: 20, bottom: 16, animate: true)
            .animate(layout.animDuration, Curves.easeOut),
        editPanel
            .animatedPanelX(
              duration: layout.animDuration.inMilliseconds * 0.001,
              closeX: layout.editPanelWidth,
              isClosed: !layout.showEditPanel,
              curve: Curves.easeOutQuad,
            )
            .positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: layout.editPanelWidth,
            ),
        homeMenu
            .animatedPanelX(
              closeX: -layout.menuWidth,
              isClosed: !layout.showMenu,
              curve: Curves.easeOutQuad,
              duration: layout.animDuration.inMilliseconds * 0.001,
            )
            .positioned(left: 0, top: 0, width: layout.menuWidth, bottom: 0),
        homeMenuResizer
            .positioned(left: layout.menuWidth - 5)
            .animate(layout.animDuration, Curves.easeOutQuad),
      ],
    );
  }
}

class DesktopHomeScreenStackAdaptor extends HomeStackDelegate {
  DesktopHomeScreenStackAdaptor(this.buildContext);

  final BuildContext buildContext;

  @override
  void didDeleteStackWidget(ViewPB view, int? index) {
    HomeService.readApp(appId: view.parentViewId).then((result) {
      result.fold(
        (parentView) {
          final List<ViewPB> views = parentView.childViews;
          if (views.isNotEmpty) {
            ViewPB lastView = views.last;
            if (index != null && index != 0 && views.length > index - 1) {
              lastView = views[index - 1];
            }

            return getIt<TabsBloc>()
                .add(TabsEvent.openPlugin(plugin: lastView.plugin()));
          }

          getIt<TabsBloc>()
              .add(TabsEvent.openPlugin(plugin: BlankPagePlugin()));
        },
        (err) => Log.error(err),
      );
    });
  }
}
