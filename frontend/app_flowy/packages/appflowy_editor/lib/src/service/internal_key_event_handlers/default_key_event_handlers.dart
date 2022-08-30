import 'package:appflowy_editor/src/service/internal_key_event_handlers/copy_paste_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/backspace_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/enter_without_shift_in_text_node_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/arrow_keys_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/redo_undo_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/slash_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/update_text_style_by_command_x_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/whitespace_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/select_all_handler.dart';
import 'package:appflowy_editor/src/service/internal_key_event_handlers/page_up_down_handler.dart';
import 'package:appflowy_editor/src/service/keyboard_service.dart';

List<AppFlowyKeyEventHandler> defaultKeyEventHandlers = [
  deleteTextHandler,
  slashShortcutHandler,
  // arrowKeysHandler,
  arrowKeysHandler,
  copyPasteKeysHandler,
  redoUndoKeysHandler,
  enterWithoutShiftInTextNodesHandler,
  updateTextStyleByCommandXHandler,
  whiteSpaceHandler,
  selectAllHandler,
  pageUpDownHandler,
];
