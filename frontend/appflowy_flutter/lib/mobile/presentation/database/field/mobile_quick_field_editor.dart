import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_field_bottom_sheets.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_full_field_editor.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database/application/field/field_backend_service.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/field_service.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

class QuickEditField extends StatefulWidget {
  const QuickEditField({
    super.key,
    required this.viewId,
    required this.fieldInfo,
  });

  final String viewId;
  final FieldInfo fieldInfo;

  @override
  State<QuickEditField> createState() => _QuickEditFieldState();
}

class _QuickEditFieldState extends State<QuickEditField> {
  final TextEditingController controller = TextEditingController();

  late final FieldServices service = FieldServices(
    viewId: widget.viewId,
    fieldId: widget.fieldInfo.field.id,
  );

  late FieldVisibility fieldVisibility;
  late FieldOptionValues _fieldOptionValues;

  @override
  void initState() {
    super.initState();

    _fieldOptionValues =
        FieldOptionValues.fromField(field: widget.fieldInfo.field);
    fieldVisibility = widget.fieldInfo.fieldSettings?.visibility ??
        FieldVisibility.AlwaysShown;
    controller.text = widget.fieldInfo.field.name;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(16),
        OptionTextField(
          controller: controller,
          type: _fieldOptionValues.type,
          onTextChanged: (text) async {
            await service.updateName(text);
          },
        ),
        const _Divider(),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_editProperty.tr(),
          leftIcon: const FlowySvg(FlowySvgs.m_field_edit_s),
          onTap: () async {
            widget.fieldInfo.field.freeze();
            final field = widget.fieldInfo.field.rebuild((field) {
              field.name = controller.text;
              field.fieldType = _fieldOptionValues.type;
              field.typeOptionData =
                  _fieldOptionValues.getTypeOptionData() ?? [];
            });
            final fieldOptionValues = await showEditFieldScreen(
              context,
              widget.viewId,
              widget.fieldInfo.copyWith(field: field),
            );
            if (fieldOptionValues != null) {
              if (fieldOptionValues.name != _fieldOptionValues.name) {
                await service.updateName(fieldOptionValues.name);
              }

              if (fieldOptionValues.type != _fieldOptionValues.type) {
                await FieldBackendService.updateFieldType(
                  viewId: widget.viewId,
                  fieldId: widget.fieldInfo.id,
                  fieldType: fieldOptionValues.type,
                );
              }

              final data = fieldOptionValues.getTypeOptionData();
              if (data != null) {
                await FieldBackendService.updateFieldTypeOption(
                  viewId: widget.viewId,
                  fieldId: widget.fieldInfo.id,
                  typeOptionData: data,
                );
              }
              setState(() {
                _fieldOptionValues = fieldOptionValues;
                controller.text = fieldOptionValues.name;
              });
            } else {
              if (context.mounted) {
                context.pop();
              }
            }
          },
        ),
        if (!widget.fieldInfo.isPrimary)
          FlowyOptionTile.text(
            showTopBorder: false,
            text: fieldVisibility.isVisibleState()
                ? LocaleKeys.grid_field_hide.tr()
                : LocaleKeys.grid_field_show.tr(),
            leftIcon: const FlowySvg(FlowySvgs.m_field_hide_s),
            onTap: () async {
              context.pop();
              if (fieldVisibility.isVisibleState()) {
                await service.hide();
              } else {
                await service.hide();
              }
            },
          ),
        if (!widget.fieldInfo.isPrimary)
          FlowyOptionTile.text(
            showTopBorder: false,
            text: LocaleKeys.grid_field_insertLeft.tr(),
            leftIcon: const FlowySvg(FlowySvgs.m_filed_insert_left_s),
            onTap: () async {
              context.pop();
              showCreateFieldBottomSheet(
                context,
                widget.viewId,
                position: OrderObjectPositionPB(
                  position: OrderObjectPositionTypePB.Before,
                  objectId: widget.fieldInfo.id,
                ),
              );
            },
          ),
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.grid_field_insertRight.tr(),
          leftIcon: const FlowySvg(FlowySvgs.m_filed_insert_right_s),
          onTap: () async {
            context.pop();
            showCreateFieldBottomSheet(
              context,
              widget.viewId,
              position: OrderObjectPositionPB(
                position: OrderObjectPositionTypePB.After,
                objectId: widget.fieldInfo.id,
              ),
            );
          },
        ),
        if (!widget.fieldInfo.isPrimary) ...[
          FlowyOptionTile.text(
            showTopBorder: false,
            text: LocaleKeys.button_duplicate.tr(),
            leftIcon: const FlowySvg(FlowySvgs.m_field_copy_s),
            onTap: () async {
              context.pop();
              await service.duplicate();
            },
          ),
          FlowyOptionTile.text(
            showTopBorder: false,
            text: LocaleKeys.button_delete.tr(),
            textColor: Theme.of(context).colorScheme.error,
            leftIcon: FlowySvg(
              FlowySvgs.m_field_delete_s,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () async {
              context.pop();
              await service.delete();
            },
          ),
        ],
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const VSpace(20);
  }
}
