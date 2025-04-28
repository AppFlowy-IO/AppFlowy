import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/widgets.dart';

final openingBracketReplacement = String.fromCharCode(0xFFFE);
final closingBracketReplacement = String.fromCharCode(0xFFFD);

class AiPromptInputTextEditingController extends TextEditingController {
  AiPromptInputTextEditingController();

  static String replace(String text) {
    return text
        .replaceAll('[', openingBracketReplacement)
        .replaceAll(']', closingBracketReplacement);
  }

  static String restore(String text) {
    return text
        .replaceAll(openingBracketReplacement, '[')
        .replaceAll(closingBracketReplacement, ']');
  }

  void usePrompt(String content) {
    value = TextEditingValue(
      text: content,
      selection: TextSelection.collapsed(
        offset: content.length,
      ),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(
      style: style,
      children: <InlineSpan>[...getTextSpans(context)],
    );
  }

  Iterable<TextSpan> getTextSpans(BuildContext context) {
    final open = openingBracketReplacement;
    final close = closingBracketReplacement;
    final regex = RegExp('($open[^$open$close]*?$close)');
    final theme = AppFlowyTheme.of(context);

    final result = <TextSpan>[];

    text.splitMapJoin(
      regex,
      onMatch: (match) {
        final string = match.group(0)!;
        result.add(
          TextSpan(
            text: restore(string),
            style: theme.textStyle.body.standard().copyWith(
                  color: theme.textColorScheme.purple,
                  backgroundColor:
                      theme.fillColorScheme.purpleLight.withAlpha(128),
                ),
          ),
        );
        return '';
      },
      onNonMatch: (nonMatch) {
        result.add(
          TextSpan(
            text: restore(nonMatch),
          ),
        );
        return '';
      },
    );

    return result;
  }
}
