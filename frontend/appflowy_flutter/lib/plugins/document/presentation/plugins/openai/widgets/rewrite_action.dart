import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

enum RewriteAction {
  continueWriting,
  makeTextLonger,
  editPrompt;

  String get toInstruction {
    switch (this) {
      case RewriteAction.continueWriting:
        return 'Tl;dr';
      case RewriteAction.makeTextLonger:
        return 'Correct this to standard English:';
      case RewriteAction.editPrompt:
        return 'Rewrite this in your own words:';
    }
  }

  String prompt(String input) {
    switch (this) {
      case RewriteAction.continueWriting:
        return 'Continue to write after this:\n\n $input';
      case RewriteAction.makeTextLonger:
        return 'Make this text longer:\n\n$input';
      case RewriteAction.editPrompt:
        return input;
    }
  }

  static RewriteAction from(int index) {
    switch (index) {
      case 0:
        return RewriteAction.continueWriting;
      case 1:
        return RewriteAction.makeTextLonger;
      case 2:
    }
    return RewriteAction.makeTextLonger;
  }

  String get name {
    switch (this) {
      case RewriteAction.continueWriting:
        return LocaleKeys.document_plugins_rewriteActionContinueWriting.tr();
      case RewriteAction.makeTextLonger:
        return LocaleKeys.document_plugins_rewriteActionMakeTextLonger.tr();
      case RewriteAction.editPrompt:
        return LocaleKeys.document_plugins_rewriteActionEditPrompt.tr();
    }
  }
}

class RewriteActionWrapper extends ActionCell {
  final RewriteAction inner;

  RewriteActionWrapper(this.inner);

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    return inner.name;
  }
}
