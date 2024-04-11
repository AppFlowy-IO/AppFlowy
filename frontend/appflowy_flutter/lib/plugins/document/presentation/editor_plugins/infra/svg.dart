import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Svg extends StatelessWidget {
  const Svg({
    super.key,
    this.name,
    this.width,
    this.height,
    this.color,
    this.number,
    this.padding,
  });

  final String? name;
  final double? width;
  final double? height;
  final Color? color;
  final int? number;
  final EdgeInsets? padding;

  final _defaultWidth = 20.0;
  final _defaultHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(0),
      child: _buildSvg(),
    );
  }

  Widget _buildSvg() {
    if (name != null) {
      return SvgPicture.asset(
        'assets/images/$name.svg',
        colorFilter:
            color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        fit: BoxFit.fill,
        height: height,
        width: width,
        package: 'appflowy_editor_plugins',
      );
    } else if (number != null) {
      final numberText =
          '<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg"><text x="30" y="150" fill="black" font-size="160">$number.</text></svg>';
      return SvgPicture.string(
        numberText,
        width: width ?? _defaultWidth,
        height: height ?? _defaultHeight,
      );
    }
    return const SizedBox.shrink();
  }
}
