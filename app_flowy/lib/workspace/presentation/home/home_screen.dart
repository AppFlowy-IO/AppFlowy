import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_listen_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/stack_page/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/float_bubble/question_bubble.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_infra_ui/style_widget/container.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'home_layout.dart';

class HomeScreen extends StatelessWidget {
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final UserProfile user;
  final String workspaceId;
  const HomeScreen(this.user, this.workspaceId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeListenBloc>(
          create: (context) => getIt<HomeListenBloc>(param1: user)..add(const HomeListenEvent.started()),
        ),
        BlocProvider<HomeBloc>(create: (context) => getIt<HomeBloc>()),
      ],
      child: Scaffold(
        key: HomeScreen.scaffoldKey,
        body: BlocListener<HomeListenBloc, HomeListenState>(
          listener: (context, state) {
            state.map(
              loading: (_) {},
              unauthorized: (unauthorized) {
                // TODO: push to login screen when user token was invalid
                Log.error("Push to login screen when user token was invalid");
              },
            );
          },
          child: BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (previous, current) => previous != current,
            builder: (context, state) {
              return FlowyContainer(
                Theme.of(context).colorScheme.surface,
                // Colors.white,
                child: _buildBody(state, context.read<HomeBloc>().state.forceCollapse),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(HomeState state, bool forceCollapse) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final layout = HomeLayout(context, constraints, forceCollapse);
        const homeStack = HomeStack();
        final menu = _buildHomeMenu(
          layout: layout,
          context: context,
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

  Widget _buildHomeMenu({required HomeLayout layout, required BuildContext context}) {
    final homeBloc = context.read<HomeBloc>();
    final collapasedNotifier = getIt<HomeStackManager>().collapsedNotifier;

    HomeMenu homeMenu = HomeMenu(user: user, workspaceId: workspaceId, collapsedNotifier: collapasedNotifier);
    collapasedNotifier.addPublishListener((isCollapsed) {
      homeBloc.add(HomeEvent.forceCollapse(isCollapsed));
    });

    homeMenu.pageContext.addPublishListener((pageContext) {
      getIt<HomeStackManager>().switchStack(pageContext);
    });

    return FocusTraversalGroup(child: RepaintBoundary(child: homeMenu));
  }

  Widget _buildEditPannel({required HomeState homeState, required BuildContext context, required HomeLayout layout}) {
    final homeBloc = context.read<HomeBloc>();
    Widget editPannel = EditPannel(
      context: homeState.editContext,
      onEndEdit: () => homeBloc.add(const HomeEvent.dismissEditPannel()),
    );
    // editPannel = RepaintBoundary(child: editPannel);
    // editPannel = FocusTraversalGroup(child: editPannel);
    return editPannel;
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
        editPannel
            .animatedPanelX(
              duration: layout.animDuration.inMilliseconds * 0.001,
              closeX: layout.editPannelWidth,
              isClosed: !layout.showEditPannel,
            )
            .positioned(right: 0, top: 0, bottom: 0, width: layout.editPannelWidth),
        bubble
            .positioned(
              right: 20,
              bottom: 20,
              animate: true,
            )
            .animate(layout.animDuration, Curves.easeOut),
      ],
    );
  }
}
