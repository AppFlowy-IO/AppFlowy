import 'package:appflowy_ui/src/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppFlowyTheme extends StatelessWidget {
  const AppFlowyTheme({
    super.key,
    required this.data,
    required this.child,
  });

  final AppFlowyThemeData data;
  final Widget child;

  static AppFlowyThemeData of(BuildContext context, {bool listen = true}) {
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

  static AppFlowyThemeData? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<AppFlowyInheritedTheme>()
          ?.theme
          .data;
    }
    final provider = context
        .getElementForInheritedWidgetOfExactType<AppFlowyInheritedTheme>()
        ?.widget;

    return (provider as AppFlowyInheritedTheme?)?.theme.data;
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyInheritedTheme(
      theme: this,
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

  final AppFlowyTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) {
    return AppFlowyTheme(data: theme.data, child: child);
  }

  @override
  bool updateShouldNotify(AppFlowyInheritedTheme oldWidget) =>
      theme.data != oldWidget.theme.data;
}

/// An interpolation between two [ThemeData]s.
///
/// This class specializes the interpolation of [Tween<ThemeData>] to call the
/// [ThemeData.lerp] method.
///
/// See [Tween] for a discussion on how to use interpolation objects.
class AppFlowyThemeDataTween extends Tween<AppFlowyThemeData> {
  /// Creates a [AppFlowyThemeData] tween.
  ///
  /// The [begin] and [end] properties must be non-null before the tween is
  /// first used, but the arguments can be null if the values are going to be
  /// filled in later.
  AppFlowyThemeDataTween({super.begin, super.end});

  @override
  AppFlowyThemeData lerp(double t) => AppFlowyThemeData.lerp(begin!, end!, t);
}

class AnimatedAppFlowyTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme.
  ///
  /// By default, the theme transition uses a linear curve.
  const AnimatedAppFlowyTheme({
    super.key,
    required this.data,
    super.curve,
    super.duration = kThemeAnimationDuration,
    super.onEnd,
    required this.child,
  });

  /// Specifies the color and typography values for descendant widgets.
  final AppFlowyThemeData data;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedAppFlowyTheme> createState() =>
      _AnimatedThemeState();
}

class _AnimatedThemeState
    extends AnimatedWidgetBaseState<AnimatedAppFlowyTheme> {
  AppFlowyThemeDataTween? data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    data = visitor(
      data,
      widget.data,
      (dynamic value) =>
          AppFlowyThemeDataTween(begin: value as AppFlowyThemeData),
    )! as AppFlowyThemeDataTween;
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyTheme(
      data: data!.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(
      DiagnosticsProperty<AppFlowyThemeDataTween>(
        'data',
        data,
        showName: false,
        defaultValue: null,
      ),
    );
  }
}
