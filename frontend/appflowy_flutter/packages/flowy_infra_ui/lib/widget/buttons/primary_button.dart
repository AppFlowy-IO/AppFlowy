import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/size.dart';
import 'base_styled_button.dart';

class PrimaryTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool bigMode;

  const PrimaryTextButton(this.label,
      {Key? key, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      bigMode: bigMode,
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
  final bool bigMode;

  const PrimaryButton(
      {Key? key, required this.child, this.onPressed, this.bigMode = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseStyledButton(
      minWidth: bigMode ? 100 : 80,
      minHeight: bigMode ? 40 : 38,
      contentPadding: EdgeInsets.zero,
      bgColor: Theme.of(context).colorScheme.primary,
      hoverColor: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: bigMode ? Corners.s12Border : Corners.s8Border,
      onPressed: onPressed,
      child: child,
    );
  }
}
