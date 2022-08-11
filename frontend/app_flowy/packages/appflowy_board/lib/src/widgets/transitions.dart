import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

class SizeTransitionWithIntrinsicSize extends SingleChildRenderObjectWidget {
  /// Creates a size transition with its intrinsic width/height taking [sizeFactor]
  /// into account.
  ///
  /// The [axis] argument defaults to [Axis.vertical].
  /// The [axisAlignment] defaults to 0.0, which centers the child along the
  ///  main axis during the transition.
  SizeTransitionWithIntrinsicSize({
    this.axis = Axis.vertical,
    required this.sizeFactor,
    double axisAlignment = 0.0,
    Widget? child,
    Key? key,
  }) : super(
            key: key,
            child: SizeTransition(
              axis: axis,
              sizeFactor: sizeFactor,
              axisAlignment: axisAlignment,
              child: child,
            ));

  final Axis axis;
  final Animation<double> sizeFactor;

  @override
  RenderSizeTransitionWithIntrinsicSize createRenderObject(
      BuildContext context) {
    return RenderSizeTransitionWithIntrinsicSize(
      axis: axis,
      sizeFactor: sizeFactor,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      RenderSizeTransitionWithIntrinsicSize renderObject) {
    renderObject
      ..axis = axis
      ..sizeFactor = sizeFactor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Axis>('axis', axis));
    properties
        .add(DiagnosticsProperty<Animation<double>>('sizeFactor', sizeFactor));
  }
}

class RenderSizeTransitionWithIntrinsicSize extends RenderProxyBox {
  Axis axis;
  Animation<double> sizeFactor;

  RenderSizeTransitionWithIntrinsicSize({
    this.axis = Axis.vertical,
    required this.sizeFactor,
    RenderBox? child,
  }) : super(child);

  @override
  double computeMinIntrinsicWidth(double height) {
    final child = this.child;
    if (child != null) {
      double childWidth = child.getMinIntrinsicWidth(height);
      return axis == Axis.horizontal
          ? childWidth * sizeFactor.value
          : childWidth;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final child = this.child;
    if (child != null) {
      double childWidth = child.getMaxIntrinsicWidth(height);
      return axis == Axis.horizontal
          ? childWidth * sizeFactor.value
          : childWidth;
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final child = this.child;
    if (child != null) {
      double childHeight = child.getMinIntrinsicHeight(width);
      return axis == Axis.vertical
          ? childHeight * sizeFactor.value
          : childHeight;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final child = this.child;
    if (child != null) {
      double childHeight = child.getMaxIntrinsicHeight(width);
      return axis == Axis.vertical
          ? childHeight * sizeFactor.value
          : childHeight;
    }
    return 0.0;
  }
}
