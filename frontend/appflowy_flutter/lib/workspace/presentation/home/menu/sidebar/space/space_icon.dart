import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SpaceIcon extends StatelessWidget {
  const SpaceIcon({
    super.key,
    required this.dimension,
    this.textDimension,
    this.cornerRadius = 0,
    required this.space,
    this.svgSize,
  });

  final double dimension;
  final double? textDimension;
  final double cornerRadius;
  final ViewPB space;
  final double? svgSize;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _buildSpaceIcon(context);

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

  (Widget, Color?) _buildSpaceIcon(BuildContext context) {
    final spaceIcon = space.spaceIcon;
    if (spaceIcon == null || spaceIcon.isEmpty == true) {
      // if space icon is null, use the first character of space name as icon
      return _buildEmptySpaceIcon(context);
    } else {
      return _buildCustomSpaceIcon(context);
    }
  }

  (Widget, Color?) _buildEmptySpaceIcon(BuildContext context) {
    final name = space.name.isNotEmpty ? space.name.capitalize()[0] : '';
    final icon = FlowyText.medium(
      name,
      color: Theme.of(context).colorScheme.surface,
      fontSize: svgSize,
      figmaLineHeight: textDimension ?? dimension,
    );
    Color? color;
    try {
      final defaultColor = builtInSpaceColors.firstOrNull;
      if (defaultColor != null) {
        color = Color(int.parse(defaultColor));
      }
    } catch (e) {
      Log.error('Failed to parse default space icon color: $e');
    }
    return (icon, color);
  }

  (Widget, Color?) _buildCustomSpaceIcon(BuildContext context) {
    final spaceIconColor = space.spaceIconColor;

    final svg = space.buildSpaceIconSvg(
      context,
      size: svgSize != null ? Size.square(svgSize!) : null,
    );
    Widget icon;
    if (svg == null) {
      icon = const SizedBox.shrink();
    } else {
      icon = svgSize == null ||
              space.spaceIcon?.contains(ViewExtKeys.spaceIconKey) == true
          ? svg
          : SizedBox.square(dimension: svgSize!, child: svg);
    }

    Color color = Colors.transparent;
    if (spaceIconColor != null && spaceIconColor.isNotEmpty) {
      try {
        color = Color(int.parse(spaceIconColor));
      } catch (e) {
        Log.error(
          'Failed to parse space icon color: $e, value: $spaceIconColor',
        );
      }
    }

    return (icon, color);
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
