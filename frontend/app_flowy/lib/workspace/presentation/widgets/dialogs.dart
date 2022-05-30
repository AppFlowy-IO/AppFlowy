import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra/theme.dart';
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
import 'package:textstyle_extensions/textstyle_extensions.dart';
export 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class TextFieldDialog extends StatefulWidget {
  final String value;
  final String title;
  final void Function()? cancel;
  final void Function(String) confirm;

  const TextFieldDialog({
    required this.title,
    required this.value,
    required this.confirm,
    this.cancel,
    Key? key,
  }) : super(key: key);

  @override
  State<TextFieldDialog> createState() => _CreateTextFieldDialog();
}

class _CreateTextFieldDialog extends State<TextFieldDialog> {
  String newValue = "";

  @override
  void initState() {
    newValue = widget.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
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
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
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
            },
            onCancelPressed: () {
              if (widget.cancel != null) {
                widget.cancel!();
              }
            },
          )
        ],
      ),
    );
  }
}

class FlowyAlertDialog extends StatefulWidget {
  final String title;
  final void Function()? cancel;
  final void Function()? confirm;

  const FlowyAlertDialog({
    required this.title,
    this.confirm,
    this.cancel,
    Key? key,
  }) : super(key: key);

  @override
  State<FlowyAlertDialog> createState() => _CreateFlowyAlertDialog();
}

class _CreateFlowyAlertDialog extends State<FlowyAlertDialog> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
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
            OkCancelButton(
              onOkPressed: widget.confirm!,
              onCancelPressed: widget.confirm,
            )
          ]
        ],
      ),
    );
  }
}

class OkCancelDialog extends StatelessWidget {
  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okTitle;
  final String? cancelTitle;
  final String? title;
  final String message;
  final double? maxWidth;

  const OkCancelDialog(
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
    final theme = context.watch<AppTheme>();
    return StyledDialog(
      maxWidth: maxWidth ?? 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...[
            Text(title!.toUpperCase(), style: TextStyles.T1.textColor(theme.shader1)),
            VSpace(Insets.sm * 1.5),
            Container(color: theme.bg1, height: 1),
            VSpace(Insets.m * 1.5),
          ],
          Text(message, style: TextStyles.Body1.textHeight(1.5)),
          SizedBox(height: Insets.l),
          OkCancelButton(
            onOkPressed: onOkPressed,
            onCancelPressed: onCancelPressed,
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
      {Key? key, this.onOkPressed, this.onCancelPressed, this.okTitle, this.cancelTitle, this.minHeight})
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
              onPressed: () {
                onCancelPressed!();
                AppGlobals.nav.pop();
              },
              bigMode: true,
            ),
          HSpace(Insets.m),
          if (onOkPressed != null)
            PrimaryTextButton(
              okTitle ?? LocaleKeys.button_OK.tr(),
              onPressed: () {
                onOkPressed!();
                AppGlobals.nav.pop();
              },
              bigMode: true,
            ),
        ],
      ),
    );
  }
}

class BubbleNotification extends StatefulWidget {
  final String msgTitle;
  final String msgBody;

  const BubbleNotification({Key? key, required this.msgTitle, required this.msgBody}) : super(key: key);

  @override
  State<BubbleNotification> createState() => _BubbleNotification();
}

class _BubbleNotification extends State<BubbleNotification> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
        // maxWidth: 800,
        maxHeight: 200,
        shrinkWrap: true,
        child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: SafeArea(
              child: ListTile(
                leading: SizedBox.fromSize(
                  size: const Size(40, 40),
                  child: const ClipOval(
                    child: Icon(Icons.file_copy),
                  ),
                ),
                title: Text(widget.msgTitle),
                subtitle: Text(widget.msgBody),
              ),
            )));
  }
}
