import 'package:markdown/markdown.dart' as md;

import '../../../../../../../../plugins/document/presentation/editor_plugins/inline_page/inline_page_reference.dart';

class SubPageInlineSyntax extends md.InlineSyntax {
  SubPageInlineSyntax() : super(r'{{AppFlowy-Subpage}}\{(.*?)\}\{(.*?)\}');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final md.Element el = md.Element.text('mention_block', "\$");
    el.attributes[MentionBlockKeys.mention] = '''{
                  "${MentionBlockKeys.type}": "${MentionType.page.name}",
                  "${MentionBlockKeys.pageId}": "${match.group(2)}"
                }''';
    parser.addNode(el);
    return true;
  }
}
