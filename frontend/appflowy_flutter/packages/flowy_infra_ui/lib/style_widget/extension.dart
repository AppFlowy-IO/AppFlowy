import 'package:flutter/material.dart';
export 'package:styled_widget/styled_widget.dart';

class TopBorder extends StatelessWidget {
  const TopBorder({
    super.key,
    this.width = 1.0,
    this.color = Colors.grey,
    required this.child,
  });

  final Widget child;
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: width, color: color),
        ),
      ),
      child: child,
    );
  }
}
