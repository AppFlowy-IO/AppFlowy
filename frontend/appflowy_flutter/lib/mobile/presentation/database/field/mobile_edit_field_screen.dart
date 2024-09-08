import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_full_field_editor.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/field_backend_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

class MobileEditPropertyScreen extends StatefulWidget {
  const MobileEditPropertyScreen({
    super.key,
    required this.viewId,
    required this.field,
  });

  final String viewId;
  final FieldInfo field;

  static const routeName = '/edit_property';
  static const argViewId = 'view_id';
  static const argField = 'field';

  @override
  State<MobileEditPropertyScreen> createState() =>
      _MobileEditPropertyScreenState();
}

class _MobileEditPropertyScreenState extends State<MobileEditPropertyScreen> {
  late final FieldBackendService fieldService;
  late FieldOptionValues _fieldOptionValues;

  @override
  void initState() {
    super.initState();
    _fieldOptionValues = FieldOptionValues.fromField(field: widget.field.field);
    fieldService = FieldBackendService(
      viewId: widget.viewId,
      fieldId: widget.field.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewId = widget.viewId;
    final fieldId = widget.field.id;

    return PopScope(
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.pop(_fieldOptionValues);
        }
      },
      child: Scaffold(
        appBar: FlowyAppBar(
          titleText: LocaleKeys.grid_field_editProperty.tr(),
          onTapLeading: () => context.pop(_fieldOptionValues),
        ),
        body: MobileFieldEditor(
          mode: FieldOptionMode.edit,
          isPrimary: widget.field.isPrimary,
          defaultValues: FieldOptionValues.fromField(field: widget.field.field),
          actions: [
            widget.field.visibility?.isVisibleState() ?? true
                ? FieldOptionAction.hide
                : FieldOptionAction.show,
            FieldOptionAction.duplicate,
            FieldOptionAction.delete,
          ],
          onOptionValuesChanged: (fieldOptionValues) async {
            await fieldService.updateField(name: fieldOptionValues.name);

            await FieldBackendService.updateFieldType(
              viewId: widget.viewId,
              fieldId: widget.field.id,
              fieldType: fieldOptionValues.type,
            );

            final data = fieldOptionValues.getTypeOptionData();
            if (data != null) {
              await FieldBackendService.updateFieldTypeOption(
                viewId: widget.viewId,
                fieldId: widget.field.id,
                typeOptionData: data,
              );
            }
            setState(() {
              _fieldOptionValues = fieldOptionValues;
            });
          },
          onAction: (action) {
            final service = FieldServices(
              viewId: viewId,
              fieldId: fieldId,
            );
            switch (action) {
              case FieldOptionAction.delete:
                fieldService.delete();
                context.pop();
                return;
              case FieldOptionAction.duplicate:
                fieldService.duplicate();
                break;
              case FieldOptionAction.hide:
                service.hide();
                break;
              case FieldOptionAction.show:
                service.show();
                break;
            }
            context.pop(_fieldOptionValues);
          },
        ),
      ),
    );
  }
}
