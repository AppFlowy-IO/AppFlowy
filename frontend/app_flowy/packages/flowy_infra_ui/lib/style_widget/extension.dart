import 'package:flutter/material.dart';
export 'package:styled_widget/styled_widget.dart';

extension FlowyStyledWidget on Widget {
  Widget bottomBorder({double width = 0.5, Color color = Colors.grey}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: width, color: color),
        ),
      ),
      child: this,
    );
  }

  Widget topBorder({double width = 0.5, Color color = Colors.grey}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: width, color: color),
        ),
      ),
      child: this,
    );
  }
}
