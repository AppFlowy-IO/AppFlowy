import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

typedef SimpleAFDialogAction = (String, void Function(BuildContext)?);

/// A simple dialog with a title, content, and actions.
///
/// The primary button is a filled button and colored using theme or destructive
/// color depending on the [isDestructive] parameter. The secondary button is an
/// outlined button.
///
Future<void> showSimpleAFDialog({
  required BuildContext context,
  required String title,
  required String content,
  bool isDestructive = false,
  required SimpleAFDialogAction primaryAction,
  SimpleAFDialogAction? secondaryAction,
  bool barrierDismissible = true,
}) {
  final theme = AppFlowyTheme.of(context);

  return showDialog(
    context: context,
    barrierColor: theme.surfaceColorScheme.overlay,
    barrierDismissible: barrierDismissible,
    builder: (_) {
      return AFModal(
        constraints: BoxConstraints(
          maxWidth: AFModalDimension.S,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AFModalHeader(
              leading: Text(
                title,
              ),
              trailing: [
                AFGhostButton.normal(
                  onTap: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.all(theme.spacing.xs),
                  builder: (context, isHovering, disabled) {
                    return FlowySvg(
                      FlowySvgs.toast_close_s,
                      size: Size.square(20),
                    );
                  },
                ),
              ],
            ),
            Flexible(
              child: ConstrainedBox(
                // AFModalDimension.dialogHeight - header - footer
                constraints: BoxConstraints(minHeight: 108.0),
                child: AFModalBody(
                  child: Text(
                    content,
                    style: theme.textStyle.body.standard(
                      color: theme.textColorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            AFModalFooter(
              trailing: [
                if (secondaryAction != null)
                  AFOutlinedTextButton.normal(
                    text: secondaryAction.$1,
                    onTap: () {
                      secondaryAction.$2?.call(context);
                      Navigator.of(context).pop();
                    },
                  ),
                isDestructive
                    ? AFFilledTextButton.destructive(
                        text: primaryAction.$1,
                        onTap: () {
                          primaryAction.$2?.call(context);
                          Navigator.of(context).pop();
                        },
                      )
                    : AFFilledTextButton.primary(
                        text: primaryAction.$1,
                        onTap: () {
                          primaryAction.$2?.call(context);
                          Navigator.of(context).pop();
                        },
                      ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// Shows a dialog for renaming an item with a text field.
/// The API is flexible: either provide a callback for confirmation or use the
/// returned Future to get the new value.
///
Future<String?> showAFTextFieldDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  void Function(String)? onConfirm,
  bool barrierDismissible = true,
  bool selectAll = true,
  int? maxLength,
  String? hintText,
}) {
  return showDialog<String?>(
    context: context,
    barrierColor: AppFlowyTheme.of(context).surfaceColorScheme.overlay,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return AFTextFieldDialog(
        title: title,
        initialValue: initialValue,
        onConfirm: onConfirm,
        selectAll: selectAll,
        maxLength: maxLength,
        hintText: hintText,
      );
    },
  );
}

class AFTextFieldDialog extends StatefulWidget {
  const AFTextFieldDialog({
    super.key,
    required this.title,
    required this.initialValue,
    this.onConfirm,
    this.selectAll = true,
    this.maxLength,
    this.hintText,
  });

  final String title;
  final String initialValue;
  final void Function(String)? onConfirm;
  final bool selectAll;
  final int? maxLength;
  final String? hintText;

  @override
  State<AFTextFieldDialog> createState() => _AFTextFieldDialogState();
}

class _AFTextFieldDialogState extends State<AFTextFieldDialog> {
  final textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textController.value = TextEditingValue(
      text: widget.initialValue,
      selection: widget.selectAll
          ? TextSelection(
              baseOffset: 0,
              extentOffset: widget.initialValue.length,
            )
          : TextSelection.collapsed(
              offset: widget.initialValue.length,
            ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFModal(
      constraints: BoxConstraints(
        maxWidth: AFModalDimension.S,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AFModalHeader(
            leading: Text(
              widget.title,
            ),
            trailing: [
              AFGhostButton.normal(
                onTap: () => Navigator.of(context).pop(),
                padding: EdgeInsets.all(theme.spacing.xs),
                builder: (context, isHovering, disabled) {
                  return FlowySvg(
                    FlowySvgs.toast_close_s,
                    size: Size.square(20),
                  );
                },
              ),
            ],
          ),
          Flexible(
            child: AFModalBody(
              child: AFTextField(
                autoFocus: true,
                size: AFTextFieldSize.m,
                hintText: widget.hintText,
                maxLength: widget.maxLength,
                controller: textController,
                onSubmitted: (_) {
                  handleConfirm();
                },
              ),
            ),
          ),
          AFModalFooter(
            trailing: [
              AFOutlinedTextButton.normal(
                text: LocaleKeys.button_cancel.tr(),
                onTap: () => Navigator.of(context).pop(),
              ),
              ValueListenableBuilder(
                valueListenable: textController,
                builder: (contex, value, child) {
                  return AFFilledTextButton.primary(
                    text: LocaleKeys.button_confirm.tr(),
                    disabled: value.text.trim().isEmpty,
                    onTap: handleConfirm,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void handleConfirm() {
    final text = textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    widget.onConfirm?.call(text);
    Navigator.of(context).pop(text);
  }
}
