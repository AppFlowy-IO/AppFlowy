import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_watch_bloc.dart';
import 'package:app_flowy/workspace/presentation/app/view_list.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_size.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

class AppWidget extends MenuItem {
  final App app;
  const AppWidget(this.app, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(create: (context) {
          final appBloc = getIt<AppBloc>(param1: app.id);
          appBloc.add(const AppEvent.initial());
          return appBloc;
        }),
        BlocProvider<AppWatchBloc>(create: (context) {
          final watchBloc = getIt<AppWatchBloc>(param1: app.id);
          watchBloc.add(const AppWatchEvent.started());
          return watchBloc;
        }),
      ],
      child: BlocBuilder<AppWatchBloc, AppWatchState>(
        builder: (context, state) {
          final child = state.map(
            initial: (_) => BlocBuilder<AppBloc, AppState>(
              builder: (context, state) {
                return ViewList(state.views);
              },
            ),
            loadViews: (s) => ViewList(some(s.views)),
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
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              ExpandablePanel(
                theme: const ExpandableThemeData(
                  headerAlignment: ExpandablePanelHeaderAlignment.center,
                  tapBodyToExpand: false,
                  tapBodyToCollapse: false,
                  iconPadding: EdgeInsets.zero,
                  hasIcon: false,
                ),
                header: AppHeader(app),
                expanded: Padding(
                  padding: EdgeInsets.only(left: Sizes.iconMed),
                  child: child,
                ),
                collapsed: const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  MenuItemType get type => MenuItemType.app;
}

class AppHeader extends StatelessWidget {
  final App app;
  const AppHeader(
    this.app, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Insets.m),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExpandableIcon(
              theme: ExpandableThemeData(
                expandIcon: Icons.arrow_right,
                collapseIcon: Icons.arrow_drop_down,
                iconColor: Colors.black,
                iconSize: HomeMenuSize.collapseIconSize,
                iconPadding: EdgeInsets.zero,
                hasIcon: false,
              ),
            ),
            Expanded(
              child: Text(app.name),
            ),
            SizedBox(
              height: HomeMenuSize.createViewButtonSize,
              child: createViewPopupMenu(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget createViewPopupMenu(BuildContext context) {
    return PopupMenuButton(
        iconSize: 24,
        tooltip: 'create new view',
        icon: const Icon(Icons.add),
        padding: EdgeInsets.zero,
        onSelected: (viewType) => _createView(viewType as ViewType, context),
        itemBuilder: (context) => menuItemBuilder());
  }

  List<PopupMenuEntry> menuItemBuilder() {
    return ViewType.values
        .where((element) => element != ViewType.Blank)
        .map((ty) {
      return PopupMenuItem<ViewType>(
          value: ty,
          child: Row(
            children: <Widget>[Text(ty.name)],
          ));
    }).toList();
  }

  void _createView(ViewType viewType, BuildContext context) {
    context.read<AppBloc>().add(AppEvent.createView("New view", "", viewType));
  }
}
