import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// For icon that needs to change color when it is on hovered
///
/// Get the hover color from ThemeData
class FlowySvg extends StatelessWidget {
  const FlowySvg({
    super.key,
    required this.name,
    this.size,
    this.color,
  });

  final String name;
  final Size? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      'assets/images/$name.svg',
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
    );

    if (size != null) {
      return SizedBox.fromSize(
        size: size,
        child: svg,
      );
    } else {
      return svg;
    }
  }
}
