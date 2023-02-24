import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/size.dart';

import 'base_styled_button.dart';

class SecondaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bigMode;

  const SecondaryTextButton(this.label,
      {Key? key, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      bigMode: bigMode,
      onPressed: onPressed,
      child: FlowyText.regular(
        label,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool bigMode;

  const SecondaryButton(
      {Key? key, required this.child, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseStyledButton(
      minWidth: bigMode ? 100 : 80,
      minHeight: bigMode ? 40 : 38,
      contentPadding: EdgeInsets.zero,
      bgColor: Theme.of(context).colorScheme.surface,
      hoverColor: Theme.of(context).colorScheme.secondary,
      downColor: Theme.of(context).colorScheme.primary,
      outlineColor: Theme.of(context).colorScheme.primary,
      borderRadius: bigMode ? Corners.s12Border : Corners.s8Border,
      onPressed: onPressed,
      child: child,
    );
  }
}
