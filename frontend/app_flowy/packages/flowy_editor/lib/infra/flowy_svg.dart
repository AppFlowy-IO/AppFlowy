import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FlowySvg extends StatelessWidget {
  const FlowySvg({
    Key? key,
    required this.name,
    required this.size,
    this.color,
  }) : super(key: key);

  final String name;
  final Size size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: SvgPicture.asset(
        'assets/images/$name.svg',
        color: color,
        package: 'flowy_editor',
      ),
    );
  }
}
