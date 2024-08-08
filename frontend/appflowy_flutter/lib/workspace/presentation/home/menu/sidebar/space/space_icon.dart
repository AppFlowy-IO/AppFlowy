import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
    // if space icon is null, use the first character of space name as icon

    final Color color;
    final Widget icon;

    if (space.spaceIcon == null) {
      final name = space.name.isNotEmpty ? space.name.capitalize()[0] : '';
      icon = FlowyText(
        name,
        color: Theme.of(context).colorScheme.surface,
        fontSize: svgSize,
        figmaLineHeight: dimension,
      );
      color = Color(int.parse(builtInSpaceColors.first));
    } else {
      final spaceIconColor = space.spaceIconColor;
      color = spaceIconColor != null
          ? Color(int.parse(spaceIconColor))
          : Colors.transparent;
      final svg = space.buildSpaceIconSvg(
        context,
        size: svgSize != null ? Size.square(svgSize!) : null,
      );
      if (svg == null) {
        icon = const SizedBox.shrink();
      } else {
        icon =
            svgSize == null || space.spaceIcon?.contains('space_icon') == true
                ? svg
                : SizedBox.square(dimension: svgSize!, child: svg);
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Container(
        width: dimension,
        height: dimension,
        color: color,
        child: Center(
          child: icon,
        ),
      ),
    );
  }
}

const kDefaultSpaceIconId = 'interface_essential/home-3';

class DefaultSpaceIcon extends StatelessWidget {
  const DefaultSpaceIcon({
    super.key,
    required this.dimension,
    required this.iconDimension,
    this.cornerRadius = 0,
  });

  final double dimension;
  final double cornerRadius;
  final double iconDimension;

  @override
  Widget build(BuildContext context) {
    final svgContent = kIconGroups?.findSvgContent(
      kDefaultSpaceIconId,
    );

    final Widget svg;
    if (svgContent != null) {
      svg = FlowySvg.string(
        svgContent,
        size: Size.square(iconDimension),
        color: Theme.of(context).colorScheme.surface,
      );
    } else {
      svg = FlowySvg(
        FlowySvgData('assets/flowy_icons/16x/${builtInSpaceIcons.first}.svg'),
        color: Theme.of(context).colorScheme.surface,
        size: Size.square(iconDimension),
      );
    }

    final color = Color(int.parse(builtInSpaceColors.first));
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Container(
        width: dimension,
        height: dimension,
        color: color,
        child: Center(
          child: svg,
        ),
      ),
    );
  }
}
