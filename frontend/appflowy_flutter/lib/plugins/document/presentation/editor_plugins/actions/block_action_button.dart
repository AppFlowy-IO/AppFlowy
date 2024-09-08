import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';

class BlockActionButton extends StatelessWidget {
  const BlockActionButton({
    super.key,
    required this.svg,
    required this.richMessage,
    required this.onTap,
  });

  final FlowySvgData svg;
  final InlineSpan richMessage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: FlowyTooltip(
        richMessage: richMessage,
        child: MouseRegion(
          cursor: Platform.isWindows
              ? SystemMouseCursors.click
              : SystemMouseCursors.grab,
          child: IgnoreParentGestureWidget(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.deferToChild,
              child: FlowySvg(
                svg,
                size: const Size.square(18.0),
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
