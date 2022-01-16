import 'dart:math';

import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

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
            style: Theme.of(context).textTheme.headline5,
          )
        ],
      ),
    );
  }
}
