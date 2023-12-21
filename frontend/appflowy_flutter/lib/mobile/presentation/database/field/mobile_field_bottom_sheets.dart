import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'mobile_create_field_screen.dart';
import 'mobile_edit_field_screen.dart';
import 'mobile_field_picker_list.dart';
import 'mobile_field_type_grid.dart';
import 'mobile_field_type_option_editor.dart';
import 'mobile_quick_field_editor.dart';

void showCreateFieldBottomSheet(BuildContext context, String viewId) {
  showMobileBottomSheet(
    context,
    padding: EdgeInsets.zero,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        snap: true,
        initialChildSize: 0.7,
        minChildSize: 0.7,
        builder: (context, controller) => FieldOptions(
          scrollController: controller,
          onAddField: (type) async {
            final optionValues = await context.push<FieldOptionValues>(
              Uri(
                path: MobileNewPropertyScreen.routeName,
                queryParameters: {
                  MobileNewPropertyScreen.argViewId: viewId,
                  MobileNewPropertyScreen.argFieldTypeId: type.value.toString(),
                },
              ).toString(),
            );
            if (optionValues != null) {
              await optionValues.create(viewId: viewId);
              if (context.mounted) {
                context.pop();
              }
            }
          },
        ),
      );
    },
  );
}

Future<FieldOptionValues?> showEditFieldScreen(
  BuildContext context,
  String viewId,
  FieldInfo field,
) async {
  final optionValues = await context.push<FieldOptionValues>(
    MobileEditPropertyScreen.routeName,
    extra: {
      MobileEditPropertyScreen.argViewId: viewId,
      MobileEditPropertyScreen.argField: field.field,
    },
  );
  if (optionValues != null) {
    final service = FieldBackendService(
      viewId: viewId,
      fieldId: field.id,
    );

    if (optionValues.name != field.name) {
      await service.updateField(name: optionValues.name);
    }

    if (optionValues.type != field.fieldType) {
      await service.updateFieldType(fieldType: optionValues.type);
    }

    final data = optionValues.toTypeOptionBuffer();
    if (data != null) {
      await FieldBackendService.updateFieldTypeOption(
        viewId: viewId,
        fieldId: field.id,
        typeOptionData: data,
      );
    }
  }

  return optionValues;
}

void showQuickEditField(
  BuildContext context,
  String viewId,
  FieldInfo fieldInfo,
) async {
  showMobileBottomSheet(
    context,
    padding: EdgeInsets.zero,
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    resizeToAvoidBottomInset: true,
    builder: (context) {
      return SingleChildScrollView(
        child: QuickEditField(
          viewId: viewId,
          fieldInfo: fieldInfo,
        ),
      );
    },
  );
}

Future<String?> showFieldPicker(
  BuildContext context,
  String? selectedFieldId,
  FieldController fieldController,
  bool Function(FieldInfo fieldInfo) filterBy,
) {
  return showMobileBottomSheet<String>(
    context,
    padding: EdgeInsets.zero,
    builder: (context) {
      return MobileFieldPickerList(
        selectedFieldId: selectedFieldId,
        fieldController: fieldController,
        filterBy: filterBy,
      );
    },
  );
}
