import 'package:flutter/material.dart';

typedef SeparatorBuilder = Widget Function();

class SeparatedColumn extends Column {
  final SeparatorBuilder separatorBuilder;

  SeparatedColumn({
    Key? key,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    MainAxisSize? mainAxisSize,
    TextBaseline? textBaseline,
    TextDirection? textDirection,
    VerticalDirection? verticalDirection,
    List<Widget> children = const <Widget>[],
    required this.separatorBuilder,
  }) : super(
          key: key,
          children: _insertSeparators(children, separatorBuilder),
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          textBaseline: textBaseline,
          textDirection: textDirection,
          verticalDirection: verticalDirection ?? VerticalDirection.down,
        );
}

class SeparatedRow extends Row {
  final SeparatorBuilder separatorBuilder;

  SeparatedRow({
    Key? key,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
    MainAxisSize? mainAxisSize,
    TextBaseline? textBaseline,
    TextDirection? textDirection,
    VerticalDirection? verticalDirection,
    List<Widget> children = const <Widget>[],
    required this.separatorBuilder,
  }) : super(
          key: key,
          children: _insertSeparators(children, separatorBuilder),
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          textBaseline: textBaseline,
          textDirection: textDirection,
          verticalDirection: verticalDirection ?? VerticalDirection.down,
        );
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
