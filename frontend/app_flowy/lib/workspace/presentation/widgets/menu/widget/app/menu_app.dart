import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/header/header.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
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
  late AppDataNotifier notifier;

  @override
  void initState() {
    notifier = AppDataNotifier();
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
      child: BlocSelector<AppBloc, AppState, AppDataNotifier>(
        selector: (state) {
          final menuSharedState = Provider.of<MenuSharedState>(context, listen: false);
          if (state.latestCreatedView != null) {
            menuSharedState.forcedOpenView.value = state.latestCreatedView!;
          }

          notifier.views = state.views;
          notifier.selectedView = menuSharedState.selectedView.value;
          return notifier;
        },
        builder: (context, notifier) => ChangeNotifierProvider.value(
          value: notifier,
          child: Consumer(
            builder: (BuildContext context, AppDataNotifier notifier, Widget? child) {
              return expandableWrapper(context, notifier);
            },
          ),
        ),
      ),
    );
  }

  ExpandableNotifier expandableWrapper(BuildContext context, AppDataNotifier notifier) {
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
              header: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
                builder: (context, state) => MenuAppHeader(widget.app),
              ),
              expanded: _renderViewSection(notifier),
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
        return ViewSection(appData: notifier);
      }),
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

class AppDataNotifier extends ChangeNotifier {
  List<View> _views = [];
  View? _selectedView;
  ExpandableController expandController = ExpandableController(initialExpanded: false);

  AppDataNotifier();

  set selectedView(View? view) {
    _selectedView = view;

    if (view != null && _views.isNotEmpty) {
      final isExpanded = _views.contains(view);
      if (expandController.expanded == false && expandController.expanded != isExpanded) {
        // Workaround: Delay 150 milliseconds to make the smooth animation while expanding
        Future.delayed(const Duration(milliseconds: 150), () {
          expandController.expanded = isExpanded;
        });
      }
    }
  }

  View? get selectedView => _selectedView;

  set views(List<View>? views) {
    if (views == null) {
      if (_views.isNotEmpty) {
        _views = List.empty(growable: false);
        notifyListeners();
      }
      return;
    }

    if (_views != views) {
      _views = views;
      notifyListeners();
    }
  }

  List<View> get views => _views;
}
