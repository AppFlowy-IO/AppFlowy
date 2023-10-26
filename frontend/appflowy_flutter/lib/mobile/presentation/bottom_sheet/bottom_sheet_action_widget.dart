import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class BottomSheetActionWidget extends StatelessWidget {
  const BottomSheetActionWidget({
    super.key,
    required this.svg,
    required this.text,
    required this.onTap,
  });

  final FlowySvgData svg;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
        onTap: onTap,
        enableFeedback: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 16.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlowySvg(
                svg,
                size: const Size.square(22.0),
                blendMode: BlendMode.dst,
              ),
              const HSpace(6.0),
              FlowyText(text),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
