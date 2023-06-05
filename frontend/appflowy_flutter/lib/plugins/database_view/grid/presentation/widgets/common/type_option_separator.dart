import 'package:flutter/material.dart';

class TypeOptionSeparator extends StatelessWidget {
  final double spacing;
  const TypeOptionSeparator({this.spacing = 6.0, final Key? key}) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Container(
        color: Theme.of(context).dividerColor,
        height: 1.0,
      ),
    );
  }
}
