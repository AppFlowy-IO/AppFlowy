import 'dart:math' as math;

import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheet/route.dart';
import 'package:sheet/sheet.dart';

import 'show_mobile_bottom_sheet.dart';

Future<T?> showTransitionMobileBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool useRootNavigator = false,
  EdgeInsets contentPadding = EdgeInsets.zero,
  Color? backgroundColor,
  // drag handle
  bool showDragHandle = false,
  // header
  bool showHeader = false,
  String title = '',
  bool showBackButton = false,
  bool showCloseButton = false,
  bool showDoneButton = false,
  bool showDivider = true,
  // stops
  double initialStop = 1.0,
  List<double>? stops,
}) {
  assert(
    showHeader ||
        title.isEmpty &&
            !showCloseButton &&
            !showBackButton &&
            !showDoneButton &&
            !showDivider,
  );
  assert(!(showCloseButton && showBackButton));

  backgroundColor ??= Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFF7F8FB)
      : const Color(0xFF23262B);

  return Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  ).push<T>(
    TransitionSheetRoute<T>(
      backgroundColor: backgroundColor,
      initialStop: initialStop,
      stops: stops,
      builder: (context) {
        final Widget child = builder(context);

        // if the children is only one, we don't need to wrap it with a column
        if (!showDragHandle && !showHeader) {
          return child;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle) const DragHandle(),
            if (showHeader) ...[
              BottomSheetHeader(
                showCloseButton: showCloseButton,
                showBackButton: showBackButton,
                showDoneButton: showDoneButton,
                showRemoveButton: false,
                title: title,
              ),
              if (showDivider)
                const Divider(
                  height: 0.5,
                  thickness: 0.5,
                ),
            ],
            Expanded(
              child: Padding(
                padding: contentPadding,
                child: child,
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// The top offset that will be displayed from the bottom route
const double _kPreviousRouteVisibleOffset = 10.0;

/// Minimal distance from the top of the screen to the top of the previous route
/// It will be used ff the top safe area is less than this value.
/// In iPhones the top SafeArea is more or equal to this distance.
const double _kSheetMinimalOffset = 10;

const Curve _kCupertinoSheetCurve = Curves.easeOutExpo;
const Curve _kCupertinoTransitionCurve = Curves.linear;

/// Wraps the child into a cupertino modal sheet appearance. This is used to
/// create a [SheetRoute].
///
/// Clip the child widget to rectangle with top rounded corners and adds
/// top padding and top safe area.
class _CupertinoSheetDecorationBuilder extends StatelessWidget {
  const _CupertinoSheetDecorationBuilder({
    required this.child,
    required this.topRadius,
    this.backgroundColor,
  });

  /// The child contained by the modal sheet
  final Widget child;

  /// The color to paint behind the child
  final Color? backgroundColor;

  /// The top corners of this modal sheet are rounded by this Radius
  final Radius topRadius;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: topRadius),
            color: backgroundColor,
          ),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        );
      },
    );
  }
}

/// Customized CupertinoSheetRoute from the sheets package
///
/// A modal route that overlays a widget over the current route and animates
/// it from the bottom with a cupertino modal sheet appearance
///
/// Clip the child widget to rectangle with top rounded corners and adds
/// top padding and top safe area.
class TransitionSheetRoute<T> extends SheetRoute<T> {
  TransitionSheetRoute({
    required WidgetBuilder builder,
    super.stops,
    double initialStop = 1.0,
    super.settings,
    Color? backgroundColor,
    super.maintainState = true,
    super.fit,
  }) : super(
          builder: (BuildContext context) {
            return _CupertinoSheetDecorationBuilder(
              backgroundColor: backgroundColor,
              topRadius: const Radius.circular(16),
              child: Builder(builder: builder),
            );
          },
          animationCurve: _kCupertinoSheetCurve,
          initialExtent: initialStop,
        );

  @override
  bool get draggable => true;

  final SheetController _sheetController = SheetController();

  @override
  SheetController createSheetController() => _sheetController;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  Widget buildSheet(BuildContext context, Widget child) {
    final effectivePhysics = draggable
        ? BouncingSheetPhysics(
            parent: SnapSheetPhysics(
              stops: stops ?? <double>[0, 1],
              parent: physics,
            ),
          )
        : const NeverDraggableSheetPhysics();
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double topMargin =
        math.max(_kSheetMinimalOffset, mediaQuery.padding.top) +
            _kPreviousRouteVisibleOffset;
    return Sheet.raw(
      initialExtent: initialExtent,
      decorationBuilder: decorationBuilder,
      fit: fit,
      maxExtent: mediaQuery.size.height - topMargin,
      physics: effectivePhysics,
      controller: sheetController,
      child: child,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double topOffset = math.max(_kSheetMinimalOffset, topPadding);
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double progress = secondaryAnimation.value;
        final double scale = 1 - progress / 10;
        final double distanceWithScale =
            (topOffset + _kPreviousRouteVisibleOffset) * 0.9;
        final Offset offset =
            Offset(0, progress * (topOffset - distanceWithScale));
        return Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }

  @override
  bool canDriveSecondaryTransitionForPreviousRoute(
    Route<dynamic> previousRoute,
  ) =>
      true;

  @override
  Widget buildSecondaryTransitionForPreviousRoute(
    BuildContext context,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> delayAnimation = CurvedAnimation(
      parent: _sheetController.animation,
      curve: Interval(
        initialExtent == 1 ? 0 : initialExtent,
        1,
      ),
    );

    final Animation<double> secondaryAnimation = CurvedAnimation(
      parent: _sheetController.animation,
      curve: Interval(
        0,
        initialExtent,
      ),
    );

    return CupertinoSheetBottomRouteTransition(
      body: child,
      sheetAnimation: delayAnimation,
      secondaryAnimation: secondaryAnimation,
    );
  }
}

/// Animation for previous route when a [TransitionSheetRoute] enters/exits
@visibleForTesting
class CupertinoSheetBottomRouteTransition extends StatelessWidget {
  const CupertinoSheetBottomRouteTransition({
    super.key,
    required this.sheetAnimation,
    required this.secondaryAnimation,
    required this.body,
  });

  final Widget body;

  final Animation<double> sheetAnimation;
  final Animation<double> secondaryAnimation;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double topOffset = math.max(_kSheetMinimalOffset, topPadding);

    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: sheetAnimation,
      curve: _kCupertinoTransitionCurve,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: AnimatedBuilder(
        animation: secondaryAnimation,
        child: body,
        builder: (BuildContext context, Widget? child) {
          final double progress = curvedAnimation.value;
          final double scale = 1 - progress / 10;
          return Stack(
            children: <Widget>[
              Container(color: Colors.black),
              Transform.translate(
                offset: Offset(0, progress * topOffset),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.lerp(
                        Radius.zero,
                        const Radius.circular(16.0),
                        progress,
                      )!,
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey
                                : Colors.black)
                            .withOpacity(secondaryAnimation.value * 0.1),
                        BlendMode.srcOver,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
