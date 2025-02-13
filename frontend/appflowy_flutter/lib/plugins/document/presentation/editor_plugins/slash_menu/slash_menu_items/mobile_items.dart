import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/selection_menu/mobile_selection_menu_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

import 'slash_menu_items.dart';

final List<SelectionMenuItem> mobileItems = [
  textStyleMobileSlashMenuItem,
  listMobileSlashMenuItem,
  toggleListMobileSlashMenuItem,
  fileOrMediaMobileSlashMenuItem,
  decorationsMobileSlashMenuItem,
  tableSlashMenuItem,
  dateOrReminderSlashMenuItem,
  advancedMobileSlashMenuItem,
];

final List<SelectionMenuItem> mobileItemsInTale = [
  textStyleMobileSlashMenuItem,
  listMobileSlashMenuItem,
  toggleListMobileSlashMenuItem,
  fileOrMediaMobileSlashMenuItem,
  decorationsMobileSlashMenuItem,
  dateOrReminderSlashMenuItem,
  advancedMobileSlashMenuItem,
];

SelectionMenuItemHandler _handler = (_, __, ___) {};

MobileSelectionMenuItem textStyleMobileSlashMenuItem = MobileSelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_textStyle.tr,
  handler: _handler,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_text_s,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  children: [
    paragraphSlashMenuItem,
    heading1SlashMenuItem,
    heading2SlashMenuItem,
    heading3SlashMenuItem,
  ],
);

MobileSelectionMenuItem listMobileSlashMenuItem = MobileSelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_list.tr,
  handler: _handler,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_bulleted_list_s,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  children: [
    todoListSlashMenuItem,
    bulletedListSlashMenuItem,
    numberedListSlashMenuItem,
  ],
);

MobileSelectionMenuItem toggleListMobileSlashMenuItem = MobileSelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_toggleList.tr,
  handler: _handler,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_toggle_s,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  children: [
    toggleListSlashMenuItem,
    toggleHeading1SlashMenuItem,
    toggleHeading2SlashMenuItem,
    toggleHeading3SlashMenuItem,
  ],
);

MobileSelectionMenuItem fileOrMediaMobileSlashMenuItem =
    MobileSelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_fileOrMedia.tr,
  handler: _handler,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_file_s,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  children: [
    imageSlashMenuItem,
    photoGallerySlashMenuItem,
    fileSlashMenuItem,
  ],
);

MobileSelectionMenuItem decorationsMobileSlashMenuItem =
    MobileSelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_decorations.tr,
  handler: _handler,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_simple_table_s,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  children: [
    quoteSlashMenuItem,
    dividerSlashMenuItem,
  ],
);

MobileSelectionMenuItem advancedMobileSlashMenuItem = MobileSelectionMenuItem(
  getName: LocaleKeys.document_slashMenu_name_advanced.tr,
  handler: _handler,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.m_aa_font_color_m,
    isSelected: isSelected,
    style: style,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  children: [
    subPageSlashMenuItem,
    calloutSlashMenuItem,
    codeBlockSlashMenuItem,
    mathEquationSlashMenuItem,
  ],
);
