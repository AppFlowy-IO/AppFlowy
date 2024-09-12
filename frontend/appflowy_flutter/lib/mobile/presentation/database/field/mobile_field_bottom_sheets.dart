import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/type_option_menu_item.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
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
  FieldType.Time,
  FieldType.Media,
];

Future<FieldType?> showFieldTypeGridBottomSheet(
  BuildContext context, {
  required String title,
}) {
  return showMobileBottomSheet<FieldType>(
    context,
    showHeader: true,
    showDragHandle: true,
    showCloseButton: true,
    elevation: 20,
    title: title,
    backgroundColor: AFThemeExtension.of(context).background,
    enableDraggableScrollable: true,
    builder: (context) {
      final typeOptionMenuItemValue = mobileSupportedFieldTypes
          .map(
            (fieldType) => TypeOptionMenuItemValue(
              value: fieldType,
              backgroundColor: Theme.of(context).brightness == Brightness.light
                  ? fieldType.mobileIconBackgroundColor
                  : fieldType.mobileIconBackgroundColorDark,
              text: fieldType.i18n,
              icon: fieldType.svgData,
              onTap: (context, fieldType) =>
                  Navigator.of(context).pop(fieldType),
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

/// Shows the field type grid and upon selection, allow users to edit the
/// field's properties and saving it when the user clicks save.
void mobileCreateFieldWorkflow(
  BuildContext context,
  String viewId, {
  OrderObjectPositionPB? position,
}) async {
  final fieldType = await showFieldTypeGridBottomSheet(
    context,
    title: LocaleKeys.grid_field_newProperty.tr(),
  );
  if (fieldType == null || !context.mounted) {
    return;
  }
  final optionValues = await context.push<FieldOptionValues>(
    Uri(
      path: MobileNewPropertyScreen.routeName,
      queryParameters: {
        MobileNewPropertyScreen.argViewId: viewId,
        MobileNewPropertyScreen.argFieldTypeId: fieldType.value.toString(),
      },
    ).toString(),
  );
  if (optionValues != null) {
    await optionValues.create(viewId: viewId, position: position);
  }
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
  FieldController fieldController,
  FieldInfo fieldInfo,
) {
  showMobileBottomSheet(
    context,
    showDragHandle: true,
    builder: (context) {
      return SingleChildScrollView(
        child: QuickEditField(
          viewId: viewId,
          fieldController: fieldController,
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
