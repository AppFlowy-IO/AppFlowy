import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-ai/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../ai_writer_block_component.dart';

const kdefaultReplacementType = AskAIReplacementType.markdown;

enum AskAIReplacementType {
  markdown,
  plainText,
}

enum SuggestionAction {
  accept,
  discard,
  close,
  tryAgain,
  rewrite,
  keep,
  insertBelow;

  String get i18n => switch (this) {
        accept => LocaleKeys.suggestion_accept.tr(),
        discard => LocaleKeys.suggestion_discard.tr(),
        close => LocaleKeys.suggestion_close.tr(),
        tryAgain => LocaleKeys.suggestion_tryAgain.tr(),
        rewrite => LocaleKeys.suggestion_rewrite.tr(),
        keep => LocaleKeys.suggestion_keep.tr(),
        insertBelow => LocaleKeys.suggestion_insertBelow.tr(),
      };

  FlowySvg buildIcon(BuildContext context) {
    final icon = switch (this) {
      accept || keep => FlowySvgs.ai_fix_spelling_grammar_s,
      discard || close => FlowySvgs.toast_close_s,
      tryAgain || rewrite => FlowySvgs.ai_try_again_s,
      insertBelow => FlowySvgs.suggestion_insert_below_s,
    };

    return FlowySvg(
      icon,
      size: Size.square(16.0),
      color: switch (this) {
        accept || keep => Color(0xFF278E42),
        discard || close => Color(0xFFC40055),
        _ => Theme.of(context).iconTheme.color,
      },
    );
  }
}

enum AiWriterCommand {
  userQuestion,
  explain,
  // summarize,
  continueWriting,
  fixSpellingAndGrammar,
  improveWriting,
  makeShorter,
  makeLonger;

  String defaultPrompt(String input) => switch (this) {
        userQuestion => input,
        explain => "Explain this phrase in a concise manner:\n\n$input",
        // summarize => '$input\n\nTl;dr',
        continueWriting =>
          'Continue writing based on this existing text:\n\n$input',
        fixSpellingAndGrammar => 'Correct this to standard English:\n\n$input',
        improveWriting => 'Rewrite this in your own words:\n\n$input',
        makeShorter => 'Make this text shorter:\n\n$input',
        makeLonger => 'Make this text longer:\n\n$input',
      };

  String get i18n => switch (this) {
        userQuestion => LocaleKeys.document_plugins_aiWriter_userQuestion.tr(),
        explain => LocaleKeys.document_plugins_aiWriter_explain.tr(),
        // summarize => LocaleKeys.document_plugins_aiWriter_summarize.tr(),
        continueWriting =>
          LocaleKeys.document_plugins_aiWriter_continueWriting.tr(),
        fixSpellingAndGrammar =>
          LocaleKeys.document_plugins_aiWriter_fixSpelling.tr(),
        improveWriting =>
          LocaleKeys.document_plugins_smartEditImproveWriting.tr(),
        makeShorter => LocaleKeys.document_plugins_aiWriter_makeShorter.tr(),
        makeLonger => LocaleKeys.document_plugins_aiWriter_makeLonger.tr(),
      };

  FlowySvgData get icon => switch (this) {
        userQuestion => FlowySvgs.toolbar_ai_ask_anything_m,
        explain => FlowySvgs.toolbar_ai_explain_m,
        // summarize => FlowySvgs.ai_summarize_s,
        continueWriting ||
        improveWriting =>
          FlowySvgs.toolbar_ai_improve_writing_m,
        fixSpellingAndGrammar => FlowySvgs.toolbar_ai_fix_spelling_grammar_m,
        makeShorter => FlowySvgs.toolbar_ai_make_shorter_m,
        makeLonger => FlowySvgs.toolbar_ai_make_longer_m,
      };

  CompletionTypePB toCompletionType() => switch (this) {
        userQuestion => CompletionTypePB.UserQuestion,
        explain => CompletionTypePB.ExplainSelected,
        // summarize => CompletionTypePB.Summarize,
        continueWriting => CompletionTypePB.ContinueWriting,
        fixSpellingAndGrammar => CompletionTypePB.SpellingAndGrammar,
        improveWriting => CompletionTypePB.ImproveWriting,
        makeShorter => CompletionTypePB.MakeShorter,
        makeLonger => CompletionTypePB.MakeLonger,
      };
}

enum ApplySuggestionFormatType {
  original(AiWriterBlockKeys.suggestionOriginal),
  replace(AiWriterBlockKeys.suggestionReplacement),
  clear(null);

  const ApplySuggestionFormatType(this.value);
  final String? value;

  Map<String, dynamic> get attributes => {AiWriterBlockKeys.suggestion: value};
}

enum AiRole {
  user,
  system,
  ai,
}

class AiWriterRecord extends Equatable {
  const AiWriterRecord.user({
    required this.content,
    required this.format,
  }) : role = AiRole.user;

  const AiWriterRecord.ai({
    required this.content,
  })  : role = AiRole.ai,
        format = null;

  final AiRole role;
  final String content;
  final PredefinedFormat? format;

  @override
  List<Object?> get props => [role, content, format];

  CompletionRecordPB toPB() {
    return CompletionRecordPB(
      content: content,
      role: switch (role) {
        AiRole.user => ChatMessageTypePB.User,
        AiRole.system || AiRole.ai => ChatMessageTypePB.System,
      },
    );
  }
}
