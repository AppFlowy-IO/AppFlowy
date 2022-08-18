import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FlowySvg extends StatelessWidget {
  const FlowySvg({
    Key? key,
    this.name,
    this.size = const Size(20, 20),
    this.color,
    this.number,
    this.padding,
  }) : super(key: key);

  final String? name;
  final Size size;
  final Color? color;
  final int? number;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(0),
      child: _buildSvg(),
    );
  }

  Widget _buildSvg() {
    if (name != null) {
      return SizedBox.fromSize(
        size: size,
        child: SvgPicture.asset(
          'assets/images/$name.svg',
          color: color,
          package: 'appflowy_editor',
          fit: BoxFit.fill,
        ),
      );
    } else if (number != null) {
      final numberText =
          '<svg width="200" height="200" xmlns="http://www.w3.org/2000/svg"><text x="30" y="150" fill="black" font-size="160">$number.</text></svg>';
      return SvgPicture.string(
        numberText,
        width: size.width,
        height: size.width,
      );
    }
    return Container();
  }
}
