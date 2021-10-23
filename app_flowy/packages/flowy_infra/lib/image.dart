import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget svg(String name, {Color? color}) {
  final Widget svg = SvgPicture.asset('assets/images/$name.svg', color: color);

  return svg;
}

Widget svgWithSize(String name, Size size) {
  return SizedBox.fromSize(
    size: size,
    child: svg(name),
  );
}
