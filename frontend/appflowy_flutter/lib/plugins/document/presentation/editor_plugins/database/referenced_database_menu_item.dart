import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// Document Reference

SelectionMenuItem referencedDocumentMenuItem = SelectionMenuItem(
  name: LocaleKeys.document_plugins_referencedDocument.tr(),
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.documents_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['page', 'notes', 'referenced page', 'referenced document'],
  handler: (editorState, menuService, context) {
    showLinkToPageMenu(
      Overlay.of(context),
      editorState,
      menuService,
      ViewLayoutPB.Document,
    );
  },
);

// Database References

SelectionMenuItem referencedGridMenuItem = SelectionMenuItem(
  name: LocaleKeys.document_plugins_referencedGrid.tr(),
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.grid_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['referenced', 'grid', 'database'],
  handler: (editorState, menuService, context) {
    final container = Overlay.of(context);
    showLinkToPageMenu(
      container,
      editorState,
      menuService,
      ViewLayoutPB.Grid,
    );
  },
);

SelectionMenuItem referencedBoardMenuItem = SelectionMenuItem(
  name: LocaleKeys.document_plugins_referencedBoard.tr(),
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.board_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['referenced', 'board', 'kanban'],
  handler: (editorState, menuService, context) {
    final container = Overlay.of(context);
    showLinkToPageMenu(
      container,
      editorState,
      menuService,
      ViewLayoutPB.Board,
    );
  },
);

SelectionMenuItem referencedCalendarMenuItem = SelectionMenuItem(
  name: LocaleKeys.document_plugins_referencedCalendar.tr(),
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.date_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['referenced', 'calendar', 'database'],
  handler: (editorState, menuService, context) {
    showLinkToPageMenu(
      Overlay.of(context),
      editorState,
      menuService,
      ViewLayoutPB.Calendar,
    );
  },
);
