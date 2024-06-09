import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ConfirmDialogActionAlignment {
  // The action buttons are aligned vertically
  // ---------------------
  // |  Action Button    |
  // |  Cancel Button    |
  vertical,
  // The action buttons are aligned horizontally
  // ---------------------
  // |  Action Button    |  Cancel Button    |
  horizontal,
}

/// show the dialog to confirm one single action
/// [onActionButtonPressed] and [onCancelButtonPressed] end with close the dialog
Future<T?> showFlowyMobileConfirmDialog<T>(
  BuildContext context, {
  Widget? title,
  Widget? content,
  ConfirmDialogActionAlignment actionAlignment =
      ConfirmDialogActionAlignment.horizontal,
  required String actionButtonTitle,
  required VoidCallback? onActionButtonPressed,
  Color? actionButtonColor,
  String? cancelButtonTitle,
  Color? cancelButtonColor,
  VoidCallback? onCancelButtonPressed,
}) async {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      final foregroundColor = Theme.of(context).colorScheme.onSurface;
      final actionButton = TextButton(
        child: FlowyText(
          actionButtonTitle,
          color: actionButtonColor ?? foregroundColor,
        ),
        onPressed: () {
          onActionButtonPressed?.call();
          // we cannot use dialogContext.pop() here because this is no GoRouter in dialogContext. Use Navigator instead to close the dialog.
          Navigator.of(dialogContext).pop();
        },
      );
      final cancelButton = TextButton(
        child: FlowyText(
          cancelButtonTitle ?? LocaleKeys.button_cancel.tr(),
          color: cancelButtonColor ?? foregroundColor,
        ),
        onPressed: () {
          onCancelButtonPressed?.call();
          Navigator.of(dialogContext).pop();
        },
      );

      final actions = switch (actionAlignment) {
        ConfirmDialogActionAlignment.horizontal => [
            actionButton,
            cancelButton,
          ],
        ConfirmDialogActionAlignment.vertical => [
            Column(
              children: [
                actionButton,
                const Divider(height: 1, color: Colors.grey),
                cancelButton,
              ],
            ),
          ],
      };

      return AlertDialog.adaptive(
        title: title,
        content: content,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 4.0,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: actions,
      );
    },
  );
}

Future<T?> showFlowyCupertinoConfirmDialog<T>({
  BuildContext? context,
  required String title,
  required Widget leftButton,
  required Widget rightButton,
  void Function(BuildContext context)? onLeftButtonPressed,
  void Function(BuildContext context)? onRightButtonPressed,
}) {
  return showDialog(
    context: context ?? AppGlobals.context,
    builder: (context) => CupertinoAlertDialog(
      title: FlowyText.medium(
        title,
        fontSize: 18,
        maxLines: 10,
        lineHeight: 1.3,
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            if (onLeftButtonPressed != null) {
              onLeftButtonPressed(context);
            } else {
              Navigator.of(context).pop();
            }
          },
          child: leftButton,
        ),
        CupertinoDialogAction(
          onPressed: () {
            if (onRightButtonPressed != null) {
              onRightButtonPressed(context);
            } else {
              Navigator.of(context).pop();
            }
          },
          child: rightButton,
        ),
      ],
    ),
  );
}
