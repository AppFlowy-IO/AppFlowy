import 'package:appflowy_ui/src/theme/definition/base_theme.dart';
import 'package:flutter/widgets.dart';

class AppFlowyTheme extends StatelessWidget {
  const AppFlowyTheme({
    super.key,
    required this.data,
    required this.child,
  });

  final AppFlowyBaseThemeData data;
  final Widget child;

  static AppFlowyBaseThemeData of(BuildContext context, {bool listen = true}) {
    final provider = maybeOf(context, listen: listen);
    if (provider == null) {
      throw FlutterError(
        '''
        AppFlowyTheme.of() called with a context that does not contain a AppFlowyTheme.\n
        No AppFlowyTheme ancestor could be found starting from the context that was passed to AppFlowyTheme.of().
        This can happen because you do not have a AppFlowyTheme widget (which introduces a AppFlowyTheme),
        or it can happen if the context you use comes from a widget above this widget.\n
        The context used was: $context''',
      );
    }
    return provider;
  }

  static AppFlowyBaseThemeData? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<AppFlowyInheritedTheme>()
          ?.theme;
    }
    final provider = context
        .getElementForInheritedWidgetOfExactType<AppFlowyInheritedTheme>()
        ?.widget;

    return (provider as AppFlowyInheritedTheme?)?.theme;
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyInheritedTheme(
      theme: data,
      child: child,
    );
  }
}

class AppFlowyInheritedTheme extends InheritedTheme {
  const AppFlowyInheritedTheme({
    super.key,
    required this.theme,
    required super.child,
  });

  final AppFlowyBaseThemeData theme;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AppFlowyTheme(data: theme, child: child);
  }

  @override
  bool updateShouldNotify(AppFlowyInheritedTheme oldWidget) =>
      theme != oldWidget.theme;
}
