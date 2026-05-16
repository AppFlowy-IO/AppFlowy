import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

import 'base_styled_button.dart';
import 'secondary_button.dart';

class PrimaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TextButtonMode mode;

  const PrimaryTextButton(this.label,
      {super.key, this.onPressed, this.mode = TextButtonMode.big});

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      mode: mode,
      onPressed: onPressed,
      child: FlowyText.regular(
        label,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.child,
    this.onPressed,
    this.mode = TextButtonMode.big,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final TextButtonMode mode;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return BaseStyledButton(
      minWidth: mode.size.width,
      minHeight: mode.size.height,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      bgColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      hoverColor: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: mode.borderRadius,
      onPressed: onPressed,
      child: child,
    );
  }
}
