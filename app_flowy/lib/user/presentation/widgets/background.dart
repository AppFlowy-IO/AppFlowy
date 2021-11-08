import 'dart:math';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthFormContainer extends StatelessWidget {
  final List<Widget> children;
  const AuthFormContainer({
    Key? key,
    required this.children,
  }) : super(key: key);

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

class FlowyLogoTitle extends StatelessWidget {
  final String title;
  final Size logoSize;
  const FlowyLogoTitle({
    Key? key,
    required this.title,
    this.logoSize = const Size.square(40),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.fromSize(
            size: logoSize,
            child: svg("flowy_logo"),
          ),
          const VSpace(30),
          Text(
            title,
            style: TextStyle(
              color: theme.shader1,
              fontWeight: FontWeight.w600,
              fontSize: 24,
            ),
          )
        ],
      ),
    );
  }
}
