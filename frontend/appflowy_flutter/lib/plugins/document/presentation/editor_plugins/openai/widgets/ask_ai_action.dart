import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum AskAIAction {
  summarize,
  fixSpelling,
  improveWriting,
  makeItLonger;

  String get toInstruction {
    switch (this) {
      case AskAIAction.summarize:
        return 'Tl;dr';
      case AskAIAction.fixSpelling:
        return 'Correct this to standard English:';
      case AskAIAction.improveWriting:
        return 'Rewrite this in your own words:';
      case AskAIAction.makeItLonger:
        return 'Make this text longer:';
    }
  }

  String prompt(String input) {
    switch (this) {
      case AskAIAction.summarize:
        return '$input\n\nTl;dr';
      case AskAIAction.fixSpelling:
        return 'Correct this to standard English:\n\n$input';
      case AskAIAction.improveWriting:
        return 'Rewrite this:\n\n$input';
      case AskAIAction.makeItLonger:
        return 'Make this text longer:\n\n$input';
    }
  }

  static AskAIAction from(int index) {
    switch (index) {
      case 0:
        return AskAIAction.summarize;
      case 1:
        return AskAIAction.fixSpelling;
      case 2:
        return AskAIAction.improveWriting;
      case 3:
        return AskAIAction.makeItLonger;
    }
    return AskAIAction.fixSpelling;
  }

  String get name {
    switch (this) {
      case AskAIAction.summarize:
        return LocaleKeys.document_plugins_smartEditSummarize.tr();
      case AskAIAction.fixSpelling:
        return LocaleKeys.document_plugins_smartEditFixSpelling.tr();
      case AskAIAction.improveWriting:
        return LocaleKeys.document_plugins_smartEditImproveWriting.tr();
      case AskAIAction.makeItLonger:
        return LocaleKeys.document_plugins_smartEditMakeLonger.tr();
    }
  }
}

class AskAIActionWrapper extends ActionCell {
  AskAIActionWrapper(this.inner);

  final AskAIAction inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    return inner.name;
  }
}
