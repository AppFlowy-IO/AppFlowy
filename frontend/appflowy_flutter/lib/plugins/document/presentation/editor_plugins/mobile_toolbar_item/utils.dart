import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_edit_link_widget.dart';
import 'package:flutter/material.dart';

void showEditLinkBottomSheet(
  BuildContext context,
  String text,
  String? href,
  void Function(BuildContext context, String text, String href) onEdit,
) {
  showMobileBottomSheet(
    context,
    showHeader: false,
    builder: (context) {
      return MobileBottomSheetEditLinkWidget(
        text: text,
        href: href,
        onEdit: (text, href) => onEdit(context, text, href),
      );
    },
  );
}
