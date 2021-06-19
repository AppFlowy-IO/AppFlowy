import 'package:flutter/material.dart';

class Body extends StatelessWidget {
  const Body({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Container(
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image(
                fit: BoxFit.cover,
                width: size.width,
                height: size.height,
                image: const AssetImage(
                    'assets/images/appflowy_launch_splash.jpg')),
            const CircularProgressIndicator.adaptive(),
          ],
        ),
      ),
    );
  }
}
