import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

SelectionMenuItem inlineGridMenuItem(DocumentBloc documentBloc) =>
    SelectionMenuItem(
      getName: LocaleKeys.document_slashMenu_grid_createANewGrid.tr,
      icon: (editorState, onSelected, style) => SelectableSvgWidget(
        data: FlowySvgs.grid_s,
        isSelected: onSelected,
        style: style,
      ),
      keywords: ['grid', 'database'],
      handler: (editorState, menuService, context) async {
        // create the view inside current page
        final parentViewId = documentBloc.view.id;
        final value = await ViewBackendService.createView(
          parentViewId: parentViewId,
          name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          layoutType: ViewLayoutPB.Grid,
        );
        value.map((r) => editorState.insertInlinePage(parentViewId, r));
      },
    );

SelectionMenuItem inlineBoardMenuItem(DocumentBloc documentBloc) =>
    SelectionMenuItem(
      getName: LocaleKeys.document_slashMenu_board_createANewBoard.tr,
      icon: (editorState, onSelected, style) => SelectableSvgWidget(
        data: FlowySvgs.board_s,
        isSelected: onSelected,
        style: style,
      ),
      keywords: ['board', 'kanban', 'database'],
      handler: (editorState, menuService, context) async {
        // create the view inside current page
        final parentViewId = documentBloc.view.id;
        final value = await ViewBackendService.createView(
          parentViewId: parentViewId,
          name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          layoutType: ViewLayoutPB.Board,
        );
        value.map((r) => editorState.insertInlinePage(parentViewId, r));
      },
    );

SelectionMenuItem inlineCalendarMenuItem(DocumentBloc documentBloc) =>
    SelectionMenuItem(
      getName: LocaleKeys.document_slashMenu_calendar_createANewCalendar.tr,
      icon: (editorState, onSelected, style) => SelectableSvgWidget(
        data: FlowySvgs.date_s,
        isSelected: onSelected,
        style: style,
      ),
      keywords: ['calendar', 'database'],
      handler: (editorState, menuService, context) async {
        // create the view inside current page
        final parentViewId = documentBloc.view.id;
        final value = await ViewBackendService.createView(
          parentViewId: parentViewId,
          name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
          layoutType: ViewLayoutPB.Calendar,
        );
        value.map((r) => editorState.insertInlinePage(parentViewId, r));
      },
    );
