import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/hover_builder.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FolderHeader extends StatelessWidget {
  const FolderHeader({
    super.key,
    required this.title,
    required this.expandButtonTooltip,
    required this.addButtonTooltip,
    required this.onPressed,
    required this.onAdded,
  });

  final String title;
  final String expandButtonTooltip;
  final String addButtonTooltip;
  final VoidCallback onPressed;
  final VoidCallback onAdded;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return FlowyButton(
          onTap: onPressed,
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          rightIcon: ValueListenableBuilder(
            valueListenable: isHovered,
            builder: (context, onHover, child) =>
                Opacity(opacity: onHover ? 1 : 0, child: child),
            child: FlowyIconButton(
              tooltipText: addButtonTooltip,
              icon: const FlowySvg(FlowySvgs.view_item_add_s),
              onPressed: onAdded,
            ),
          ),
          iconPadding: 10.0,
          text: FlowyText(title),
        );
      },
    );
  }
}
