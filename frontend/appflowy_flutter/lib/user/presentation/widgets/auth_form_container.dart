import 'dart:math';

import 'package:flutter/material.dart';

class AuthFormContainer extends StatelessWidget {
  final List<Widget> children;
  const AuthFormContainer({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: min(size.width, 340),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
