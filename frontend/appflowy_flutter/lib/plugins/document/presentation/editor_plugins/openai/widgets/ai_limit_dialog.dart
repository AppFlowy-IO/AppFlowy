import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class _AILimitDialog extends StatelessWidget {
  const _AILimitDialog({
    required this.message,
    required this.onOkPressed,
  });
  final VoidCallback onOkPressed;
  final String message;

  @override
  Widget build(BuildContext context) {
    return NavigatorOkCancelDialog(
      message: message,
      okTitle: LocaleKeys.button_ok.tr(),
      onOkPressed: onOkPressed,
      titleUpperCase: false,
    );
  }
}

void showAILimitDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    useRootNavigator: false,
    builder: (dialogContext) => _AILimitDialog(
      message: message,
      onOkPressed: () {},
    ),
  );
}
