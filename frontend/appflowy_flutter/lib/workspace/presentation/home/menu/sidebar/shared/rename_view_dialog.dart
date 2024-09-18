import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flutter/material.dart';

/// Creates a new view and shows the rename dialog if needed.
///
/// If the user has enabled the setting to show the rename dialog when creating a new view,
/// this function will show the rename dialog.
///
/// Otherwise, it will just create the view with default name.
Future<void> createViewAndShowRenameDialogIfNeeded(
  BuildContext context,
  String dialogTitle,
  void Function(String viewName, BuildContext context) createView,
) async {
  final value = await getIt<KeyValueStorage>().getWithFormat(
    KVKeys.showRenameDialogWhenCreatingNewFile,
    (value) => bool.parse(value),
  );
  final showRenameDialog = value ?? false;
  if (context.mounted && showRenameDialog) {
    await NavigatorTextFieldDialog(
      title: dialogTitle,
      value: '',
      autoSelectAllText: true,
      onConfirm: createView,
    ).show(context);
  } else if (context.mounted) {
    createView('', context);
  }
}
