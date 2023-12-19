import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';

void showConfirmationDialog({
  required BuildContext context,
  required String title,
  required VoidCallback onConfirm,
}) {
  NavigatorAlertDialog(
    title: title,
    confirm: () {
      onConfirm();
    },
    cancel: () {},
  ).show(context);
}
