import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:easy_localization/easy_localization.dart';

SelectionMenuItem inlineBoardMenuItem(DocumentBloc documentBloc) =>
    SelectionMenuItem(
      name: LocaleKeys.document_slashMenu_board_createANewBoard.tr(),
      icon: (editorState, onSelected, style) => SelectableSvgWidget(
        name: 'editor/board',
        isSelected: onSelected,
        style: style,
      ),
      keywords: ['board', 'kanban', 'database'],
      handler: (editorState, menuService, context) async {
        if (!documentBloc.view.hasParentViewId()) {
          return;
        }

        final parentViewId = documentBloc.view.parentViewId;
        ViewBackendService.createView(
          parentViewId: parentViewId,
          name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          layoutType: ViewLayoutPB.Board,
        ).then(
          (value) => value
              .swap()
              .map((r) => editorState.insertInlinePage(parentViewId, r)),
        );
      },
    );
