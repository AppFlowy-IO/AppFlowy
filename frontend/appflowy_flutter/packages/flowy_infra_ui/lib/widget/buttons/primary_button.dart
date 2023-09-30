import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'base_styled_button.dart';
import 'secondary_button.dart';

class PrimaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final TextButtonMode mode;

  const PrimaryTextButton(this.label,
      {Key? key, this.onPressed, this.mode = TextButtonMode.big})
      : super(key: key);

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
  final Widget child;
  final VoidCallback? onPressed;
  final TextButtonMode mode;

  const PrimaryButton(
      {Key? key,
      required this.child,
      this.onPressed,
      this.mode = TextButtonMode.big})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseStyledButton(
      minWidth: mode.size.width,
      minHeight: mode.size.height,
      contentPadding: EdgeInsets.zero,
      bgColor: Theme.of(context).colorScheme.primary,
      hoverColor: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: mode.borderRadius,
      onPressed: onPressed,
      child: child,
    );
  }
}
