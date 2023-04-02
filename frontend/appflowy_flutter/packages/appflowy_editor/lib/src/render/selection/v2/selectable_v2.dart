import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:flutter/material.dart';

abstract class SelectableState<T extends StatefulWidget> extends State<T> {
  Future<void> setSelectionV2(Selection? selection);

  Position getPositionInOffset(Offset offset);
}
