import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

typedef MentionPageNameGetter = Future<String> Function(String pageId);

extension TextDeltaExtension on Delta {
  /// Convert the delta to a text string.
  ///
  /// Unlike the [toPlainText], this method will keep the mention text
  /// such as mentioned page name, mentioned block content.
  ///
  /// If the mentioned page or mentioned block not found, it will downgrade to
  /// the default plain text.
  Future<String> toText({
    required MentionPageNameGetter getMentionPageName,
  }) async {
    final defaultPlainText = toPlainText();

    String text = '';
    final ops = iterator;
    while (ops.moveNext()) {
      final op = ops.current;
      final attributes = op.attributes;
      if (op is TextInsert) {
        // if the text is '\$', it means the block text is empty,
        //  the real data is in the attributes
        if (op.text == MentionBlockKeys.mentionChar) {
          final mention = attributes?[MentionBlockKeys.mention];
          final mentionPageId = mention?[MentionBlockKeys.pageId];
          if (mentionPageId != null) {
            text += await getMentionPageName(mentionPageId);
            continue;
          }
        }

        text += op.text;
      } else {
        // if the delta contains other types of operations,
        // return the default plain text
        return defaultPlainText;
      }
    }

    return text;
  }
}
