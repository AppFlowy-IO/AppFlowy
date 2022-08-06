import 'package:flutter/widgets.dart';

import '../transitions.dart';

mixin ReorderFlexMinxi {
  @protected
  Widget makeAppearingWidget(
    Widget child,
    AnimationController animationController,
    Size? draggingFeedbackSize,
    Axis direction,
  ) {
    final sizeFactor = animationController.withLinearCurve();
    if (null == draggingFeedbackSize) {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: sizeFactor,
        axis: direction,
        child: FadeTransition(
          opacity: sizeFactor,
          child: child,
        ),
      );
    } else {
      var transition = SizeTransition(
        sizeFactor: sizeFactor,
        axis: direction,
        child: FadeTransition(opacity: animationController, child: child),
      );

      BoxConstraints contentSizeConstraints = BoxConstraints.loose(draggingFeedbackSize);
      return ConstrainedBox(constraints: contentSizeConstraints, child: transition);
    }
  }

  @protected
  Widget makeDisappearingWidget(
    Widget child,
    AnimationController animationController,
    Size? draggingFeedbackSize,
    Axis direction,
  ) {
    final sizeFactor = animationController.withLinearCurve();
    if (null == draggingFeedbackSize) {
      return SizeTransitionWithIntrinsicSize(
        sizeFactor: sizeFactor,
        axis: direction,
        child: FadeTransition(
          opacity: sizeFactor,
          child: child,
        ),
      );
    } else {
      var transition = SizeTransition(
        sizeFactor: sizeFactor,
        axis: direction,
        child: FadeTransition(opacity: animationController, child: child),
      );

      BoxConstraints contentSizeConstraints = BoxConstraints.loose(draggingFeedbackSize);
      return ConstrainedBox(constraints: contentSizeConstraints, child: transition);
    }
  }
}

Animation<double> withCurve(AnimationController animationController, Cubic curve) {
  return CurvedAnimation(
    parent: animationController,
    curve: curve,
  );
}

extension CurveAnimationController on AnimationController {
  Animation<double> withLinearCurve() {
    return withCurve(Curves.linear);
  }

  Animation<double> withCurve(Curve curve) {
    return CurvedAnimation(
      parent: this,
      curve: curve,
    );
  }
}
