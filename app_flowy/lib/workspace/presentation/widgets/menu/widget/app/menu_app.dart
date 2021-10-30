import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/header/header.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'section/section.dart';

class MenuApp extends MenuItem {
  final App app;
  final notifier = AppDataNotifier();

  MenuApp(this.app, {Key? key}) : super(key: ValueKey("${app.id}${app.version}"));

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) {
            final appBloc = getIt<AppBloc>(param1: app.id);
            appBloc.add(const AppEvent.initial());
            return appBloc;
          },
        ),
      ],
      child: BlocListener<AppBloc, AppState>(
        listenWhen: (p, c) => p.selectedView != c.selectedView,
        listener: (context, state) => notifier.selectView = state.selectedView,
        child: BlocBuilder<AppBloc, AppState>(
          buildWhen: (p, c) => p.views != c.views,
          builder: (context, state) {
            notifier.views = state.views;
            return expandableWrapper(context, _renderViewSection(notifier));
          },
        ),
      ),
    );
  }

  ExpandableNotifier expandableWrapper(BuildContext context, Widget child) {
    return ExpandableNotifier(
      child: ScrollOnExpand(
        scrollOnExpand: false,
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
              header: MenuAppHeader(app),
              expanded: child,
              collapsed: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderViewSection(AppDataNotifier viewListNotifier) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: viewListNotifier)],
      child: Consumer(builder: (context, AppDataNotifier notifier, child) {
        return const ViewSection().padding(vertical: 8);
      }),
    );
  }

  @override
  MenuItemType get type => MenuItemType.app;
}

class MenuAppSizes {
  static double iconSize = 16;
  static double headerHeight = 26;
  static double headerPadding = 6;
  static double iconPadding = 6;
  static double appVPadding = 14;
  static double scale = 1;
  static double get expandedPadding => iconSize * scale + headerPadding;
}

class AppDataNotifier extends ChangeNotifier {
  List<View> _views = [];
  View? _selectedView;
  AppDataNotifier();

  set views(List<View>? items) {
    _views = items ?? List.empty(growable: false);
    notifyListeners();
  }

  set selectView(View? view) {
    _selectedView = view;
    notifyListeners();
  }

  get selectedView => _selectedView;

  List<View> get views => _views;
}
