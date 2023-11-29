import 'package:flutter/cupertino.dart';

class Space extends StatelessWidget {
  final double width;
  final double height;

  const Space(this.width, this.height, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}

class VSpace extends StatelessWidget {
  const VSpace(
    this.size, {
    super.key,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (color != null) {
      return SizedBox(
        height: size,
        width: double.infinity,
        child: ColoredBox(
          color: color!,
        ),
      );
    } else {
      return Space(0, size);
    }
  }
}

class HSpace extends StatelessWidget {
  final double size;

  const HSpace(this.size, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Space(size, 0);
}
