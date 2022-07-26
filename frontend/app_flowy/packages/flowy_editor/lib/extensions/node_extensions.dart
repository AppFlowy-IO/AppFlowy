import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/extensions/object_extensions.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flutter/material.dart';

extension NodeExtensions on Node {
  RenderBox? get renderBox =>
      key?.currentContext?.findRenderObject()?.unwrapOrNull<RenderBox>();

  Selectable? get selectable => key?.currentState?.unwrapOrNull<Selectable>();
}
