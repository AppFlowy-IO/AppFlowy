import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class OptionColorItem extends StatelessWidget {
  const OptionColorItem({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final VoidCallback onTap;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(
          8.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: Corners.s12Border,
          border: Border.all(
            color: isSelected
                ? const Color(0xff00C6F1)
                : Theme.of(context).dividerColor,
          ),
        ),
        alignment: Alignment.center,
        child: isSelected
            ? const FlowySvg(
                FlowySvgs.blue_check_s,
                size: Size.square(28.0),
                blendMode: null,
              )
            : null,
      ),
    );
  }
}
