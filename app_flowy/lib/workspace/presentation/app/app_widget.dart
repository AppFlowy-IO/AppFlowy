import 'package:dartz/dartz.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_watch_bloc.dart';
import 'package:app_flowy/workspace/presentation/app/view_list.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:provider/provider.dart';
import 'app_header.dart';

class AppWidgetSize {
  static double expandedIconSize = 24;
  static double expandedIconRightSpace = 8;
  static double scale = 1;
  static double get expandedPadding =>
      expandedIconSize * scale + expandedIconRightSpace;
}

class ViewListData extends ChangeNotifier {
  List<View>? innerViews;
  ViewListData();

  set views(List<View> views) {
    innerViews = views;
    notifyListeners();
  }

  List<View> get views => innerViews ?? [];
}

class AppWidgetContext {
  final App app;
  final viewListData = ViewListData();

  AppWidgetContext(
    this.app,
  );

  Key valueKey() => ValueKey("${app.id}${app.version}");
}

class AppWidget extends MenuItem {
  final AppWidgetContext appCtx;
  AppWidget(this.appCtx, {Key? key}) : super(key: appCtx.valueKey());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(create: (context) {
          final appBloc = getIt<AppBloc>(param1: appCtx.app.id);
          appBloc.add(const AppEvent.initial());
          return appBloc;
        }),
        BlocProvider<AppWatchBloc>(create: (context) {
          final watchBloc = getIt<AppWatchBloc>(param1: appCtx.app.id);
          watchBloc.add(const AppWatchEvent.started());
          return watchBloc;
        }),
      ],
      child: BlocBuilder<AppWatchBloc, AppWatchState>(
        builder: (context, state) {
          final child = state.map(
            initial: (_) => BlocBuilder<AppBloc, AppState>(
              builder: (context, state) => _renderViewList(state.views),
            ),
            loadViews: (s) => _renderViewList(some(s.views)),
            loadFail: (s) => FlowyErrorPage(s.error.toString()),
          );

          return expandableWrapper(context, child);
        },
      ),
    );
  }

  ExpandableNotifier expandableWrapper(BuildContext context, Widget child) {
    return ExpandableNotifier(
      child: ScrollOnExpand(
        scrollOnExpand: true,
        scrollOnCollapse: false,
        child: Column(
          children: <Widget>[
            ExpandablePanel(
              theme: const ExpandableThemeData(
                headerAlignment: ExpandablePanelHeaderAlignment.center,
                tapBodyToExpand: false,
                tapBodyToCollapse: false,
                tapHeaderToExpand: false,
                iconPadding: EdgeInsets.zero,
                hasIcon: false,
              ),
              header: AppHeader(appCtx.app),
              expanded: child,
              collapsed: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderViewList(Option<List<View>> some) {
    some.fold(
      () {
        appCtx.viewListData.views = List.empty(growable: true);
      },
      (views) {
        appCtx.viewListData.views = views;
      },
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appCtx.viewListData),
      ],
      child: Consumer(builder: (context, ViewListData notifier, child) {
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ViewList(notifier.views));
      }),
    );
  }

  @override
  MenuItemType get type => MenuItemType.app;
}
