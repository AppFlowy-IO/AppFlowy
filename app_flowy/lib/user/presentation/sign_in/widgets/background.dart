import 'package:flutter/material.dart';

class SignInBackground extends StatelessWidget {
  final Widget child;
  const SignInBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SizedBox(
        height: size.height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
                image: const AssetImage(
                    'assets/images/appflowy_launch_splash.jpg')),
            child,
          ],
        ));
  }
}
