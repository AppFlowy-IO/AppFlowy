import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class BlockActionButton extends StatelessWidget {
  const BlockActionButton({
    super.key,
    required this.svg,
    required this.richMessage,
    required this.onTap,
    this.showTooltip = true,
    this.onPointerDown,
  });

  final FlowySvgData svg;
  final bool showTooltip;
  final InlineSpan richMessage;
  final VoidCallback onTap;
  final VoidCallback? onPointerDown;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 18.0,
      hoverColor: Colors.transparent,
      iconColorOnHover: Theme.of(context).iconTheme.color,
      onPressed: onTap,
      richTooltipText: showTooltip ? richMessage : null,
      icon: MouseRegion(
        cursor: Platform.isWindows
            ? SystemMouseCursors.click
            : SystemMouseCursors.grab,
        child: FlowySvg(
          svg,
          size: const Size.square(18.0),
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}
