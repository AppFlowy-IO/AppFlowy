import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';

class BlockActionButton extends StatelessWidget {
  const BlockActionButton({
    super.key,
    required this.svgName,
    required this.richMessage,
    required this.onTap,
  });

  final String svgName;
  final InlineSpan richMessage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Tooltip(
        preferBelow: false,
        richMessage: richMessage,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: IgnoreParentGestureWidget(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.deferToChild,
              child: svgWidget(
                svgName,
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
