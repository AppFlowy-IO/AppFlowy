import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_full_field_editor.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileNewPropertyScreen extends StatefulWidget {
  const MobileNewPropertyScreen({
    super.key,
    required this.viewId,
    this.fieldType,
  });

  final String viewId;
  final FieldType? fieldType;

  static const routeName = '/new_property';
  static const argViewId = 'view_id';
  static const argFieldTypeId = 'field_type_id';

  @override
  State<MobileNewPropertyScreen> createState() =>
      _MobileNewPropertyScreenState();
}

class _MobileNewPropertyScreenState extends State<MobileNewPropertyScreen> {
  late FieldOptionValues optionValues;

  @override
  void initState() {
    super.initState();

    final type = widget.fieldType ?? FieldType.RichText;
    optionValues = FieldOptionValues(
      type: type,
      name: type.i18n,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlowyAppBar(
        centerTitle: true,
        titleText: LocaleKeys.grid_field_newProperty.tr(),
        leadingType: FlowyAppBarLeadingType.cancel,
        actions: [
          _SaveButton(
            onSave: () {
              context.pop(optionValues);
            },
          ),
        ],
      ),
      body: MobileFieldEditor(
        mode: FieldOptionMode.add,
        defaultValues: optionValues,
        onOptionValuesChanged: (optionValues) {
          this.optionValues = optionValues;
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
