import 'package:flutter/material.dart';

class TypeOptionSeparator extends StatelessWidget {
  const TypeOptionSeparator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        color: Theme.of(context).dividerColor,
        height: 1.0,
      ),
    );
  }
}
