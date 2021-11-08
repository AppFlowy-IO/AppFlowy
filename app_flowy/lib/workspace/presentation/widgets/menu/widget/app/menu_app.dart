import 'package:app_flowy/workspace/presentation/widgets/menu/menu.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/header/header.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'section/section.dart';

class MenuApp extends StatefulWidget {
  final App app;
  MenuApp(this.app, {Key? key}) : super(key: ValueKey("${app.id}${app.version}"));

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  final notifier = AppDataNotifier();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) {
            final appBloc = getIt<AppBloc>(param1: widget.app);
            appBloc.add(const AppEvent.initial());
            return appBloc;
          },
        ),
      ],
      child: BlocSelector<AppBloc, AppState, AppDataNotifier>(
        selector: (state) {
          if (state.latestCreatedView != null) {
            Provider.of<MenuSharedState>(context, listen: false).forcedOpenView = state.latestCreatedView;
          }
          notifier.views = state.views;
          return notifier;
        },
        builder: (context, state) {
          return expandableWrapper(context, _renderViewSection(state));
        },
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
              header: MenuAppHeader(widget.app),
              expanded: child,
              collapsed: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderViewSection(AppDataNotifier notifier) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: notifier)],
      child: Consumer(builder: (context, AppDataNotifier notifier, child) {
        return const ViewSection().padding(vertical: 8);
      }),
    );
  }
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
  AppDataNotifier();

  set views(List<View>? items) {
    if (items == null) {
      if (_views.isNotEmpty) {
        _views = List.empty(growable: false);
        notifyListeners();
      }
      return;
    }

    if (_views != items) {
      _views = items;
      notifyListeners();
    }
  }

  List<View> get views => _views;
}
