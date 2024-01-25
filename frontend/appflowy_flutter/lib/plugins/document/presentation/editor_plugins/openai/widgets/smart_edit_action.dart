import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

enum SmartEditAction {
  summarize,
  fixSpelling,
  improveWriting,
  makeItLonger;

  String get toInstruction {
    switch (this) {
      case SmartEditAction.summarize:
        return 'Tl;dr';
      case SmartEditAction.fixSpelling:
        return 'Correct this to standard English:';
      case SmartEditAction.improveWriting:
        return 'Rewrite this in your own words:';
      case SmartEditAction.makeItLonger:
        return 'Make this text longer:';
    }
  }

  String prompt(String input) {
    switch (this) {
      case SmartEditAction.summarize:
        return '$input\n\nTl;dr';
      case SmartEditAction.fixSpelling:
        return 'Correct this to standard English:\n\n$input';
      case SmartEditAction.improveWriting:
        return 'Rewrite this:\n\n$input';
      case SmartEditAction.makeItLonger:
        return 'Make this text longer:\n\n$input';
    }
  }

  static SmartEditAction from(int index) {
    switch (index) {
      case 0:
        return SmartEditAction.summarize;
      case 1:
        return SmartEditAction.fixSpelling;
      case 2:
        return SmartEditAction.improveWriting;
      case 3:
        return SmartEditAction.makeItLonger;
    }
    return SmartEditAction.fixSpelling;
  }

  String get name {
    switch (this) {
      case SmartEditAction.summarize:
        return LocaleKeys.document_plugins_smartEditSummarize.tr();
      case SmartEditAction.fixSpelling:
        return LocaleKeys.document_plugins_smartEditFixSpelling.tr();
      case SmartEditAction.improveWriting:
        return LocaleKeys.document_plugins_smartEditImproveWriting.tr();
      case SmartEditAction.makeItLonger:
        return LocaleKeys.document_plugins_smartEditMakeLonger.tr();
    }
  }
}

class SmartEditActionWrapper extends ActionCell {
  SmartEditActionWrapper(this.inner);

  final SmartEditAction inner;

  Widget? icon(Color iconColor) => null;

  @override
  String get name {
    return inner.name;
  }
}
