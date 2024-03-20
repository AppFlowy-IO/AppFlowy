import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class CloseKeyboardOrMenuButton extends StatelessWidget {
  const CloseKeyboardOrMenuButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 42,
      child: FlowyButton(
        text: const FlowySvg(
          FlowySvgs.m_toolbar_keyboard_m,
        ),
        onTap: onPressed,
      ),
    );
  }
}
