import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/cover_editor.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

class SpaceIcon extends StatelessWidget {
  const SpaceIcon({
    super.key,
    required this.dimension,
    this.cornerRadius = 0,
    required this.space,
    this.svgSize,
  });

  final double dimension;
  final double cornerRadius;
  final ViewPB space;
  final double? svgSize;

  @override
  Widget build(BuildContext context) {
    final spaceIconColor = space.spaceIconColor;
    final color = spaceIconColor != null
        ? Color(int.parse(spaceIconColor))
        : Colors.transparent;
    final svg = space.buildSpaceIconSvg(
      context,
      size: svgSize != null ? Size.square(svgSize!) : null,
    );
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
          child: svgSize == null
              ? svg
              : SizedBox.square(dimension: svgSize!, child: svg),
        ),
      ),
    );
  }
}

class DefaultSpaceIcon extends StatelessWidget {
  const DefaultSpaceIcon({
    super.key,
    required this.dimension,
    this.cornerRadius = 0,
  });

  final double dimension;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    final svg = builtInSpaceIcons.first;
    final color = Color(int.parse(builtInAssetImages.first));
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Container(
        width: dimension,
        height: dimension,
        color: color,
        child: Center(
          child: FlowySvg(
            FlowySvgData('assets/flowy_icons/16x/$svg.svg'),
            color: color,
            blendMode: BlendMode.srcOut,
          ),
        ),
      ),
    );
  }
}
