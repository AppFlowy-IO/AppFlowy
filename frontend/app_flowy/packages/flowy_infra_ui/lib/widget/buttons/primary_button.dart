// ignore: depend_on_referenced_packages
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return PrimaryButton(
      bigMode: bigMode,
      onPressed: onPressed,
      child: FlowyText.regular(
        label,
        color: theme.surface,
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
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return BaseStyledButton(
      minWidth: bigMode ? 100 : 80,
      minHeight: bigMode ? 40 : 38,
      contentPadding: EdgeInsets.zero,
      bgColor: theme.main1,
      hoverColor: theme.main1,
      downColor: theme.main1,
      borderRadius: bigMode ? Corners.s12Border : Corners.s8Border,
      onPressed: onPressed,
      child: child,
    );
  }
}
