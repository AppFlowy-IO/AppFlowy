import 'package:app_flowy/home/application/home_bloc.dart';
import 'package:app_flowy/home/application/watcher/home_watcher_bloc.dart';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:app_flowy/home/presentation/widgets/blank_page.dart';
import 'package:app_flowy/home/presentation/widgets/edit_pannel/edit_pannel.dart';
import 'package:app_flowy/home/presentation/widgets/edit_pannel/pannel_animation.dart';
import 'package:app_flowy/home/presentation/widgets/home_top_bar.dart';
import 'package:app_flowy/home/presentation/widgets/menu/home_menu.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_infra_ui/styles/styled_container.dart';
import 'package:flowy_logger/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/user_detail.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'home_layout.dart';
import 'widgets/fading_index_stack.dart';

class HomeScreen extends StatelessWidget {
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final UserDetail userDetail;
  const HomeScreen(this.userDetail, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeWatcherBloc>(
            create: (context) => getIt<HomeWatcherBloc>()),
        BlocProvider<HomeBloc>(create: (context) => getIt<HomeBloc>()),
      ],
      child: Scaffold(
        key: HomeScreen.scaffoldKey,
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return StyledContainer(
              Theme.of(context).colorScheme.background,
              child: _buildBody(state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(HomeState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final layout = HomeLayout(context, constraints);
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
        pageContext.fold(
          () => homeBloc.add(const HomeEvent.setPage(BlankPageContext())),
          (pageContext) {
            homeBloc.add(HomeEvent.setPage(pageContext));
          },
        );
      },
      isCollapseChanged: (isCollapse) {
        homeBloc.add(HomeEvent.showMenu(!isCollapse));
      },
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

extension PageTypeExtension on PageType {
  HomeStackPage builder(PageContext context) {
    switch (this) {
      case PageType.blank:
        return BlankPage(context: context);
    }
  }
}

List<Widget> buildPagesWidget(PageContext pageContext) {
  return PageType.values.map((pageType) {
    if (pageType == pageContext.pageType) {
      return pageType.builder(pageContext);
    } else {
      return const BlankPage(context: BlankPageContext());
    }
  }).toList();
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
      children: const [
        HomeTopBar(),
        HomeIndexStack(),
      ],
    );
  }
}

class HomeIndexStack extends StatelessWidget {
  const HomeIndexStack({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      buildWhen: (p, c) {
        if (p.pageContext != c.pageContext) {
          Log.info(
              'PageContext switch from ${p.pageContext.pageType} to ${c.pageContext.pageType}');
        }
        return p.pageContext != c.pageContext;
      },
      builder: (context, state) {
        final pageContext = context.read<HomeBloc>().state.pageContext;
        return Expanded(
          child: Container(
            color: Colors.white,
            child: FocusTraversalGroup(
              child: FadingIndexedStack(
                index: pages.indexOf(pageContext.pageType),
                children: buildPagesWidget(pageContext),
              ),
            ),
          ),
        );
      },
    );
  }
}
