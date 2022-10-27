import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/startup/tasks/app_widget.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
export 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class NavigatorTextFieldDialog extends StatefulWidget {
  final String value;
  final String title;
  final void Function()? cancel;
  final void Function(String) confirm;

  const NavigatorTextFieldDialog({
    required this.title,
    required this.value,
    required this.confirm,
    this.cancel,
    Key? key,
  }) : super(key: key);

  @override
  State<NavigatorTextFieldDialog> createState() => _CreateTextFieldDialog();
}

class _CreateTextFieldDialog extends State<NavigatorTextFieldDialog> {
  String newValue = "";

  @override
  void initState() {
    newValue = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ...[
            FlowyText.medium(widget.title, color: theme.shader4),
            VSpace(Insets.sm * 1.5),
          ],
          FlowyFormTextInput(
            hintText: LocaleKeys.dialogCreatePageNameHint.tr(),
            initialValue: widget.value,
            textStyle: TextStyles.general(
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
            autoFocus: true,
            onChanged: (text) {
              newValue = text;
            },
            onEditingComplete: () {
              widget.confirm(newValue);
              AppGlobals.nav.pop();
            },
          ),
          const VSpace(10),
          OkCancelButton(
            onOkPressed: () {
              widget.confirm(newValue);
              Navigator.of(context).pop();
            },
            onCancelPressed: () {
              if (widget.cancel != null) {
                widget.cancel!();
              }
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }
}

class NavigatorAlertDialog extends StatefulWidget {
  final String title;
  final void Function()? cancel;
  final void Function()? confirm;

  const NavigatorAlertDialog({
    required this.title,
    this.confirm,
    this.cancel,
    Key? key,
  }) : super(key: key);

  @override
  State<NavigatorAlertDialog> createState() => _CreateFlowyAlertDialog();
}

class _CreateFlowyAlertDialog extends State<NavigatorAlertDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ...[
            FlowyText.medium(widget.title, color: theme.shader4),
          ],
          if (widget.confirm != null) ...[
            const VSpace(20),
            OkCancelButton(onOkPressed: () {
              widget.confirm?.call();
              Navigator.of(context).pop();
            }, onCancelPressed: () {
              widget.cancel?.call();
              Navigator.of(context).pop();
            })
          ]
        ],
      ),
    );
  }
}

class NavigatorOkCancelDialog extends StatelessWidget {
  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okTitle;
  final String? cancelTitle;
  final String? title;
  final String message;
  final double? maxWidth;

  const NavigatorOkCancelDialog(
      {Key? key,
      this.onOkPressed,
      this.onCancelPressed,
      this.okTitle,
      this.cancelTitle,
      this.title,
      required this.message,
      this.maxWidth})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return StyledDialog(
      maxWidth: maxWidth ?? 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...[
            FlowyText.medium(title!.toUpperCase(), color: theme.shader1),
            VSpace(Insets.sm * 1.5),
            Container(color: theme.bg1, height: 1),
            VSpace(Insets.m * 1.5),
          ],
          FlowyText.medium(message, fontSize: FontSizes.s12),
          SizedBox(height: Insets.l),
          OkCancelButton(
            onOkPressed: () {
              onOkPressed?.call();
              Navigator.of(context).pop();
            },
            onCancelPressed: () {
              onCancelPressed?.call();
              Navigator.of(context).pop();
            },
            okTitle: okTitle?.toUpperCase(),
            cancelTitle: cancelTitle?.toUpperCase(),
          )
        ],
      ),
    );
  }
}

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
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (onCancelPressed != null)
            SecondaryTextButton(
              cancelTitle ?? LocaleKeys.button_Cancel.tr(),
              onPressed: onCancelPressed,
              bigMode: true,
            ),
          HSpace(Insets.m),
          if (onOkPressed != null)
            PrimaryTextButton(
              okTitle ?? LocaleKeys.button_OK.tr(),
              onPressed: onOkPressed,
              bigMode: true,
            ),
        ],
      ),
    );
  }
}
