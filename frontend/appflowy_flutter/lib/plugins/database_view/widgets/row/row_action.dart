import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_editor.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowActionList extends StatelessWidget {
  final RowController rowController;
  const RowActionList({
    required String viewId,
    required this.rowController,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: FlowyText(LocaleKeys.grid_row_action.tr()),
        ),
        const VSpace(15),
        RowDetailPageDeleteButton(rowId: rowController.rowId),
        RowDetailPageDuplicateButton(
          rowId: rowController.rowId,
          groupId: rowController.groupId,
        ),
      ],
    );
  }
}

class RowDetailPageDeleteButton extends StatelessWidget {
  final String rowId;
  const RowDetailPageDeleteButton({required this.rowId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_delete.tr()),
        leftIcon: const FlowySvg(name: "home/trash"),
        onTap: () {
          context.read<RowDetailBloc>().add(RowDetailEvent.deleteRow(rowId));
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

class RowDetailPageDuplicateButton extends StatelessWidget {
  final String rowId;
  final String? groupId;
  const RowDetailPageDuplicateButton({
    required this.rowId,
    this.groupId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.regular(LocaleKeys.grid_row_duplicate.tr()),
        leftIcon: const FlowySvg(name: "grid/duplicate"),
        onTap: () {
          context
              .read<RowDetailBloc>()
              .add(RowDetailEvent.duplicateRow(rowId, groupId));
          FlowyOverlay.pop(context);
        },
      ),
    );
  }
}

class CreateRowFieldButton extends StatefulWidget {
  final String viewId;

  const CreateRowFieldButton({
    required this.viewId,
    Key? key,
  }) : super(key: key);

  @override
  State<CreateRowFieldButton> createState() => _CreateRowFieldButtonState();
}

class _CreateRowFieldButtonState extends State<CreateRowFieldButton> {
  late PopoverController popoverController;
  late TypeOptionPB typeOption;

  @override
  void initState() {
    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(240, 200)),
      controller: popoverController,
      direction: PopoverDirection.topWithLeftAligned,
      triggerActions: PopoverTriggerFlags.none,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: 40,
        child: FlowyButton(
          text: FlowyText.medium(
            LocaleKeys.grid_field_newProperty.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onTap: () async {
            final result = await TypeOptionBackendService.createFieldTypeOption(
              viewId: widget.viewId,
            );
            result.fold(
              (l) {
                typeOption = l;
                popoverController.show();
              },
              (r) => Log.error("Failed to create field type option: $r"),
            );
          },
          leftIcon: svgWidget(
            "home/add",
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      ),
      popupBuilder: (BuildContext popOverContext) {
        return FieldEditor(
          viewId: widget.viewId,
          typeOptionLoader: FieldTypeOptionLoader(
            viewId: widget.viewId,
            field: typeOption.field_2,
          ),
          onDeleted: (fieldId) {
            popoverController.close();
            NavigatorAlertDialog(
              title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
              confirm: () {
                context
                    .read<RowDetailBloc>()
                    .add(RowDetailEvent.deleteField(fieldId));
              },
            ).show(context);
          },
        );
      },
    );
  }
}
