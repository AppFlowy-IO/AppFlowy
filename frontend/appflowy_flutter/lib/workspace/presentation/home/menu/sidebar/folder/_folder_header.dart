import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class FolderHeader extends StatefulWidget {
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
  State<FolderHeader> createState() => _FolderHeaderState();
}

class _FolderHeaderState extends State<FolderHeader> {
  bool onHover = false;

  @override
  Widget build(BuildContext context) {
    const iconSize = 26.0;
    const textPadding = 4.0;
    return MouseRegion(
      onEnter: (event) => setState(() => onHover = true),
      onExit: (event) => setState(() => onHover = false),
      child: Row(
        children: [
          FlowyTextButton(
            widget.title,
            tooltip: widget.expandButtonTooltip,
            constraints: const BoxConstraints(
              minHeight: iconSize + textPadding * 2,
            ),
            fontColor: AFThemeExtension.of(context).textColor,
            padding: const EdgeInsets.all(textPadding),
            fillColor: Colors.transparent,
            onPressed: widget.onPressed,
          ),
          if (onHover) ...[
            const Spacer(),
            FlowyIconButton(
              tooltipText: widget.addButtonTooltip,
              hoverColor: Theme.of(context).colorScheme.secondaryContainer,
              iconPadding: const EdgeInsets.all(2),
              height: iconSize,
              width: iconSize,
              icon: const FlowySvg(FlowySvgs.add_s),
              onPressed: widget.onAdded,
            ),
          ],
        ],
      ),
    );
  }
}
