import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class CalloutNodeParser extends NodeParser {
  const CalloutNodeParser();

  @override
  String get id => CalloutBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta ?? Delta()
      ..insert('');
    final String markdown = DeltaMarkdownEncoder()
        .convert(delta)
        .split('\n')
        .map((e) => '> $e')
        .join('\n');
    final type = node.attributes[CalloutBlockKeys.iconType];
    final icon = type == FlowyIconType.emoji.name || type == null || type == ""
        ? node.attributes[CalloutBlockKeys.icon]
        : null;

    final content = icon == null ? markdown : "> $icon\n$markdown";

    return '''
$content

''';
  }
}
