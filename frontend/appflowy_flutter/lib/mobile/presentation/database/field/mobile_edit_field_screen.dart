import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_field_type_option_editor.dart';
import 'package:appflowy/plugins/database/application/field/field_backend_service.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/field_service.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:go_router/go_router.dart';

class MobileEditPropertyScreen extends StatefulWidget {
  static const routeName = '/edit_property';
  static const argViewId = 'view_id';
  static const argField = 'field';

  const MobileEditPropertyScreen({
    super.key,
    required this.viewId,
    required this.field,
  });

  final String viewId;
  final FieldInfo field;

  @override
  State<MobileEditPropertyScreen> createState() =>
      _MobileEditPropertyScreenState();
}

class _MobileEditPropertyScreenState extends State<MobileEditPropertyScreen> {
  late final FieldBackendService fieldService;
  late FieldOptionValues field;

  @override
  void initState() {
    super.initState();
    field = FieldOptionValues.fromField(field: widget.field.field);
    fieldService = FieldBackendService(
      viewId: widget.viewId,
      fieldId: widget.field.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewId = widget.viewId;
    final fieldId = widget.field.id;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FlowyText.medium(
          LocaleKeys.grid_field_editProperty.tr(),
        ),
        leading: AppBarBackButton(
          onTap: () => context.pop(field),
        ),
      ),
      body: FieldOptionEditor(
        mode: FieldOptionMode.edit,
        isPrimary: widget.field.isPrimary,
        defaultValues: field,
        actions: [
          if (widget.field.fieldSettings?.visibility.isVisibleState() ?? true)
            FieldOptionAction.hide
          else
            FieldOptionAction.show,
          FieldOptionAction.duplicate,
          FieldOptionAction.delete,
        ],
        onOptionValuesChanged: (newField) async {
          if (newField.name != field.name) {
            await fieldService.updateField(name: newField.name);
          }

          if (newField.type != widget.field.fieldType) {
            await fieldService.updateType(fieldType: newField.type);
          }

          final data = newField.getTypeOptionData();
          if (data != null) {
            await FieldBackendService.updateFieldTypeOption(
              viewId: viewId,
              fieldId: widget.field.id,
              typeOptionData: data,
            );
          }
          // setState(() => field = newField);
        },
        onAction: (action) {
          final service = FieldServices(
            viewId: viewId,
            fieldId: fieldId,
          );
          switch (action) {
            case FieldOptionAction.delete:
              service.delete();
              break;
            case FieldOptionAction.duplicate:
              service.duplicate();
              break;
            case FieldOptionAction.hide:
              service.hide();
              break;
            case FieldOptionAction.show:
              service.show();
              break;
          }
          context.pop(field);
        },
      ),
    );
  }
}
