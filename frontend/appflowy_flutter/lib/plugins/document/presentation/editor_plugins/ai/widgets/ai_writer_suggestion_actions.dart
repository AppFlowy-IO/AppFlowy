import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../operations/ai_writer_entities.dart';

class SuggestionActionBar extends StatelessWidget {
  const SuggestionActionBar({
    super.key,
    required this.currentCommand,
    required this.hasSelection,
    required this.onTap,
  });

  final AiWriterCommand currentCommand;
  final bool hasSelection;
  final void Function(SuggestionAction) onTap;

  @override
  Widget build(BuildContext context) {
    return SeparatedRow(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () => const HSpace(4.0),
      children: _getSuggestedActions()
          .map(
            (action) => SuggestionActionButton(
              action: action,
              onTap: () => onTap(action),
            ),
          )
          .toList(),
    );
  }

  List<SuggestionAction> _getSuggestedActions() {
    if (hasSelection) {
      return switch (currentCommand) {
        AiWriterCommand.userQuestion || AiWriterCommand.continueWriting => [
            SuggestionAction.keep,
            SuggestionAction.discard,
            SuggestionAction.rewrite,
          ],
        AiWriterCommand.explain => [
            SuggestionAction.insertBelow,
            SuggestionAction.tryAgain,
            SuggestionAction.close,
          ],
        AiWriterCommand.fixSpellingAndGrammar ||
        AiWriterCommand.improveWriting ||
        AiWriterCommand.makeShorter ||
        AiWriterCommand.makeLonger =>
          [
            SuggestionAction.accept,
            SuggestionAction.discard,
            SuggestionAction.insertBelow,
            SuggestionAction.rewrite,
          ],
      };
    } else {
      return switch (currentCommand) {
        AiWriterCommand.userQuestion || AiWriterCommand.continueWriting => [
            SuggestionAction.keep,
            SuggestionAction.discard,
            SuggestionAction.rewrite,
          ],
        AiWriterCommand.explain => [
            SuggestionAction.insertBelow,
            SuggestionAction.tryAgain,
            SuggestionAction.close,
          ],
        _ => [
            SuggestionAction.keep,
            SuggestionAction.discard,
            SuggestionAction.rewrite,
          ],
      };
    }
  }
}

class SuggestionActionButton extends StatelessWidget {
  const SuggestionActionButton({
    super.key,
    required this.action,
    required this.onTap,
  });

  final SuggestionAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FlowyButton(
        text: FlowyText(
          action.i18n,
          figmaLineHeight: 20,
        ),
        leftIcon: action.buildIcon(context),
        iconPadding: 4.0,
        margin: const EdgeInsets.symmetric(
          horizontal: 6.0,
          vertical: 4.0,
        ),
        onTap: onTap,
        useIntrinsicWidth: true,
      ),
    );
  }
}
