import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:flutter/material.dart';

abstract class SelectableState {
  Future<void> setSelectionV2(Selection? selection);

  Position getPositionInOffset(Offset offset);
}
