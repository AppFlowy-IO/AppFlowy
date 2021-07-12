import 'package:flowy_style/size.dart';
import 'package:flowy_style/spacing.dart';
import 'package:flowy_style/strings.dart';
import 'package:flutter/material.dart';

import 'primary_button.dart';
import 'secondary_button.dart';

class OkCancelButton extends StatelessWidget {
  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okTitle;
  final String? cancelTitle;
  final double? minHeight;

  const OkCancelButton(
      {Key? key,
      this.onOkPressed,
      this.onCancelPressed,
      this.okTitle,
      this.cancelTitle,
      this.minHeight})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        if (onOkPressed != null)
          PrimaryTextButton(okTitle ?? S.BTN_OK.toUpperCase(),
              onPressed: onOkPressed),
        HSpace(Insets.m),
        if (onCancelPressed != null)
          SecondaryTextButton(cancelTitle ?? S.BTN_CANCEL.toUpperCase(),
              onPressed: onCancelPressed),
      ],
    );
  }
}
