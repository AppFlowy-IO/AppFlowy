import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_watch_bloc.dart';
import 'package:app_flowy/workspace/presentation/app/view_list.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu_list.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/text_button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

class AppWidgetSize {
  static double expandedIconSize = 24;
  static double expandedIconRightSpace = 8;
  static double scale = 1;
  static double get expandedPadding =>
      expandedIconSize * scale + expandedIconRightSpace;
}

class AppWidgetContext {
  final App app;

  AppWidgetContext(this.app);

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
    List<View> views = some.fold(
      () => List.empty(growable: true),
      (views) => views,
    );

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ViewList(views));
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            ExpandableController.of(context,
                    rebuildOnChange: false, required: true)
                ?.toggle();
          },
          child: ExpandableIcon(
            theme: ExpandableThemeData(
              expandIcon: Icons.arrow_drop_up,
              collapseIcon: Icons.arrow_drop_down,
              iconColor: Colors.black,
              iconSize: AppWidgetSize.expandedIconSize,
              iconPadding: EdgeInsets.zero,
              hasIcon: false,
            ),
          ),
        ),
        HSpace(AppWidgetSize.expandedIconRightSpace),
        Expanded(
          child: FlowyTextButton(
            app.name,
            onPressed: () {
              debugPrint('show app document');
            },
          ),
        ),
        // StyledIconButton(
        //   icon: const Icon(Icons.add),
        //   onPressed: () {
        //     debugPrint('add view');
        //   },
        // ),
        PopupMenuButton(
            iconSize: 20,
            tooltip: 'create new view',
            icon: const Icon(Icons.add),
            padding: EdgeInsets.zero,
            onSelected: (viewType) =>
                _createView(viewType as ViewType, context),
            itemBuilder: (context) => menuItemBuilder())
      ],
    );
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
