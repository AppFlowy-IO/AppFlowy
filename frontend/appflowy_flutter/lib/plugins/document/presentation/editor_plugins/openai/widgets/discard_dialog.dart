import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';

import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import 'package:easy_localization/easy_localization.dart';

class DiscardDialog extends StatelessWidget {
  const DiscardDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return NavigatorOkCancelDialog(
      message: LocaleKeys.document_plugins_discardResponse.tr(),
      okTitle: LocaleKeys.button_discard.tr(),
      cancelTitle: LocaleKeys.button_cancel.tr(),
      onOkPressed: onConfirm,
      onCancelPressed: onCancel,
    );
  }
}
