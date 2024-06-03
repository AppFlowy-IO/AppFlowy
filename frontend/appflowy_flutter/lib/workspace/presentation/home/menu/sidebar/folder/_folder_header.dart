import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FolderHeader extends StatefulWidget {
  const FolderHeader({
    super.key,
    required this.title,
    required this.expandButtonTooltip,
    required this.addButtonTooltip,
    required this.onPressed,
    required this.onAdded,
    required this.isExpanded,
  });

  final String title;
  final String expandButtonTooltip;
  final String addButtonTooltip;
  final VoidCallback onPressed;
  final VoidCallback onAdded;
  final bool isExpanded;

  @override
  State<FolderHeader> createState() => _FolderHeaderState();
}

class _FolderHeaderState extends State<FolderHeader> {
  final isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: FlowyButton(
        onTap: widget.onPressed,
        margin: const EdgeInsets.symmetric(horizontal: 6.0),
        rightIcon: ValueListenableBuilder(
          valueListenable: isHovered,
          builder: (context, onHover, child) =>
              Opacity(opacity: onHover ? 1 : 0, child: child),
          child: FlowyIconButton(
            tooltipText: widget.addButtonTooltip,
            icon: const FlowySvg(FlowySvgs.view_item_add_s),
            onPressed: widget.onAdded,
          ),
        ),
        iconPadding: 10.0,
        text: Row(
          children: [
            FlowyText(
              widget.title,
              lineHeight: 1.15,
            ),
            const HSpace(4.0),
            FlowySvg(
              widget.isExpanded
                  ? FlowySvgs.workspace_drop_down_menu_show_s
                  : FlowySvgs.workspace_drop_down_menu_hide_s,
            ),
          ],
        ),
      ),
    );
  }
}
