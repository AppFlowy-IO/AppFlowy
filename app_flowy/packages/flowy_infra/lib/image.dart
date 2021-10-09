import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget svg(String name) {
  final Widget svg = SvgPicture.asset(
    'assets/images/$name.svg',
  );

  return svg;
}

Widget svgWithSize(String name, Size size) {
  return SizedBox.fromSize(
    size: size,
    child: svg(name),
  );
}
