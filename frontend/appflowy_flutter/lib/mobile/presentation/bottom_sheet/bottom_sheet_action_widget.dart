import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/box_container.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return FlowyBoxContainer(
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        enableFeedback: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 12.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlowySvg(
                svg,
                size: const Size.square(24.0),
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
