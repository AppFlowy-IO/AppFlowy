import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// For icon that needs to change color when it is on hovered
///
/// Get the hover color from ThemeData
class FlowySvg extends StatelessWidget {
  const FlowySvg({super.key, this.size, required this.name});
  final String name;
  final Size? size;

  @override
  Widget build(BuildContext context) {
    return svgWidget(
      name,
      size: size,
      color: Theme.of(context).iconTheme.color,
    );
  }
}

Widget svgWidget(String name, {Size? size, Color? color}) {
  if (size != null) {
    return SizedBox.fromSize(
      size: size,
      child: SvgPicture.asset(
        'assets/images/$name.svg',
        colorFilter:
            color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      ),
    );
  } else {
    return SvgPicture.asset(
      'assets/images/$name.svg',
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}
