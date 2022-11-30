import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget svgWidget(String name, {Size? size, Color? color}) {
  if (size != null) {
    return SizedBox.fromSize(
      size: size,
      child: SvgPicture.asset('assets/images/$name.svg', color: color),
    );
  } else {
    return SvgPicture.asset('assets/images/$name.svg', color: color);
  }
}
