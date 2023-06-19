import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/size.dart';

import 'base_styled_button.dart';

enum SecondaryTextButtonMode {
  normal,
  big,
  small;

  Size get size {
    switch (this) {
      case SecondaryTextButtonMode.normal:
        return const Size(80, 38);
      case SecondaryTextButtonMode.big:
        return const Size(100, 40);
      case SecondaryTextButtonMode.small:
        return const Size(100, 30);
    }
  }

  BorderRadius get borderRadius {
    switch (this) {
      case SecondaryTextButtonMode.normal:
        return Corners.s8Border;
      case SecondaryTextButtonMode.big:
        return Corners.s12Border;
      case SecondaryTextButtonMode.small:
        return Corners.s6Border;
    }
  }
}

class SecondaryTextButton extends StatelessWidget {
  const SecondaryTextButton(
    this.label, {
    super.key,
    this.onPressed,
    this.mode = SecondaryTextButtonMode.normal,
  });

  final String label;
  final VoidCallback? onPressed;
  final SecondaryTextButtonMode mode;

  @override
  Widget build(BuildContext context) {
    return SecondaryButton(
      mode: mode,
      onPressed: onPressed,
      child: FlowyText.regular(
        label,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.mode = SecondaryTextButtonMode.normal,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final SecondaryTextButtonMode mode;

  @override
  Widget build(BuildContext context) {
    final size = mode.size;
    return BaseStyledButton(
      minWidth: size.width,
      minHeight: size.height,
      contentPadding: EdgeInsets.zero,
      bgColor: Theme.of(context).colorScheme.surface,
      outlineColor: Theme.of(context).colorScheme.primary,
      borderRadius: mode.borderRadius,
      onPressed: onPressed,
      child: child,
    );
  }
}
