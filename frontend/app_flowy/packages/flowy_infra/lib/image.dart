import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget svgWithSize(String name, Size size) {
  return SizedBox.fromSize(
    size: size,
    child: svgWidget(name),
  );
}

Widget svgWidget(String name, {Size? size, Color? color}) {
  if (size != null) {
    return SizedBox.fromSize(
      size: size,
      child: _svgWidget(name, color: color),
    );
  } else {
    return _svgWidget(name, color: color);
  }
}

Widget _svgWidget(String name, {Color? color}) {
  final Widget svg = SvgPicture.asset('assets/images/$name.svg', color: color);

  return svg;
}
