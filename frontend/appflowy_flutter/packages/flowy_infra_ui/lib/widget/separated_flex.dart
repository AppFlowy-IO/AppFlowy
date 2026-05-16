import 'package:flutter/material.dart';

typedef SeparatorBuilder = Widget Function();

Widget _defaultColumnSeparatorBuilder() => const Divider();
Widget _defaultRowSeparatorBuilder() => const VerticalDivider();

class SeparatedColumn extends Column {
  SeparatedColumn({
    super.key,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.mainAxisSize,
    super.textBaseline,
    super.textDirection,
    super.verticalDirection,
    SeparatorBuilder separatorBuilder = _defaultColumnSeparatorBuilder,
    required List<Widget> children,
  }) : super(children: _insertSeparators(children, separatorBuilder));
}

class SeparatedRow extends Row {
  SeparatedRow({
    super.key,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.mainAxisSize,
    super.textBaseline,
    super.textDirection,
    super.verticalDirection,
    SeparatorBuilder separatorBuilder = _defaultRowSeparatorBuilder,
    required List<Widget> children,
  }) : super(children: _insertSeparators(children, separatorBuilder));
}

List<Widget> _insertSeparators(
  List<Widget> children,
  SeparatorBuilder separatorBuilder,
) {
  if (children.length < 2) {
    return children;
  }

  List<Widget> newChildren = [];
  for (int i = 0; i < children.length - 1; i++) {
    newChildren.add(children[i]);
    newChildren.add(separatorBuilder());
  }
  return newChildren..add(children.last);
}
