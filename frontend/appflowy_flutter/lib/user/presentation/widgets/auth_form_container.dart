import 'package:flutter/material.dart';

class AuthFormContainer extends StatelessWidget {
  final List<Widget> children;
  static const double width = 340;
  const AuthFormContainer({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}
