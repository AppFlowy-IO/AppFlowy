import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';

/// Represents a single action inside an action menu.
///
/// [itemWrapper] can be used to wrap the [ActionMenuItemWidget] with another
/// widget (e.g. a popover).
class ActionMenuItem {
  final Widget Function({double? size, Color? color}) iconBuilder;
  final Function()? onPressed;
  final bool Function()? selected;
  final Widget Function(Widget item)? itemWrapper;

  ActionMenuItem({
    required this.iconBuilder,
    required this.onPressed,
    this.selected,
    this.itemWrapper,
  });

  factory ActionMenuItem.icon({
    required IconData iconData,
    required Function()? onPressed,
    bool Function()? selected,
    Widget Function(Widget item)? itemWrapper,
  }) {
    return ActionMenuItem(
      iconBuilder: ({size, color}) {
        return Icon(
          iconData,
          size: size,
          color: color,
        );
      },
      onPressed: onPressed,
      selected: selected,
      itemWrapper: itemWrapper,
    );
  }

  factory ActionMenuItem.svg({
    required String name,
    required Function()? onPressed,
    bool Function()? selected,
    Widget Function(Widget item)? itemWrapper,
  }) {
    return ActionMenuItem(
      iconBuilder: ({size, color}) {
        return FlowySvg(
          name: name,
          color: color,
          width: size,
          height: size,
        );
      },
      onPressed: onPressed,
      selected: selected,
      itemWrapper: itemWrapper,
    );
  }

  factory ActionMenuItem.separator() {
    return ActionMenuItem(
      iconBuilder: ({size, color}) {
        return FlowySvg(
          name: 'image_toolbar/divider',
          color: color,
          height: size,
        );
      },
      onPressed: null,
    );
  }
}

class ActionMenuItemWidget extends StatelessWidget {
  final ActionMenuItem item;
  final double iconSize;

  const ActionMenuItemWidget({
    super.key,
    required this.item,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final editorStyle = EditorStyle.of(context);
    final isSelected = item.selected?.call() ?? false;
    final color = isSelected
        ? editorStyle?.selectionMenuItemSelectedIconColor
        : editorStyle?.selectionMenuItemIconColor;

    var icon = item.iconBuilder(size: iconSize, color: color);
    var itemWidget = Padding(
      padding: const EdgeInsets.all(3),
      child: item.onPressed != null
          ? MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: item.onPressed,
                child: icon,
              ),
            )
          : icon,
    );

    return item.itemWrapper?.call(itemWidget) ?? itemWidget;
  }
}
