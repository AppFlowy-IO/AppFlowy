import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

class SpaceIcon extends StatelessWidget {
  const SpaceIcon({
    super.key,
    required this.dimension,
    this.cornerRadius = 0,
    required this.space,
  });

  final double dimension;
  final double cornerRadius;
  final ViewPB space;

  @override
  Widget build(BuildContext context) {
    final spaceIconColor = space.spaceIconColor;
    final color = spaceIconColor != null
        ? Color(int.parse(spaceIconColor))
        : Colors.transparent;
    final svg = space.buildSpaceIconSvg(context);
    if (svg == null) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Container(
        width: dimension,
        height: dimension,
        color: color,
        child: Center(
          child: space.buildSpaceIconSvg(context),
        ),
      ),
    );
  }
}
