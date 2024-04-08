import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final List<List<ContextMenuItem>> customContextMenuItems = [
  [
    ContextMenuItem(
      getName: LocaleKeys.document_plugins_contextMenu_copy.tr,
      onPressed: (editorState) => customCopyCommand.execute(editorState),
    ),
    ContextMenuItem(
      getName: LocaleKeys.document_plugins_contextMenu_paste.tr,
      onPressed: (editorState) => customPasteCommand.execute(editorState),
    ),
    ContextMenuItem(
      getName: LocaleKeys.document_plugins_contextMenu_cut.tr,
      onPressed: (editorState) => customCutCommand.execute(editorState),
    ),
  ],
];
