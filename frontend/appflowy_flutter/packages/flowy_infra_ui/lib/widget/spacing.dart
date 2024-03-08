import 'package:flutter/cupertino.dart';

class Space extends StatelessWidget {
  final double width;
  final double height;

  const Space(this.width, this.height, {super.key});

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
  const HSpace(
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
        height: double.infinity,
        width: size,
        child: ColoredBox(
          color: color!,
        ),
      );
    } else {
      return Space(size, 0);
    }
  }
}
