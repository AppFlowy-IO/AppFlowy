import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

SelectionMenuItem boardMenuItem = SelectionMenuItem(
  name: LocaleKeys.document_plugins_referencedBoard.tr(),
  icon: (editorState, onSelected) => SelectableSvgWidget(
    name: 'editor/board',
    isSelected: onSelected,
  ),
  keywords: ['referenced', 'board', 'kanban'],
  handler: (editorState, menuService, context) {
    showLinkToPageMenu(
      editorState,
      menuService,
      context,
      ViewLayoutPB.Board,
    );
  },
);
