import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
export 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

class NavigatorTextFieldDialog extends StatefulWidget {
  const NavigatorTextFieldDialog({
    super.key,
    required this.title,
    this.autoSelectAllText = false,
    required this.value,
    required this.confirm,
    this.cancel,
  });

  final String value;
  final String title;
  final void Function()? cancel;
  final void Function(String) confirm;
  final bool autoSelectAllText;

  @override
  State<NavigatorTextFieldDialog> createState() =>
      _NavigatorTextFieldDialogState();
}

class _NavigatorTextFieldDialogState extends State<NavigatorTextFieldDialog> {
  String newValue = "";
  final controller = TextEditingController();

  @override
  void initState() {
    newValue = widget.value;
    controller.text = newValue;
    if (widget.autoSelectAllText) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: newValue.length,
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      child: Column(
        children: <Widget>[
          FlowyText.medium(
            widget.title,
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: FontSizes.s16,
          ),
          VSpace(Insets.m),
          FlowyFormTextInput(
            textAlign: TextAlign.center,
            hintText: LocaleKeys.dialogCreatePageNameHint.tr(),
            controller: controller,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: FontSizes.s16,
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
          VSpace(Insets.xl),
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
          ),
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
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ...[
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                maxHeight: 260,
              ),
              child: FlowyText.medium(
                widget.title,
                fontSize: FontSizes.s16,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.tertiary,
                maxLines: null,
              ),
            ),
          ],
          if (widget.confirm != null) ...[
            const VSpace(20),
            OkCancelButton(
              onOkPressed: () {
                widget.confirm?.call();
                Navigator.of(context).pop();
              },
              onCancelPressed: () {
                widget.cancel?.call();
                Navigator.of(context).pop();
              },
            ),
          ],
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

  const NavigatorOkCancelDialog({
    Key? key,
    this.onOkPressed,
    this.onCancelPressed,
    this.okTitle,
    this.cancelTitle,
    this.title,
    required this.message,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      maxWidth: maxWidth ?? 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...[
            FlowyText.medium(
              title!.toUpperCase(),
              fontSize: FontSizes.s16,
            ),
            VSpace(Insets.sm * 1.5),
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant,
              height: 1,
            ),
            VSpace(Insets.m * 1.5),
          ],
          FlowyText.medium(message),
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
          ),
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
  final MainAxisAlignment alignment;
  final TextButtonMode mode;

  const OkCancelButton({
    Key? key,
    this.onOkPressed,
    this.onCancelPressed,
    this.okTitle,
    this.cancelTitle,
    this.minHeight,
    this.alignment = MainAxisAlignment.spaceAround,
    this.mode = TextButtonMode.big,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: alignment,
        children: <Widget>[
          if (onCancelPressed != null)
            SecondaryTextButton(
              cancelTitle ?? LocaleKeys.button_cancel.tr(),
              onPressed: onCancelPressed,
              mode: mode,
            ),
          HSpace(Insets.m),
          if (onOkPressed != null)
            PrimaryTextButton(
              okTitle ?? LocaleKeys.button_ok.tr(),
              onPressed: onOkPressed,
              mode: mode,
            ),
        ],
      ),
    );
  }
}
