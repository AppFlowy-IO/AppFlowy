import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_field_options_eidtor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field_settings/field_settings_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileEditPropertyScreen extends StatefulWidget {
  static const routeName = '/edit_property';
  static const argViewId = 'view_id';
  static const argField = 'field';
  static const argIsPrimary = 'is_primary';

  const MobileEditPropertyScreen({
    super.key,
    required this.viewId,
    required this.field,
    this.isPrimary = false,
  });

  final String viewId;
  final FieldPB field;
  final bool isPrimary;

  @override
  State<MobileEditPropertyScreen> createState() =>
      _MobileEditPropertyScreenState();
}

class _MobileEditPropertyScreenState extends State<MobileEditPropertyScreen> {
  late Future<FieldOptionValues?> future;

  FieldOptionValues? optionValues;

  @override
  void initState() {
    super.initState();

    future = FieldOptionValues.get(
      viewId: widget.viewId,
      fieldId: widget.field.id,
      fieldType: widget.field.fieldType,
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
        leading: AppBarCancelButton(
          onTap: () => context.pop(),
        ),
        leadingWidth: 120,
        actions: [
          _SaveButton(
            onSave: () {
              context.pop(optionValues);
            },
          ),
        ],
      ),
      body: FutureBuilder<FieldOptionValues?>(
        future: future,
        builder: (context, snapshot) {
          final optionValues = snapshot.data;
          if (optionValues == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return FieldOptionEditor(
            mode: FieldOptionMode.edit,
            isPrimary: widget.isPrimary,
            defaultValues: optionValues,
            onOptionValuesChanged: (optionValues) {
              this.optionValues = optionValues;
            },
            onAction: (action) {
              final service = FieldBackendService(
                viewId: viewId,
                fieldId: fieldId,
              );
              switch (action) {
                case FieldOptionAction.delete:
                  service.deleteField();
                  break;
                case FieldOptionAction.duplicate:
                  service.duplicateField();
                  break;
                case FieldOptionAction.hide:
                  FieldSettingsBackendService(viewId: viewId)
                      .updateFieldSettings(
                    fieldId: fieldId,
                    fieldVisibility: FieldVisibility.AlwaysHidden,
                  );
                  break;
              }
              context.pop();
            },
          );
        },
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.onSave,
  });

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Align(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: onSave,
          child: FlowyText.medium(
            LocaleKeys.button_save.tr(),
            color: const Color(0xFF00ADDC),
          ),
        ),
      ),
    );
  }
}
