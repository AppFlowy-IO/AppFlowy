import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:provider/provider.dart';
import 'section/section.dart';

class MenuApp extends StatefulWidget {
  final ViewPB view;
  const MenuApp(this.view, {Key? key}) : super(key: key);

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  late AppViewDataContext viewDataContext;

  @override
  void initState() {
    viewDataContext = AppViewDataContext(viewId: widget.view.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>(
          create: (context) {
            final appBloc = AppBloc(view: widget.view);
            appBloc.add(const AppEvent.initial());
            return appBloc;
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AppBloc, AppState>(
            listenWhen: (p, c) => p.latestCreatedView != c.latestCreatedView,
            listener: (context, state) {
              if (state.latestCreatedView != null) {
                getIt<MenuSharedState>().latestOpenView =
                    state.latestCreatedView;
              }
            },
          ),
          BlocListener<AppBloc, AppState>(
            listener: (context, state) => viewDataContext.views = state.views,
          ),
        ],
        child: BlocBuilder<AppBloc, AppState>(
          builder: (context, state) {
            return ChangeNotifierProvider.value(
              value: viewDataContext,
              child: Consumer<AppViewDataContext>(
                builder: (context, viewDataContext, _) {
                  return expandableWrapper(context, viewDataContext);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  ExpandableNotifier expandableWrapper(
    BuildContext context,
    AppViewDataContext viewDataContext,
  ) {
    return ExpandableNotifier(
      controller: viewDataContext.expandController,
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
              header: MenuAppHeader(widget.view),
              expanded: ViewSection(appViewData: viewDataContext),
              collapsed: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MenuApp oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    viewDataContext.dispose();
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
