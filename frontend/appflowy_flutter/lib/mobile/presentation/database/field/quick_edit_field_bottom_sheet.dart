import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/database/field/bottom_sheet_create_field.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/field_backend_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  late FieldType fieldType;

  @override
  void initState() {
    super.initState();

    fieldType = widget.fieldInfo.fieldType;
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
        const AppBarCloseButton(),
        OptionTextField(
          controller: controller,
          type: fieldType,
          onTextChanged: (text) async {
            await service.updateName(text);
          },
        ),
        const _Divider(),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_editProperty.tr(),
          leftIcon: const FlowySvg(FlowySvgs.edit_s),
          onTap: () async {
            final optionValues = await showEditFieldScreen(
              context,
              widget.viewId,
              widget.fieldInfo,
            );
            if (optionValues != null) {
              setState(() {
                fieldType = optionValues.type;
                controller.text = optionValues.name;
              });
            }
          },
        ),
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.grid_field_hide.tr(),
          leftIcon: const FlowySvg(FlowySvgs.hide_s),
          onTap: () async {
            context.pop();
            await service.hide();
          },
        ),
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.grid_field_insertLeft.tr(),
          leftIcon: const FlowySvg(FlowySvgs.insert_left_s),
          onTap: () async {
            context.pop();
            await service.insertLeft();
          },
        ),
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.grid_field_insertRight.tr(),
          leftIcon: const FlowySvg(FlowySvgs.insert_right_s),
          onTap: () async {
            context.pop();
            await service.insertRight();
          },
        ),
        if (!widget.fieldInfo.isPrimary) ...[
          FlowyOptionTile.text(
            showTopBorder: false,
            text: LocaleKeys.button_duplicate.tr(),
            leftIcon: const FlowySvg(FlowySvgs.copy_s),
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
              FlowySvgs.delete_s,
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
