import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/header.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_watch_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'view/view_list.dart';

class AppPageSize {
  static double expandedIconSize = 16;
  static double expandedIconRightSpace = 6;
  static double scale = 1;
  static double get expandedPadding => expandedIconSize * scale + expandedIconRightSpace;
}

class AppPageContext {
  final App app;
  final viewListData = ViewListData();

  AppPageContext(
    this.app,
  );

  Key valueKey() => ValueKey("${app.id}${app.version}");
}

class AppPage extends MenuItem {
  final AppPageContext appCtx;
  AppPage(this.appCtx, {Key? key}) : super(key: appCtx.valueKey());

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
            loadViews: (s) => _renderViewList(s.views),
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

  Widget _renderViewList(List<View>? views) {
    appCtx.viewListData.views = views ?? List.empty(growable: false);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appCtx.viewListData),
      ],
      child: Consumer(builder: (context, ViewListData notifier, child) {
        return ViewListPage(notifier.views).padding(vertical: 8);
      }),
    );
  }

  @override
  MenuItemType get type => MenuItemType.app;
}
