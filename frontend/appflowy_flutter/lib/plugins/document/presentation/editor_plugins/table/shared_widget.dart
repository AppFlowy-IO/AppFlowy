import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:flutter/material.dart';

class SimpleTableAddRowButton extends StatelessWidget {
  const SimpleTableAddRowButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: SimpleTableConstants.addRowButtonHeight,
          margin: const EdgeInsets.symmetric(
            vertical: SimpleTableConstants.addRowButtonPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              SimpleTableConstants.addRowButtonRadius,
            ),
            color: SimpleTableConstants.addRowButtonBackgroundColor,
          ),
          child: const FlowySvg(
            FlowySvgs.add_s,
          ),
        ),
      ),
    );
  }
}

class SimpleTableAddColumnButton extends StatelessWidget {
  const SimpleTableAddColumnButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: SimpleTableConstants.addColumnButtonWidth,
          margin: const EdgeInsets.symmetric(
            horizontal: SimpleTableConstants.addColumnButtonPadding,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              SimpleTableConstants.addColumnButtonRadius,
            ),
            color: SimpleTableConstants.addColumnButtonBackgroundColor,
          ),
          child: const FlowySvg(
            FlowySvgs.add_s,
          ),
        ),
      ),
    );
  }
}
