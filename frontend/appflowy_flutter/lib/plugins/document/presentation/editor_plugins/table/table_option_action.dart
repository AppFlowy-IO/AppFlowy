import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';

class TableOptionActionWrapper extends ActionCell {
  TableOptionActionWrapper(this.inner);

  final TableOptionAction inner;

  @override
  Widget? leftIcon(Color iconColor) => inner.icon(iconColor);

  @override
  String get name => inner.description;
}

enum TableOptionAction {
  addAfter,
  addBefore,
  delete,
  duplicate,
  clear,

  /// callout background color
  bgColor;

  Widget icon(Color? color) {
    switch (this) {
      case TableOptionAction.addAfter:
        return FlowySvg(FlowySvgs.add_s, color: color);
      case TableOptionAction.addBefore:
        return FlowySvg(FlowySvgs.add_s, color: color);
      case TableOptionAction.delete:
        return FlowySvg(FlowySvgs.delete_s, color: color);
      case TableOptionAction.duplicate:
        return FlowySvg(FlowySvgs.copy_s, color: color);
      case TableOptionAction.clear:
        return Icon(Icons.clear, color: color, size: 16.0);
      case TableOptionAction.bgColor:
        return FlowySvg(const FlowySvgData('editor/color'), color: color);
    }
  }

  String get description {
    switch (this) {
      case TableOptionAction.addAfter:
        return LocaleKeys.document_plugins_table_addAfter.tr();
      case TableOptionAction.addBefore:
        return LocaleKeys.document_plugins_table_addBefore.tr();
      case TableOptionAction.delete:
        return LocaleKeys.document_plugins_table_delete.tr();
      case TableOptionAction.duplicate:
        return LocaleKeys.document_plugins_table_duplicate.tr();
      case TableOptionAction.clear:
        return LocaleKeys.document_plugins_table_clear.tr();
      case TableOptionAction.bgColor:
        return LocaleKeys.document_plugins_table_bgColor.tr();
    }
  }
}
