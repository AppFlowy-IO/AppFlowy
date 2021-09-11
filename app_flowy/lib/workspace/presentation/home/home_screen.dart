import 'package:app_flowy/workspace/application/home/home_bloc.dart';
import 'package:app_flowy/workspace/application/home/home_auth_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_infra/flowy_logger.dart';
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
        BlocProvider<HomeAuthBloc>(
          create: (context) => getIt<HomeAuthBloc>(param1: user)
            ..add(const HomeAuthEvent.started()),
        ),
        BlocProvider<HomeBloc>(create: (context) => getIt<HomeBloc>()),
      ],
      child: Scaffold(
        key: HomeScreen.scaffoldKey,
        body: BlocListener<HomeAuthBloc, HomeAuthState>(
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
                child: _buildBody(
                    state, context.read<HomeBloc>().state.forceCollapse),
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
        const homePage = HomePage();
        final menu = _buildHomeMenu(
          layout: layout,
          context: context,
        );
        final editPannel = _buildEditPannel(
          homeState: state,
          layout: layout,
          context: context,
        );
        return _layoutWidgets(
            layout: layout,
            homePage: homePage,
            homeMenu: menu,
            editPannel: editPannel);
      },
    );
  }

  Widget _buildHomeMenu(
      {required HomeLayout layout, required BuildContext context}) {
    final homeBloc = context.read<HomeBloc>();
    Widget homeMenu = HomeMenu(
      pageContextChanged: (pageContext) {
        getIt<HomePageStack>().setStackView(pageContext);
      },
      isCollapseChanged: (isCollapse) {
        homeBloc.add(HomeEvent.forceCollapse(isCollapse));
      },
      user: user,
      workspaceId: workspaceId,
    );
    homeMenu = RepaintBoundary(child: homeMenu);
    homeMenu = FocusTraversalGroup(child: homeMenu);
    return homeMenu;
  }

  Widget _buildEditPannel(
      {required HomeState homeState,
      required BuildContext context,
      required HomeLayout layout}) {
    final homeBloc = context.read<HomeBloc>();
    Widget editPannel = EditPannel(
      context: homeState.editContext,
      onEndEdit: () => homeBloc.add(const HomeEvent.dismissEditPannel()),
    );
    // editPannel = RepaintBoundary(child: editPannel);
    // editPannel = FocusTraversalGroup(child: editPannel);
    return editPannel;
  }

  Widget _layoutWidgets(
      {required HomeLayout layout,
      required Widget homeMenu,
      required Widget homePage,
      required Widget editPannel}) {
    return Stack(
      children: [
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
        homePage
            .constrained(minWidth: 500)
            .positioned(
                left: layout.homePageLOffset,
                right: layout.homePageROffset,
                bottom: 0,
                top: 0,
                animate: true)
            .animate(layout.animDuration, Curves.easeOut),
        editPannel
            .animatedPanelX(
              duration: layout.animDuration.inMilliseconds * 0.001,
              closeX: layout.editPannelWidth,
              isClosed: !layout.showEditPannel,
            )
            .positioned(
                right: 0, top: 0, bottom: 0, width: layout.editPannelWidth),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  // final Size size;
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Log.info('HomePage build');
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        getIt<HomePageStack>().stackTopBar(),
        Expanded(
          child: Container(
            color: Colors.white,
            child: FocusTraversalGroup(
              child: getIt<HomePageStack>().stackWidget(),
            ),
          ),
        ),
      ],
    );
  }
}

// class HomeIndexStack extends StatelessWidget {
//   const HomeIndexStack({Key? key}) : super(key: key);
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<HomeBloc, HomeState>(
//       buildWhen: (p, c) {
//         if (p.pageContext != c.pageContext) {
//           Log.info(
//               'PageContext switch from ${p.pageContext.pageType} to ${c.pageContext.pageType}');
//         }
//         return p.pageContext != c.pageContext;
//       },
//       builder: (context, state) {
//         final pageContext = context.read<HomeBloc>().state.pageContext;
//         return Expanded(
//           child: Container(
//             color: Colors.white,
//             child: FocusTraversalGroup(
//               child: getIt<FlowyHomeIndexStack>().indexStack(pageContext),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
