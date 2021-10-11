import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/header.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_listen_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'section/section.dart';

class MenuAppSizes {
  static double expandedIconSize = 16;
  static double expandedIconPadding = 6;
  static double scale = 1;
  static double get expandedPadding => expandedIconSize * scale + expandedIconPadding;
}

class MenuAppContext {
  final App app;
  final viewListData = ViewSectionData();

  MenuAppContext(this.app);

  Key valueKey() => ValueKey("${app.id}${app.version}");
}

class MenuApp extends MenuItem {
  final MenuAppContext appCtx;
  MenuApp(this.appCtx, {Key? key}) : super(key: appCtx.valueKey());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(create: (context) {
          final appBloc = getIt<AppBloc>(param1: appCtx.app.id);
          appBloc.add(const AppEvent.initial());
          return appBloc;
        }),
        BlocProvider<AppListenBloc>(create: (context) {
          final watchBloc = getIt<AppListenBloc>(param1: appCtx.app.id);
          watchBloc.add(const AppListenEvent.started());
          return watchBloc;
        }),
      ],
      child: BlocBuilder<AppListenBloc, AppListenState>(
        builder: (context, state) {
          final child = state.map(
            initial: (_) => BlocBuilder<AppBloc, AppState>(
              builder: (context, state) => _renderViewSection(state.views),
            ),
            loadViews: (s) => _renderViewSection(s.views),
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
              header: MenuAppHeader(appCtx.app),
              expanded: child,
              collapsed: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderViewSection(List<View>? views) {
    appCtx.viewListData.views = views ?? List.empty(growable: false);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appCtx.viewListData),
      ],
      child: Consumer(builder: (context, ViewSectionData notifier, child) {
        return ViewSection(notifier.views).padding(vertical: 8);
      }),
    );
  }

  @override
  MenuItemType get type => MenuItemType.app;
}
