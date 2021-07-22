import 'package:app_flowy/home/application/app/app_bloc.dart';
import 'package:app_flowy/home/application/app/app_watch_bloc.dart';
import 'package:app_flowy/home/presentation/widgets/menu/menu_size.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppWidget extends StatelessWidget {
  final App app;
  const AppWidget(this.app, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
            create: (context) => getIt<AppBloc>(param1: app.id)),
        BlocProvider<AppWatchBloc>(
            create: (context) => getIt<AppWatchBloc>(param1: app.id)),
      ],
      child: BlocBuilder<AppWatchBloc, AppWatchState>(
        builder: (context, state) {
          final child = state.map(
            initial: (_) => BlocBuilder<AppBloc, AppState>(
              builder: (context, state) {
                return Container();
              },
            ),
            loadViews: (s) {
              return Container();
              // final child = state.map(
              //   initial: (_) => const CircularProgressIndicator.adaptive(),
              //   loadViews: (s) => ViewList(s.views),
              //   successOrFailure: (s) => FlowyErrorPage(s.error),
              // );

              // return expandableWrapper(context, Container());
            },
            loadFail: (s) {
              return FlowyErrorPage(s.error.toString());
            },
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
                collapsed: const Text("close"),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        onSelected: (viewType) =>
            handleCreateView(viewType as ViewType, context),
        itemBuilder: (context) => menuItemBuilder());
  }

  List<PopupMenuEntry> menuItemBuilder() {
    return ViewType.values
        // .where((element) => element != ViewType.ViewTypeUnknown)
        .map((ty) {
      return PopupMenuItem<ViewType>(
          value: ty,
          child: Row(
            children: <Widget>[Text(ty.name)],
          ));
    }).toList();
  }

  void handleCreateView(ViewType viewType, BuildContext context) {
    switch (viewType) {
      case ViewType.Docs:
        // context
        //     .read<AppEditBloc>()
        //     .add(AppEditEvent.createView(app.id, 'Grid View'));
        break;
    }
  }
}
