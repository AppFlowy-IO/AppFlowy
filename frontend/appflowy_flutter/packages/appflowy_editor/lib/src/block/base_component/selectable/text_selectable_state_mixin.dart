import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

mixin TextBlockSelectableStateMixin<T extends StatefulWidget>
    implements SelectableState<T> {
  final GlobalKey textBlockKey = GlobalKey();

  @override
  Position getPositionInOffset(Offset offset) {
    assert(textBlockKey.currentState is TextBlockState);
    return (textBlockKey.currentState as TextBlockState)
        .getPositionInOffset(offset);
  }

  @override
  Future<void> setSelectionV2(Selection? selection) {
    assert(textBlockKey.currentState is TextBlockState);
    return (textBlockKey.currentState as TextBlockState)
        .setSelectionV2(selection);
  }
}
