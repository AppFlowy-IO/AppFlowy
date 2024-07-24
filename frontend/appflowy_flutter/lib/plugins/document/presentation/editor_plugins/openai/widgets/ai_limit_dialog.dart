import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';

void showAILimitDialog(BuildContext context, String message) {
  showConfirmDialog(
    context: context,
    title: LocaleKeys.sideBar_aiResponseLimitDialogTitle.tr(),
    description: message,
  );
}
