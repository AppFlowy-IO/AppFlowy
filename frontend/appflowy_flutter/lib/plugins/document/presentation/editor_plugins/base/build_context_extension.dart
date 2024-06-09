import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension BuildContextExtension on BuildContext {
  /// returns a boolean value indicating whether the given offset is contained within the bounds of the specified RenderBox or not.
  bool isOffsetInside(Offset offset) {
    final box = findRenderObject() as RenderBox?;
    if (box == null) {
      return false;
    }
    final result = BoxHitTestResult();
    box.hitTest(result, position: box.globalToLocal(offset));
    return result.path.any((entry) => entry.target == box);
  }

  double get appBarHeight =>
      AppBarTheme.of(this).toolbarHeight ?? kToolbarHeight;
  double get statusBarHeight => statusBarAndAppBarHeight - appBarHeight;
  double get statusBarAndAppBarHeight => MediaQuery.of(this).padding.top;
}
