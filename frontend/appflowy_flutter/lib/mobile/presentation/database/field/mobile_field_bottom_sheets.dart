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
        initialChildSize: 0.7,
        minChildSize: 0.7,
        builder: (context, controller) => FieldOptions(
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

Future<FieldOptionValues?> showEditFieldScreen(
  BuildContext context,
  String viewId,
  FieldInfo field,
) async {
  final optionValues = await context.push<FieldOptionValues>(
    MobileEditPropertyScreen.routeName,
    extra: {
      MobileEditPropertyScreen.argViewId: viewId,
      MobileEditPropertyScreen.argField: field,
    },
  );

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
