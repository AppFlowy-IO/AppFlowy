import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/slash_menu_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_menu_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';

// text menu item
final textSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_text.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_text_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['text', 'paragraph'],
  handler: (editorState, _, __) {
    insertNodeAfterSelection(editorState, paragraphNode());
  },
);

// heading 1 - 3 menu items
final heading1SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_heading1.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_h1_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['heading 1', 'h1', 'heading1'],
  handler: (editorState, _, __) {
    insertHeadingAfterSelection(editorState, 1);
  },
);

final heading2SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_heading2.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_h2_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['heading 2', 'h2', 'heading2'],
  handler: (editorState, _, __) {
    insertHeadingAfterSelection(editorState, 2);
  },
);

final heading3SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_heading3.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_h3_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['heading 3', 'h3', 'heading3'],
  handler: (editorState, _, __) {
    insertHeadingAfterSelection(editorState, 3);
  },
);

// image menu item
final imageSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_image.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_image_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['image', 'photo', 'picture', 'img'],
  handler: (editorState, menuService, context) async {
    // use the key to retrieve the state of the image block to show the popover automatically
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await editorState.insertEmptyImageBlock(imagePlaceholderKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      imagePlaceholderKey.currentState?.controller.show();
    });
  },
);

// bulleted list menu item
final bulletedListSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_bulletedList.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_bulleted_list_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['bulleted list', 'list', 'unordered list'],
  handler: (editorState, _, __) {
    insertBulletedListAfterSelection(editorState);
  },
);

// numbered list menu item
final numberedListSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_numberedList.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_numbered_list_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['numbered list', 'list', 'ordered list'],
  handler: (editorState, _, __) {
    insertNumberedListAfterSelection(editorState);
  },
);

// todo list menu item
final todoListSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_todoList.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_checkbox_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['checkbox', 'todo', 'list', 'to-do', 'task'],
  handler: (editorState, _, __) {
    insertCheckboxAfterSelection(editorState);
  },
);

// quote menu item
final quoteSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_quote.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_quote_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['quote', 'refer', 'blockquote', 'citation'],
  handler: (editorState, _, __) {
    insertQuoteAfterSelection(editorState);
  },
);

// divider menu item
final dividerSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_divider.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_divider_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['divider', 'separator', 'line', 'break', 'horizontal line'],
  handler: (editorState, _, __) {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final path = selection.end.path;
    final node = editorState.getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = editorState.transaction
      ..insertNode(insertedPath, dividerNode())
      ..insertNode(insertedPath, paragraphNode())
      ..afterSelection = Selection.collapsed(Position(path: insertedPath.next));
    editorState.apply(transaction);
  },
);

// grid & board & calendar menu item
SelectionMenuItem gridSlashMenuItem(DocumentBloc documentBloc) {
  return SelectionMenuItem(
    getName: () => LocaleKeys.document_slashMenu_name_grid.tr(),
    nameBuilder: _slashMenuItemNameBuilder,
    icon: (editorState, onSelected, style) => SelectableSvgWidget(
      data: FlowySvgs.slash_menu_icon_grid_s,
      isSelected: onSelected,
      style: style,
    ),
    keywords: ['grid', 'database'],
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
  );
}

SelectionMenuItem kanbanSlashMenuItem(DocumentBloc documentBloc) {
  return SelectionMenuItem(
    getName: () => LocaleKeys.document_slashMenu_name_kanban.tr(),
    nameBuilder: _slashMenuItemNameBuilder,
    icon: (editorState, onSelected, style) => SelectableSvgWidget(
      data: FlowySvgs.slash_menu_icon_kanban_s,
      isSelected: onSelected,
      style: style,
    ),
    keywords: ['board', 'kanban', 'database'],
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
  );
}

SelectionMenuItem calendarSlashMenuItem(DocumentBloc documentBloc) {
  return SelectionMenuItem(
    getName: () => LocaleKeys.document_slashMenu_name_calendar.tr(),
    nameBuilder: _slashMenuItemNameBuilder,
    icon: (editorState, onSelected, style) => SelectableSvgWidget(
      data: FlowySvgs.slash_menu_icon_calendar_s,
      isSelected: onSelected,
      style: style,
    ),
    keywords: ['calendar', 'database'],
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
  );
}

// linked doc menu item
final referencedDocSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedDoc.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_doc_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: [
    'page',
    'notes',
    'referenced page',
    'referenced document',
    'link to page',
  ],
  handler: (editorState, menuService, context) => showLinkToPageMenu(
    editorState,
    menuService,
    ViewLayoutPB.Document,
  ),
);

// linked grid & board & calendar menu item
SelectionMenuItem referencedGridSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedGrid.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_grid_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['referenced', 'grid', 'database', 'linked'],
  handler: (editorState, menuService, context) =>
      showLinkToPageMenu(editorState, menuService, ViewLayoutPB.Grid),
);

SelectionMenuItem referencedKanbanSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedKanban.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_kanban_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['referenced', 'board', 'kanban', 'linked'],
  handler: (editorState, menuService, context) =>
      showLinkToPageMenu(editorState, menuService, ViewLayoutPB.Board),
);

SelectionMenuItem referencedCalendarSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_linkedCalendar.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_calendar_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['referenced', 'calendar', 'database', 'linked'],
  handler: (editorState, menuService, context) =>
      showLinkToPageMenu(editorState, menuService, ViewLayoutPB.Calendar),
);

// callout menu item
SelectionMenuItem calloutSlashMenuItem = SelectionMenuItem.node(
  getName: LocaleKeys.document_plugins_callout.tr,
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_callout_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: [CalloutBlockKeys.type],
  nodeBuilder: (editorState, context) =>
      calloutNode(defaultColor: Colors.transparent),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  updateSelection: (_, path, __, ___) {
    return Selection.single(path: path, startOffset: 0);
  },
);

// outline menu item
SelectionMenuItem outlineSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_outline.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_outline_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['outline', 'table of contents'],
  nodeBuilder: (editorState, _) => outlineBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

// math equation
SelectionMenuItem mathEquationSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_mathEquation.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_math_equation_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['tex', 'latex', 'katex', 'math equation', 'formula'],
  nodeBuilder: (editorState, _) => mathEquationNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  updateSelection: (editorState, path, __, ___) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState =
          editorState.getNodeAtPath(path)?.key.currentState;
      if (mathEquationState != null &&
          mathEquationState is MathEquationBlockComponentWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });
    return null;
  },
);

// code block menu item
SelectionMenuItem codeBlockSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_code.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_code_block_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['code', 'code block'],
  nodeBuilder: (_, __) => codeBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

// toggle menu item
SelectionMenuItem toggleListSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_toggleList.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_toggle_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['collapsed list', 'toggle list', 'list', 'dropdown'],
  nodeBuilder: (editorState, _) => toggleListBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);

// emoji menu item
SelectionMenuItem emojiSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_emoji.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_emoji_picker_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['emoji', 'reaction', 'emoticon'],
  handler: (editorState, menuService, context) {
    final container = Overlay.of(context);
    menuService.dismiss();
    showEmojiPickerMenu(
      container,
      editorState,
      menuService.alignment,
      menuService.offset,
    );
  },
);

// auto generate menu item
SelectionMenuItem aiWriterSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_aiWriter.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_ai_writer_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['ai', 'openai', 'writer', 'ai writer', 'autogenerator'],
  nodeBuilder: (editorState, _) {
    final node = autoCompletionNode(start: editorState.selection!);
    return node;
  },
  replace: (_, node) => false,
);

// table menu item
SelectionMenuItem tableSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_table.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_simple_table_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['table', 'rows', 'columns', 'data'],
  handler: (editorState, _, __) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final currentNode = editorState.getNodeAtPath(selection.end.path);
    if (currentNode == null) {
      return;
    }

    final tableNode = TableNode.fromList([
      ['', ''],
      ['', ''],
    ]);

    final transaction = editorState.transaction;
    final delta = currentNode.delta;
    if (delta != null && delta.isEmpty) {
      transaction
        ..insertNode(selection.end.path, tableNode.node)
        ..deleteNode(currentNode);
      transaction.afterSelection = Selection.collapsed(
        Position(
          path: selection.end.path + [0, 0],
        ),
      );
    } else {
      transaction.insertNode(selection.end.path.next, tableNode.node);
      transaction.afterSelection = Selection.collapsed(
        Position(
          path: selection.end.path.next + [0, 0],
        ),
      );
    }

    await editorState.apply(transaction);
  },
);

// date or reminder menu item
SelectionMenuItem dateOrReminderSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_dateOrReminder.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_date_or_reminder_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['insert date', 'date', 'time', 'reminder', 'schedule'],
  handler: (editorState, menuService, context) =>
      insertDateReference(editorState),
);

// photo gallery menu item
SelectionMenuItem photoGallerySlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_photoGallery.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_photo_gallery_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: [
    LocaleKeys.document_plugins_photoGallery_imageKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_imageGalleryKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_photoKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_photoBrowserKeyword.tr(),
    LocaleKeys.document_plugins_photoGallery_galleryKeyword.tr(),
  ],
  handler: (editorState, _, __) async {
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await editorState.insertEmptyMultiImageBlock(imagePlaceholderKey);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => imagePlaceholderKey.currentState?.controller.show(),
    );
  },
);

// file menu item
SelectionMenuItem fileSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_file.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_file_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['file upload', 'pdf', 'zip', 'archive', 'upload', 'attachment'],
  handler: (editorState, _, __) async {
    final fileGlobalKey = GlobalKey<FileBlockComponentState>();
    await editorState.insertEmptyFileBlock(fileGlobalKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fileGlobalKey.currentState?.controller.show();
    });
  },
);

// Sub-page menu item
SelectionMenuItem subPageSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_subPage_name.tr(),
  nameBuilder: _slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.insert_document_s,
    isSelected: isSelected,
    style: style,
  ),
  keywords: [
    LocaleKeys.document_slashMenu_subPage_keyword1.tr(),
    LocaleKeys.document_slashMenu_subPage_keyword2.tr(),
    LocaleKeys.document_slashMenu_subPage_keyword3.tr(),
    LocaleKeys.document_slashMenu_subPage_keyword4.tr(),
    LocaleKeys.document_slashMenu_subPage_keyword5.tr(),
    LocaleKeys.document_slashMenu_subPage_keyword6.tr(),
    LocaleKeys.document_slashMenu_subPage_keyword7.tr(),
  ],
  updateSelection: (_, path, __, ___) =>
      Selection.collapsed(Position(path: path)),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nodeBuilder: (_, __) => subPageNode(),
);

Widget _slashMenuItemNameBuilder(
  String name,
  SelectionMenuStyle style,
  bool isSelected,
) {
  return FlowyText.regular(
    name,
    fontSize: 12.0,
    figmaLineHeight: 15.0,
    color: isSelected
        ? style.selectionMenuItemSelectedTextColor
        : style.selectionMenuItemTextColor,
  );
}
