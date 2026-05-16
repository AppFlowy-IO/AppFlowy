import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Convert 'num. ' to bulleted list
///
/// - support
///   - desktop
///   - mobile
///
/// In heading block and toggle heading block, this shortcut will be ignored.
CharacterShortcutEvent customFormatNumberToNumberedList =
    CharacterShortcutEvent(
  key: 'format number to numbered list',
  character: ' ',
  handler: (editorState) async => formatMarkdownSymbol(
    editorState,
    (node) => node.type != NumberedListBlockKeys.type,
    (node, text, selection) {
      final shouldBeIgnored = _shouldBeIgnored(node);
      if (shouldBeIgnored) {
        return false;
      }

      final match = numberedListRegex.firstMatch(text);
      if (match == null) {
        return false;
      }

      final matchText = match.group(0);
      final numberText = match.group(1);

      if (matchText == null || numberText == null) {
        return false;
      }

      // if the previous one is numbered list,
      // we should check the current number is the next number of the previous one
      Node? previous = node.previous;
      int level = 0;
      int? startNumber;
      while (previous != null && previous.type == NumberedListBlockKeys.type) {
        startNumber = previous.attributes[NumberedListBlockKeys.number] as int?;
        level++;
        previous = previous.previous;
      }
      if (startNumber != null) {
        final currentNumber = int.tryParse(numberText);
        if (currentNumber == null || currentNumber != startNumber + level) {
          return false;
        }
      }

      return selection.endIndex == matchText.length;
    },
    (text, node, delta) {
      final match = numberedListRegex.firstMatch(text);
      final matchText = match?.group(0);
      if (matchText == null) {
        return [node];
      }

      final number = matchText.substring(0, matchText.length - 1);
      final composedDelta = delta.compose(
        Delta()..delete(matchText.length),
      );
      return [
        node.copyWith(
          type: NumberedListBlockKeys.type,
          attributes: {
            NumberedListBlockKeys.delta: composedDelta.toJson(),
            NumberedListBlockKeys.number: int.tryParse(number),
          },
        ),
      ];
    },
  ),
);

bool _shouldBeIgnored(Node node) {
  final type = node.type;

  // ignore heading block
  if (type == HeadingBlockKeys.type) {
    return true;
  }

  // ignore toggle heading block
  final level = node.attributes[ToggleListBlockKeys.level] as int?;
  if (type == ToggleListBlockKeys.type && level != null) {
    return true;
  }

  return false;
}
