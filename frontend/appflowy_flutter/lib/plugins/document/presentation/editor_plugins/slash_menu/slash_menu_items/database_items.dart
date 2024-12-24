import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

import 'slash_menu_item_builder.dart';

final _gridKeywords = ['grid', 'database'];
final _kanbanKeywords = ['board', 'kanban', 'database'];
final _calendarKeywords = ['calendar', 'database'];

final _linkedDocKeywords = [
  'page',
  'notes',
  'referenced page',
  'referenced document',
  'referenced database',
  'link to database',
  'link to document',
  'link to page',
  'link to grid',
  'link to board',
  'link to calendar',
];
final _linkedGridKeywords = [
  'referenced',
  'grid',
  'database',
  'linked',
];
final _linkedKanbanKeywords = [
  'referenced',
  'board',
  'kanban',
  'linked',
];
final _linkedCalendarKeywords = [
  'referenced',
  'calendar',
  'database',
  'linked',
];

/// Grid menu item
SelectionMenuItem gridSlashMenuItem(DocumentBloc documentBloc) {
  return SelectionMenuItem(
    getName: () => LocaleKeys.document_slashMenu_name_grid.tr(),
    keywords: _gridKeywords,
    handler: (editorState, menuService, context) async {
      // create the view inside current page
      final parentViewId = documentBloc.documentId;
      final value = await ViewBackendService.createView(
        parentViewId: parentViewId,
        name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        layoutType: ViewLayoutPB.Grid,
      );
      value.map((r) => editorState.insertInlinePage(parentViewId, r));
    },
    nameBuilder: slashMenuItemNameBuilder,
    icon: (editorState, onSelected, style) => SelectableSvgWidget(
      data: FlowySvgs.slash_menu_icon_grid_s,
      isSelected: onSelected,
      style: style,
    ),
  );
}

SelectionMenuItem kanbanSlashMenuItem(DocumentBloc documentBloc) {
  return SelectionMenuItem(
    getName: () => LocaleKeys.document_slashMenu_name_kanban.tr(),
    keywords: _kanbanKeywords,
    handler: (editorState, menuService, context) async {
      // create the view inside current page
      final parentViewId = documentBloc.documentId;
      final value = await ViewBackendService.createView(
        parentViewId: parentViewId,
        name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        layoutType: ViewLayoutPB.Board,
      );
      value.map((r) => editorState.insertInlinePage(parentViewId, r));
    },
    nameBuilder: slashMenuItemNameBuilder,
    icon: (editorState, onSelected, style) => SelectableSvgWidget(
      data: FlowySvgs.slash_menu_icon_kanban_s,
      isSelected: onSelected,
      style: style,
    ),
  );
}

SelectionMenuItem calendarSlashMenuItem(DocumentBloc documentBloc) {
  return SelectionMenuItem(
    getName: () => LocaleKeys.document_slashMenu_name_calendar.tr(),
    keywords: _calendarKeywords,
    handler: (editorState, menuService, context) async {
      // create the view inside current page
      final parentViewId = documentBloc.documentId;
      final value = await ViewBackendService.createView(
        parentViewId: parentViewId,
        name: LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        layoutType: ViewLayoutPB.Calendar,
      );
      value.map((r) => editorState.insertInlinePage(parentViewId, r));
    },
    nameBuilder: slashMenuItemNameBuilder,
    icon: (editorState, onSelected, style) => SelectableSvgWidget(
      data: FlowySvgs.slash_menu_icon_calendar_s,
      isSelected: onSelected,
      style: style,
    ),
  );
}

// linked doc menu item
final linkToPageSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedDoc.tr(),
  keywords: _linkedDocKeywords,
  handler: (editorState, menuService, context) => showLinkToPageMenu(
    editorState,
    menuService,
    // enable database and document references
    insertPage: false,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_doc_s,
    isSelected: isSelected,
    style: style,
  ),
);

// linked grid & board & calendar menu item
SelectionMenuItem referencedGridSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedGrid.tr(),
  keywords: _linkedGridKeywords,
  handler: (editorState, menuService, context) => showLinkToPageMenu(
    editorState,
    menuService,
    pageType: ViewLayoutPB.Grid,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_grid_s,
    isSelected: onSelected,
    style: style,
  ),
);

SelectionMenuItem referencedKanbanSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedKanban.tr(),
  keywords: _linkedKanbanKeywords,
  handler: (editorState, menuService, context) => showLinkToPageMenu(
    editorState,
    menuService,
    pageType: ViewLayoutPB.Board,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_kanban_s,
    isSelected: onSelected,
    style: style,
  ),
);

SelectionMenuItem referencedCalendarSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedCalendar.tr(),
  keywords: _linkedCalendarKeywords,
  handler: (editorState, menuService, context) => showLinkToPageMenu(
    editorState,
    menuService,
    pageType: ViewLayoutPB.Calendar,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_calendar_s,
    isSelected: onSelected,
    style: style,
  ),
);
