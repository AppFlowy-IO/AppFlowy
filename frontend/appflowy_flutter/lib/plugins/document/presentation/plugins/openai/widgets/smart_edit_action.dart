import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

enum SmartEditAction {
  summarize,
  fixSpelling;

  String get toInstruction {
    switch (this) {
      case SmartEditAction.summarize:
        return 'Summarize';
      case SmartEditAction.fixSpelling:
        return 'Fix the spelling mistakes';
    }
  }
}

class SmartEditActionWrapper extends ActionCell {
  final SmartEditAction inner;

  SmartEditActionWrapper(this.inner);

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    switch (inner) {
      case SmartEditAction.summarize:
        return LocaleKeys.document_plugins_smartEditSummarize.tr();
      case SmartEditAction.fixSpelling:
        return LocaleKeys.document_plugins_smartEditFixSpelling.tr();
    }
  }
}
