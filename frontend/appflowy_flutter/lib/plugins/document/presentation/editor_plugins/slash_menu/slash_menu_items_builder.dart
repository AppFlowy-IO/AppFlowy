import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import 'slash_menu_items/slash_menu_items.dart';

/// Build slash menu items
///
/// If in local mode, disable the ai writer feature
///
/// The linked database relies on the documentBloc, so it's required to pass in
/// the documentBloc when building the slash menu items. If the documentBloc is
/// not provided, the linked database items will be disabled.
List<SelectionMenuItem> slashMenuItemsBuilder({
  bool isLocalMode = false,
  DocumentBloc? documentBloc,
}) {
  return [
    // disable ai writer in local mode
    if (!isLocalMode) aiWriterSlashMenuItem,

    paragraphSlashMenuItem,

    // heading 1-3
    heading1SlashMenuItem,
    heading2SlashMenuItem,
    heading3SlashMenuItem,

    // image
    imageSlashMenuItem,

    // list
    bulletedListSlashMenuItem,
    numberedListSlashMenuItem,
    todoListSlashMenuItem,

    // divider
    dividerSlashMenuItem,

    // quote
    quoteSlashMenuItem,

    // simple table
    tableSlashMenuItem,

    // link to page
    linkToPageSlashMenuItem,

    // grid
    if (documentBloc != null) gridSlashMenuItem(documentBloc),
    referencedGridSlashMenuItem,

    // kanban
    if (documentBloc != null) kanbanSlashMenuItem(documentBloc),
    referencedKanbanSlashMenuItem,

    // calendar
    if (documentBloc != null) calendarSlashMenuItem(documentBloc),
    referencedCalendarSlashMenuItem,

    // callout
    calloutSlashMenuItem,

    // outline
    outlineSlashMenuItem,

    // math equation
    mathEquationSlashMenuItem,

    // code block
    codeBlockSlashMenuItem,

    // toggle list - toggle headings
    toggleListSlashMenuItem,
    toggleHeading1SlashMenuItem,
    toggleHeading2SlashMenuItem,
    toggleHeading3SlashMenuItem,

    // emoji
    emojiSlashMenuItem,

    // date or reminder
    dateOrReminderSlashMenuItem,

    // photo gallery
    photoGallerySlashMenuItem,

    // file
    fileSlashMenuItem,

    // sub page
    subPageSlashMenuItem,
  ];
}
