import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

enum ToggleListExportStyle {
  github,
  markdown,
}

class ToggleListNodeParser extends NodeParser {
  const ToggleListNodeParser({
    this.exportStyle = ToggleListExportStyle.markdown,
  });

  final ToggleListExportStyle exportStyle;

  @override
  String get id => ToggleListBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final delta = node.delta ?? Delta()
      ..insert('');
    String markdown = DeltaMarkdownEncoder().convert(delta);
    final details = encoder?.convertNodes(
      node.children,
      withIndent: true,
    );
    switch (exportStyle) {
      case ToggleListExportStyle.github:
        return '''<details>
<summary>$markdown</summary>

$details
</details>
''';
      case ToggleListExportStyle.markdown:
        markdown = '- $markdown\n';
        if (details != null && details.isNotEmpty) {
          markdown += details;
        }
        return markdown;
    }
  }
}
