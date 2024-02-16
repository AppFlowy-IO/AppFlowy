import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

///show the dialog to confirm one single action
///[onActionButtonPressed] and [onCancelButtonPressed] end with close the dialog
Future<T?> showFlowyMobileConfirmDialog<T>(
  BuildContext context, {
  Widget? title,
  Widget? content,
  required String actionButtonTitle,
  Color? actionButtonColor,
  String? cancelButtonTitle,
  required void Function()? onActionButtonPressed,
  void Function()? onCancelButtonPressed,
}) async {
  return showDialog(
    context: context,
    builder: (dialogContext) {
      final foregroundColor = Theme.of(context).colorScheme.onSurface;
      return AlertDialog.adaptive(
        title: title,
        content: content,
        actions: [
          TextButton(
            child: Text(
              actionButtonTitle,
              style: TextStyle(
                color: actionButtonColor ?? foregroundColor,
              ),
            ),
            onPressed: () {
              onActionButtonPressed?.call();
              // we cannot use dialogContext.pop() here because this is no GoRouter in dialogContext. Use Navigator instead to close the dialog.
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: Text(
              cancelButtonTitle ?? LocaleKeys.button_cancel.tr(),
              style: TextStyle(
                color: foregroundColor,
              ),
            ),
            onPressed: () {
              onCancelButtonPressed?.call();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}
