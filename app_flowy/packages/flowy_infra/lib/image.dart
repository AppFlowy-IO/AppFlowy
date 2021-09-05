import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget svgWidgetWithName(String name) {
  final Widget svg = SvgPicture.asset(
    'assets/images/$name',
  );

  return svg;
}
