import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/edit_pannel/pannel_animation.dart';
import 'package:app_flowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart' show UserProfile;
import 'package:flowy_sdk/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import '../widgets/edit_pannel/edit_pannel.dart';

import 'home_layout.dart';
import 'home_stack.dart';
import 'menu/menu.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile user;
  final CurrentWorkspaceSettingPB workspaceSetting;
  const HomeScreen(this.user, this.workspaceSetting, {Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ViewPB? initialView;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    initialView = null;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (context) {
            return HomeBloc(widget.user, widget.workspaceSetting)..add(const HomeEvent.initial());
          },
        ),
      ],
      child: Scaffold(
        body: BlocListener<HomeBloc, HomeState>(
          listenWhen: (p, c) => p.unauthorized != c.unauthorized,
          listener: (context, state) {
            if (state.unauthorized) {
              Log.error("Push to login screen when user token was invalid");
            }
          },
          child: BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              final collapasedNotifier = getIt<HomeStackManager>().collapsedNotifier;
              collapasedNotifier.addPublishListener((isCollapsed) {
                context.read<HomeBloc>().add(HomeEvent.forceCollapse(isCollapsed));
              });
              return FlowyContainer(
                Theme.of(context).colorScheme.surface,
                // Colors.white,
                child: _buildBody(state),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(HomeState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final layout = HomeLayout(context, constraints, state.forceCollapse);
        const homeStack = HomeStack();
        final menu = _buildHomeMenu(
          layout: layout,
          context: context,
          state: state,
        );
        final editPannel = _buildEditPannel(
          homeState: state,
          layout: layout,
          context: context,
        );
        const bubble = QuestionBubble();
        return _layoutWidgets(
          layout: layout,
          homeStack: homeStack,
          homeMenu: menu,
          editPannel: editPannel,
          bubble: bubble,
        );
      },
    );
  }

  Widget _buildHomeMenu({required HomeLayout layout, required BuildContext context, required HomeState state}) {
    final workspaceSetting = state.workspaceSetting;
    if (initialView == null && workspaceSetting.hasLatestView()) {
      initialView = workspaceSetting.latestView;
      final plugin = makePlugin(
        pluginType: initialView!.pluginType,
        data: initialView,
      );
      getIt<HomeStackManager>().setPlugin(plugin);
    }

    HomeMenu homeMenu = HomeMenu(
      user: widget.user,
      workspaceSetting: workspaceSetting,
      collapsedNotifier: getIt<HomeStackManager>().collapsedNotifier,
    );

    final latestView = workspaceSetting.hasLatestView() ? workspaceSetting.latestView : null;
    getIt<MenuSharedState>().latestOpenView = latestView;

    return FocusTraversalGroup(child: RepaintBoundary(child: homeMenu));
  }

  Widget _buildEditPannel({required HomeState homeState, required BuildContext context, required HomeLayout layout}) {
    final homeBloc = context.read<HomeBloc>();
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (previous, current) => previous.pannelContext != current.pannelContext,
      builder: (context, state) {
        return state.pannelContext.fold(
          () => const SizedBox(),
          (pannelContext) => FocusTraversalGroup(
            child: RepaintBoundary(
              child: EditPannel(
                pannelContext: pannelContext,
                onEndEdit: () => homeBloc.add(const HomeEvent.dismissEditPannel()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _layoutWidgets({
    required HomeLayout layout,
    required Widget homeMenu,
    required Widget homeStack,
    required Widget editPannel,
    required Widget bubble,
  }) {
    return Stack(
      children: [
        homeMenu
            .animatedPanelX(
              closeX: -layout.menuWidth,
              isClosed: !layout.showMenu,
            )
            .positioned(left: 0, top: 0, width: layout.menuWidth, bottom: 0, animate: true)
            .animate(layout.animDuration, Curves.easeOut),
        homeStack
            .constrained(minWidth: 500)
            .positioned(left: layout.homePageLOffset, right: layout.homePageROffset, bottom: 0, top: 0, animate: true)
            .animate(layout.animDuration, Curves.easeOut),
        bubble
            .positioned(
              right: 20,
              bottom: 16,
              animate: true,
            )
            .animate(layout.animDuration, Curves.easeOut),
        editPannel
            .animatedPanelX(
              duration: layout.animDuration.inMilliseconds * 0.001,
              closeX: layout.editPannelWidth,
              isClosed: !layout.showEditPannel,
            )
            .positioned(right: 0, top: 0, bottom: 0, width: layout.editPannelWidth),
      ],
    );
  }
}
