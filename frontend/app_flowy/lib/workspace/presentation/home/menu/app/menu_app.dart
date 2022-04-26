import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:provider/provider.dart';
import 'section/section.dart';

class MenuApp extends StatefulWidget {
  final App app;
  MenuApp(this.app, {Key? key}) : super(key: ValueKey(app.hashCode));

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  late AppViewDataNotifier notifier;

  @override
  void initState() {
    notifier = AppViewDataNotifier();
    super.initState();
  }

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
      child: MultiBlocListener(
        listeners: [
          BlocListener<AppBloc, AppState>(
            listenWhen: (p, c) => p.latestCreatedView != c.latestCreatedView,
            listener: (context, state) => getIt<MenuSharedState>().latestOpenView = state.latestCreatedView,
          ),
          BlocListener<AppBloc, AppState>(
            listenWhen: (p, c) => p.views != c.views,
            listener: (context, state) => notifier.views = state.views,
          ),
        ],
        child: BlocBuilder<AppBloc, AppState>(
          builder: (context, state) {
            return ChangeNotifierProvider.value(
              value: notifier,
              child: Consumer<AppViewDataNotifier>(
                builder: (context, notifier, _) {
                  return expandableWrapper(context, notifier);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  ExpandableNotifier expandableWrapper(BuildContext context, AppViewDataNotifier notifier) {
    return ExpandableNotifier(
      controller: notifier.expandController,
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
              header: ChangeNotifierProvider.value(
                value: Provider.of<AppearanceSettingModel>(context, listen: true),
                child: MenuAppHeader(widget.app),
              ),
              expanded: _renderViewSection(notifier),
              collapsed: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderViewSection(AppViewDataNotifier notifier) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: notifier)],
      child: Consumer(
        builder: (context, AppViewDataNotifier notifier, child) {
          return ViewSection(appData: notifier);
        },
      ),
    );
  }

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
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
