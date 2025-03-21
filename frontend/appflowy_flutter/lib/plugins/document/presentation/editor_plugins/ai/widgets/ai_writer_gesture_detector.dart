import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AiWriterGestureDetector extends StatelessWidget {
  const AiWriterGestureDetector({
    super.key,
    required this.behavior,
    required this.onPointerEvent,
    this.child,
  });

  final HitTestBehavior behavior;
  final void Function() onPointerEvent;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: behavior,
      gestures: <Type, GestureRecognizerFactory>{
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (instance) => instance
            ..onTapDown = ((_) => onPointerEvent())
            ..onSecondaryTapDown = ((_) => onPointerEvent())
            ..onTertiaryTapDown = ((_) => onPointerEvent()),
        ),
        ImmediateMultiDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                ImmediateMultiDragGestureRecognizer>(
          () => ImmediateMultiDragGestureRecognizer(),
          (instance) => instance.onStart = (offset) => null,
        ),
      },
      child: child,
    );
  }
}
