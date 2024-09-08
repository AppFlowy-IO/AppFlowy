import 'package:flutter/material.dart';

class AuthFormContainer extends StatelessWidget {
  const AuthFormContainer({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  static const double width = 340;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
