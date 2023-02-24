import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/header/field_editor.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../layout/sizes.dart';

class GridFieldCellActionSheet extends StatefulWidget {
  final GridFieldCellContext cellContext;
  const GridFieldCellActionSheet({required this.cellContext, Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridFieldCellActionSheetState();
}

class _GridFieldCellActionSheetState extends State<GridFieldCellActionSheet> {
  bool _showFieldEditor = false;

  @override
  Widget build(BuildContext context) {
    if (_showFieldEditor) {
      final field = widget.cellContext.field;
      return SizedBox(
        width: 400,
        child: FieldEditor(
          databaseId: widget.cellContext.viewId,
          fieldName: field.name,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.cellContext.viewId,
            field: field,
          ),
        ),
      );
    }
    return BlocProvider(
      create: (context) =>
          getIt<FieldActionSheetBloc>(param1: widget.cellContext),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _EditFieldButton(
              cellContext: widget.cellContext,
              onTap: () {
                setState(() => _showFieldEditor = true);
              },
            ),
            VSpace(GridSize.typeOptionSeparatorHeight),
            _FieldOperationList(widget.cellContext),
          ],
        ),
      ),
    ).padding(all: 6.0);
  }
}

class _EditFieldButton extends StatelessWidget {
  final GridFieldCellContext cellContext;
  final void Function()? onTap;
  const _EditFieldButton({required this.cellContext, Key? key, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldActionSheetBloc, FieldActionSheetState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: FlowyButton(
            text: FlowyText.medium(
              LocaleKeys.grid_field_editProperty.tr(),
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

class _FieldOperationList extends StatelessWidget {
  final GridFieldCellContext fieldInfo;
  const _FieldOperationList(this.fieldInfo, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Flex(
        direction: Axis.horizontal,
        children: [
          _actionCell(FieldAction.hide),
          HSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.duplicate),
        ],
      ),
      VSpace(GridSize.typeOptionSeparatorHeight),
      Flex(
        direction: Axis.horizontal,
        children: [
          _actionCell(FieldAction.delete),
          HSpace(GridSize.typeOptionSeparatorHeight),
          const Spacer(),
        ],
      ),
    ]);
  }

  Widget _actionCell(FieldAction action) {
    return Flexible(
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FieldActionCell(
          fieldInfo: fieldInfo,
          action: action,
          enable: action != FieldAction.delete || !fieldInfo.field.isPrimary,
        ),
      ),
    );
  }
}

class FieldActionCell extends StatelessWidget {
  final GridFieldCellContext fieldInfo;
  final FieldAction action;
  final bool enable;

  const FieldActionCell({
    required this.fieldInfo,
    required this.action,
    required this.enable,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: FlowyText.medium(
        action.title(),
        color: enable ? null : Theme.of(context).disabledColor,
      ),
      onTap: () {
        if (enable) {
          action.run(context, fieldInfo);
        }
      },
      leftIcon: svgWidget(
        action.iconName(),
        color: enable
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).disabledColor,
      ),
    );
  }
}

enum FieldAction {
  hide,
  duplicate,
  delete,
}

extension _FieldActionExtension on FieldAction {
  String iconName() {
    switch (this) {
      case FieldAction.hide:
        return 'grid/hide';
      case FieldAction.duplicate:
        return 'grid/duplicate';
      case FieldAction.delete:
        return 'grid/delete';
    }
  }

  String title() {
    switch (this) {
      case FieldAction.hide:
        return LocaleKeys.grid_field_hide.tr();
      case FieldAction.duplicate:
        return LocaleKeys.grid_field_duplicate.tr();
      case FieldAction.delete:
        return LocaleKeys.grid_field_delete.tr();
    }
  }

  void run(BuildContext context, GridFieldCellContext fieldInfo) {
    switch (this) {
      case FieldAction.hide:
        context
            .read<FieldActionSheetBloc>()
            .add(const FieldActionSheetEvent.hideField());
        break;
      case FieldAction.duplicate:
        PopoverContainer.of(context).close();

        FieldService(
          viewId: fieldInfo.viewId,
          fieldId: fieldInfo.field.id,
        ).duplicateField();

        break;
      case FieldAction.delete:
        PopoverContainer.of(context).close();

        NavigatorAlertDialog(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          confirm: () {
            FieldService(
              viewId: fieldInfo.viewId,
              fieldId: fieldInfo.field.id,
            ).deleteField();
          },
        ).show(context);

        break;
    }
  }
}
