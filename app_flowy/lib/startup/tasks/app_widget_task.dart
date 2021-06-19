import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_style/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_size/window_size.dart';
import 'package:app_flowy/startup/launch.dart';

class AppWidgetTask extends LaunchTask {
  @override
  LaunchTaskType get type => LaunchTaskType.appLauncher;

  @override
  void initialize(LaunchContext context) {
    final widget = context.getIt<AppFactory>().create();
    final app = AppWidget(child: widget);
    runApp(app);
  }
}

class AppWidget extends StatelessWidget {
  final Widget child;
  const AppWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    setWindowMinSize(const Size(500, 500));

    final theme = AppTheme.fromType(ThemeType.light);
    return Provider.value(
        value: theme,
        child: MaterialApp(
          title: 'AppFlowy',
          debugShowCheckedModeBanner: false,
          theme: theme.themeData,
          navigatorKey: AppGlobals.rootNavKey,
          home: child,
        ));
  }
}

class AppGlobals {
  static GlobalKey<NavigatorState> rootNavKey = GlobalKey();
  static NavigatorState get nav => rootNavKey.currentState!;
}
