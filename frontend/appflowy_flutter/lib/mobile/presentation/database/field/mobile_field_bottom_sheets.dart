import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/type_option_menu_item.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'mobile_create_field_screen.dart';
import 'mobile_edit_field_screen.dart';
import 'mobile_field_picker_list.dart';
import 'mobile_full_field_editor.dart';
import 'mobile_quick_field_editor.dart';

const mobileSupportedFieldTypes = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.URL,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.DateTime,
  FieldType.LastEditedTime,
  FieldType.CreatedTime,
  FieldType.Checkbox,
  FieldType.Checklist,
];

/// Shows the field type grid and upon selection, allow users to edit the
/// field's properties and saving it when the user clicks save.
void showCreateFieldBottomSheet(
  BuildContext context,
  String viewId, {
  OrderObjectPositionPB? position,
}) {
  showMobileBottomSheet(
    context,
    padding: EdgeInsets.zero,
    showHeader: true,
    showDragHandle: true,
    showCloseButton: true,
    elevation: 20,
    title: LocaleKeys.grid_field_newProperty.tr(),
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Colors.transparent,
    enableDraggableScrollable: true,
    builder: (context) {
      final typeOptionMenuItemValue = mobileSupportedFieldTypes
          .map(
            (fieldType) => TypeOptionMenuItemValue(
              value: fieldType,
              backgroundColor: fieldType.mobileIconBackgroundColor,
              text: fieldType.i18n,
              icon: fieldType.svgData,
              onTap: (_, fieldType) async {
                final optionValues = await context.push<FieldOptionValues>(
                  Uri(
                    path: MobileNewPropertyScreen.routeName,
                    queryParameters: {
                      MobileNewPropertyScreen.argViewId: viewId,
                      MobileNewPropertyScreen.argFieldTypeId:
                          fieldType.value.toString(),
                    },
                  ).toString(),
                );
                if (optionValues != null) {
                  await optionValues.create(viewId: viewId, position: position);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
            ),
          )
          .toList();
      return Padding(
        padding: EdgeInsets.all(16 * context.scale),
        child: TypeOptionMenu<FieldType>(
          values: typeOptionMenuItemValue,
          scaleFactor: context.scale,
        ),
      );
    },
  );
}

/// Used to edit a field.
Future<FieldOptionValues?> showEditFieldScreen(
  BuildContext context,
  String viewId,
  FieldInfo field,
) {
  return context.push<FieldOptionValues>(
    MobileEditPropertyScreen.routeName,
    extra: {
      MobileEditPropertyScreen.argViewId: viewId,
      MobileEditPropertyScreen.argField: field,
    },
  );
}

/// Shows some quick field options in a bottom sheet.
void showQuickEditField(
  BuildContext context,
  String viewId,
  FieldInfo fieldInfo,
) {
  showMobileBottomSheet(
    context,
    padding: EdgeInsets.zero,
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    resizeToAvoidBottomInset: true,
    showDragHandle: true,
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

/// Display a list of fields in the current database that users can choose from.
Future<String?> showFieldPicker(
  BuildContext context,
  String title,
  String? selectedFieldId,
  FieldController fieldController,
  bool Function(FieldInfo fieldInfo) filterBy,
) {
  return showMobileBottomSheet<String>(
    context,
    showDivider: false,
    builder: (context) {
      return MobileFieldPickerList(
        title: title,
        selectedFieldId: selectedFieldId,
        fieldController: fieldController,
        filterBy: filterBy,
      );
    },
  );
}
