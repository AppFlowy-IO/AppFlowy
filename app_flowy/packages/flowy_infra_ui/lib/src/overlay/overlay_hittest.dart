import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class OverlayHitTestArea extends SingleChildRenderObjectWidget {
  const OverlayHitTestArea({
    Key? key,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) => RenderOverlayHitTestArea();
}

class RenderOverlayHitTestArea extends RenderBox with RenderObjectWithChildMixin<RenderBox> {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    print('hitTesting');
    return super.hitTest(result, position: position);
  }
}
