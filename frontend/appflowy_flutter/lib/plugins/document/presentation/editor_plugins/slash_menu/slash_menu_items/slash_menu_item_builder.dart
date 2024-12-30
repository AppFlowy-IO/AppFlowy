import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

/// Builder function for the slash menu item.
Widget slashMenuItemNameBuilder(
  String name,
  SelectionMenuStyle style,
  bool isSelected,
) {
  return SlashMenuItemNameBuilder(
    name: name,
    style: style,
    isSelected: isSelected,
  );
}

Widget slashMenuItemIconBuilder(
  FlowySvgData data,
  bool isSelected,
  SelectionMenuStyle style,
) {
  return SelectableSvgWidget(
    data: data,
    isSelected: isSelected,
    style: style,
  );
}

/// Build the name of the slash menu item.
class SlashMenuItemNameBuilder extends StatelessWidget {
  const SlashMenuItemNameBuilder({
    super.key,
    required this.name,
    required this.style,
    required this.isSelected,
  });

  /// The name of the slash menu item.
  final String name;

  /// The style of the slash menu item.
  final SelectionMenuStyle style;

  /// Whether the slash menu item is selected.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyText.regular(
      name,
      fontSize: 12.0,
      figmaLineHeight: 15.0,
      color: isSelected
          ? style.selectionMenuItemSelectedTextColor
          : style.selectionMenuItemTextColor,
    );
  }
}

/// Build the icon of the slash menu item.
class SlashMenuIconBuilder extends StatelessWidget {
  const SlashMenuIconBuilder({
    super.key,
    required this.data,
    required this.isSelected,
    required this.style,
  });

  /// The data of the icon.
  final FlowySvgData data;

  /// Whether the slash menu item is selected.
  final bool isSelected;

  /// The style of the slash menu item.
  final SelectionMenuStyle style;

  @override
  Widget build(BuildContext context) {
    return SelectableSvgWidget(
      data: data,
      isSelected: isSelected,
      style: style,
    );
  }
}
