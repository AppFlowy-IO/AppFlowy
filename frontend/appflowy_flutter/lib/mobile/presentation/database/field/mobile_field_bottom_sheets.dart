import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'mobile_create_field_screen.dart';
import 'mobile_edit_field_screen.dart';
import 'mobile_field_picker_list.dart';
import 'mobile_field_type_grid.dart';
import 'mobile_field_type_option_editor.dart';
import 'mobile_quick_field_editor.dart';

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
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        snap: true,
        initialChildSize: 0.97,
        minChildSize: 0.97,
        maxChildSize: 0.97,
        builder: (context, controller) => MobileFieldTypeGrid(
          scrollController: controller,
          mode: FieldOptionMode.add,
          onSelectFieldType: (type) async {
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
              await optionValues.create(viewId: viewId, position: position);
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
  String? selectedFieldId,
  FieldController fieldController,
  bool Function(FieldInfo fieldInfo) filterBy,
) {
  return showMobileBottomSheet<String>(
    context,
    builder: (context) {
      return MobileFieldPickerList(
        selectedFieldId: selectedFieldId,
        fieldController: fieldController,
        filterBy: filterBy,
      );
    },
  );
}
