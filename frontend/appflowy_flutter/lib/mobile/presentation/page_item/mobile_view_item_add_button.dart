import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _iconSize = 32.0;

class MobileViewAddButton extends StatelessWidget {
  const MobileViewAddButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      iconPadding: const EdgeInsets.all(2),
      width: _iconSize,
      height: _iconSize,
      icon: const FlowySvg(
        FlowySvgs.add_s,
        size: Size.square(_iconSize),
      ),
      onPressed: onPressed,
    );
  }
}
