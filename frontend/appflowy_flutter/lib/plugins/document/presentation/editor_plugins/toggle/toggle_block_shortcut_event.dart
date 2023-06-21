import 'package:appflowy/plugins/document/presentation/editor_plugins/toggle/toggle_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const _greater = '>';

/// Convert '> ' to toggle list
///
/// - support
///   - desktop
///   - mobile
///   - web
///
CharacterShortcutEvent formatGreaterToToggleList = CharacterShortcutEvent(
  key: 'format greater to quote',
  character: ' ',
  handler: (editorState) async => await formatMarkdownSymbol(
    editorState,
    (node) => node.type != ToggleListBlockKeys.type,
    (_, text, __) => text == _greater,
    (_, node, delta) => toggleListBlockNode(
      delta: delta.compose(Delta()..delete(_greater.length)),
    ),
  ),
);
