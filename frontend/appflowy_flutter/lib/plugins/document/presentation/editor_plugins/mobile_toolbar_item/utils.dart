import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_edit_link_widget.dart';
import 'package:flutter/material.dart';

Future<T?> showEditLinkBottomSheet<T>(
  BuildContext context,
  String text,
  String? href,
  void Function(BuildContext context, String text, String href) onEdit,
) {
  return showMobileBottomSheet(
    context,
    showDragHandle: true,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    builder: (context) {
      return MobileBottomSheetEditLinkWidget(
        text: text,
        href: href,
        onEdit: (text, href) => onEdit(context, text, href),
      );
    },
  );
}
