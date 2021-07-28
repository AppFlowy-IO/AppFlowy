import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class SignInFormContainer extends StatelessWidget {
  final List<Widget> children;
  const SignInFormContainer({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class SignInTitle extends StatelessWidget {
  final String title;
  final Size logoSize;
  const SignInTitle({
    Key? key,
    required this.title,
    required this.logoSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
              fit: BoxFit.cover,
              width: logoSize.width,
              height: logoSize.height,
              image: const AssetImage('assets/images/app_flowy_logo.jpg')),
          const VSpace(30),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          )
        ],
      ),
    );
  }
}
