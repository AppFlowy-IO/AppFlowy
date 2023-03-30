import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/shortcuts/block_shortcut.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/backspace_handler.dart';
import 'package:provider/provider.dart';

BlockShortcutHandler backspaceHandler = (context) {
  final editorState = Provider.of<EditorState>(context, listen: false);
  return backspaceEventHandler(editorState, null);
};
