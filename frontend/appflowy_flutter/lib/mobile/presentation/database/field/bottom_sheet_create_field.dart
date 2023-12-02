import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_create_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_edit_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_field_options.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_field_options_eidtor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

void showEditFieldScreen(
  BuildContext context,
  String viewId,
  FieldInfo field,
) async {
  final optionValues = await context.push<FieldOptionValues>(
    MobileEditPropertyScreen.routeName,
    extra: {
      MobileEditPropertyScreen.argViewId: viewId,
      MobileEditPropertyScreen.argField: field.field,
      MobileEditPropertyScreen.argIsPrimary: field.isPrimary,
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
}
