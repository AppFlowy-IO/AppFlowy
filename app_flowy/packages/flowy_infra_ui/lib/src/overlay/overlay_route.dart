import 'package:flowy_infra_ui/src/overlay/overlay_pannel.dart';
import 'package:flutter/material.dart';

import 'overlay_basis.dart';
import 'overlay_layout_delegate.dart';

class _OverlayRouteResult {}

const Duration _kOverlayDurationDuration = Duration(milliseconds: 500);

class OverlayPannelRoute extends PopupRoute<_OverlayRouteResult> {
  final EdgeInsetsGeometry padding;
  final AnchorDirection anchorDirection;
  final Offset anchorPosition;
  final double maxWidth;
  final double maxHeight;
  final WidgetBuilder widgetBuilder;

  OverlayPannelRoute({
    this.padding = EdgeInsets.zero,
    required this.anchorDirection,
    this.barrierColor,
    required this.barrierLabel,
    required this.anchorPosition,
    required this.maxWidth,
    required this.maxHeight,
    required this.widgetBuilder,
  });

  @override
  bool get barrierDismissible => true;

  @override
  Color? barrierColor;

  @override
  String? barrierLabel;

  @override
  Duration get transitionDuration => _kOverlayDurationDuration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return LayoutBuilder(builder: (context, contraints) {
      return _OverlayRoutePage(
        route: this,
        anchorDirection: anchorDirection,
        anchorPosition: anchorPosition,
      );
    });
  }
}

class _OverlayRoutePage extends StatelessWidget {
  const _OverlayRoutePage({
    Key? key,
    required this.route,
    this.padding = EdgeInsets.zero,
    required this.anchorDirection,
    required this.anchorPosition,
  }) : super(key: key);

  final OverlayPannelRoute route;
  final EdgeInsetsGeometry padding;
  final AnchorDirection anchorDirection;
  final Offset anchorPosition;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final TextDirection? textDirection = Directionality.maybeOf(context);
    final OverlayPannel overlayPannel = OverlayPannel(
      route: route,
      padding: padding,
      anchorDirection: anchorDirection,
      anchorPosition: anchorPosition,
    );

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: true,
      removeRight: true,
      child: Builder(
        builder: (context) => CustomSingleChildLayout(
          delegate: OverlayLayoutDelegate(
            route: route,
            padding: padding.resolve(textDirection),
            anchorPosition: anchorPosition,
            anchorDirection: anchorDirection,
          ),
          child: overlayPannel,
        ),
      ),
    );
  }
}
