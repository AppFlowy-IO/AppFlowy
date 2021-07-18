import 'package:flutter/material.dart';

class AutoUnfocus extends StatelessWidget {
  const AutoUnfocus({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _unfocusWidget(context),
      child: child,
    );
  }

  void _unfocusWidget(BuildContext context) {
    final focusing = FocusScope.of(context);

    if (!focusing.hasPrimaryFocus && focusing.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
