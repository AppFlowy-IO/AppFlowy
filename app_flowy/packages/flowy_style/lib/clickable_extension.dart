import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

extension ClickableExtensions on Widget {
  Widget clickable(void Function() action, {bool opaque = true}) {
    return GestureDetector(
      behavior: opaque ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      onTap: action,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        opaque: opaque,
        child: this,
      ),
    );
  }
}
