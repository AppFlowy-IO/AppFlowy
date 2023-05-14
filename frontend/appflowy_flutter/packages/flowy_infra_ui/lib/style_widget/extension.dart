import 'package:flutter/material.dart';
export 'package:styled_widget/styled_widget.dart';

extension FlowyStyledWidget on Widget {
  Widget bottomBorder({double width = 1.0, Color color = Colors.grey}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: width, color: color),
        ),
      ),
      child: this,
    );
  }

  Widget topBorder({double width = 1.0, Color color = Colors.grey}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: width, color: color),
        ),
      ),
      child: this,
    );
  }
}
