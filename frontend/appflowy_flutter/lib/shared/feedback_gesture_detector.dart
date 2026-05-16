import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  vibrate;

  void call() {
    switch (this) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }
}

class FeedbackGestureDetector extends GestureDetector {
  FeedbackGestureDetector({
    super.key,
    HitTestBehavior behavior = HitTestBehavior.opaque,
    HapticFeedbackType feedbackType = HapticFeedbackType.light,
    required Widget child,
    required VoidCallback onTap,
  }) : super(
          behavior: behavior,
          onTap: () {
            feedbackType.call();
            onTap();
          },
          child: child,
        );
}
