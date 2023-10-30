import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_action_sheet_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../layout/sizes.dart';
import 'field_editor.dart';

class GridFieldCellActionSheet extends StatefulWidget {
  final String viewId;
  final FieldInfo fieldInfo;
  const GridFieldCellActionSheet({
    required this.viewId,
    required this.fieldInfo,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GridFieldCellActionSheetState();
}

class _GridFieldCellActionSheetState extends State<GridFieldCellActionSheet> {
  bool _showFieldEditor = false;

  @override
  Widget build(BuildContext context) {
    if (_showFieldEditor) {
      return SizedBox(
        width: 400,
        child: FieldEditor(
          viewId: widget.viewId,
          fieldInfo: widget.fieldInfo,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: widget.fieldInfo.field,
          ),
        ),
      );
    }
    return BlocProvider(
      create: (context) => FieldActionSheetBloc(
        viewId: widget.viewId,
        fieldInfo: widget.fieldInfo,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _EditFieldButton(
              onTap: () {
                setState(() => _showFieldEditor = true);
              },
            ),
            VSpace(GridSize.typeOptionSeparatorHeight),
            _FieldOperationList(
              viewId: widget.viewId,
              fieldInfo: widget.fieldInfo,
            ),
          ],
        ),
      ),
    ).padding(all: 6.0);
  }
}

class _EditFieldButton extends StatelessWidget {
  final void Function()? onTap;
  const _EditFieldButton({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldActionSheetBloc, FieldActionSheetState>(
      builder: (context, state) {
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: FlowyButton(
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            text: FlowyText.medium(
              LocaleKeys.grid_field_editProperty.tr(),
              color: AFThemeExtension.of(context).textColor,
            ),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

class _FieldOperationList extends StatelessWidget {
  final String viewId;
  final FieldInfo fieldInfo;
  const _FieldOperationList({
    required this.viewId,
    required this.fieldInfo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _actionCell(FieldAction action) {
    bool enable = true;

    // If the field is primary, delete and duplicate are disabled.
    if (fieldInfo.isPrimary) {
      switch (action) {
        case FieldAction.hide:
          break;
        case FieldAction.duplicate:
          enable = false;
          break;
        case FieldAction.delete:
          enable = false;
          break;
      }
    }

    return Flexible(
      child: SizedBox(
        height: GridSize.popoverItemHeight,
        child: FieldActionCell(
          viewId: viewId,
          fieldInfo: fieldInfo,
          action: action,
          enable: enable,
        ),
      ),
    );
  }
}

class FieldActionCell extends StatelessWidget {
  final String viewId;
  final FieldInfo fieldInfo;
  final FieldAction action;
  final bool enable;

  const FieldActionCell({
    required this.viewId,
    required this.fieldInfo,
    required this.action,
    required this.enable,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
      disable: !enable,
      text: FlowyText.medium(
        action.title(),
        color: enable
            ? AFThemeExtension.of(context).textColor
            : Theme.of(context).disabledColor,
      ),
      onTap: () => action.run(context, viewId, fieldInfo),
      leftIcon: FlowySvg(
        action.icon(),
        color: enable
            ? AFThemeExtension.of(context).textColor
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
  FlowySvgData icon() {
    switch (this) {
      case FieldAction.hide:
        return FlowySvgs.hide_s;
      case FieldAction.duplicate:
        return FlowySvgs.copy_s;
      case FieldAction.delete:
        return FlowySvgs.delete_s;
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

  void run(BuildContext context, String viewId, FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.hide:
        context
            .read<FieldActionSheetBloc>()
            .add(const FieldActionSheetEvent.hideField());
        break;
      case FieldAction.duplicate:
        PopoverContainer.of(context).close();

        FieldBackendService(
          viewId: viewId,
          fieldId: fieldInfo.id,
        ).duplicateField();

        break;
      case FieldAction.delete:
        PopoverContainer.of(context).close();

        NavigatorAlertDialog(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          confirm: () {
            FieldBackendService(
              viewId: viewId,
              fieldId: fieldInfo.field.id,
            ).deleteField();
          },
        ).show(context);

        break;
    }
  }
}
