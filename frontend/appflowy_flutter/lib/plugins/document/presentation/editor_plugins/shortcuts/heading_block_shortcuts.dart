import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Convert '# ' to bulleted list
///
/// - support
///   - desktop
///   - mobile
///   - web
///
CharacterShortcutEvent customFormatSignToHeading = CharacterShortcutEvent(
  key: 'format sign to heading list',
  character: ' ',
  handler: (editorState) async => formatMarkdownSymbol(
    editorState,
    (node) => true,
    (_, text, selection) {
      final characters = text.split('');
      // only supports h1 to h6 levels
      // if the characters is empty, the every function will return true directly
      return characters.isNotEmpty &&
          characters.every((element) => element == '#') &&
          characters.length < 7;
    },
    (text, node, delta) {
      final numberOfSign = text.split('').length;
      final type = node.type;
      final level = node.attributes[ToggleListBlockKeys.level] as int?;

      // if current node is toggle heading block, if so, keep the toggle heading block type.
      if (type == ToggleListBlockKeys.type && level != null) {
        final collapsed =
            node.attributes[ToggleListBlockKeys.collapsed] as bool?;
        return [
          toggleHeadingNode(
            level: numberOfSign,
            delta: delta.compose(Delta()..delete(numberOfSign)),
            collapsed: collapsed ?? false,
          ),
        ];
      }
      return [
        headingNode(
          level: numberOfSign,
          delta: delta.compose(Delta()..delete(numberOfSign)),
        ),
        if (node.children.isNotEmpty) ...node.children,
      ];
    },
  ),
);
