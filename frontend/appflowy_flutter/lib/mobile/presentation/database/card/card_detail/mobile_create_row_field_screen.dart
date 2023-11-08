import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/mobile_field_editor.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MobileCreateRowFieldScreen extends StatefulWidget {
  final String viewId;
  final TypeOptionPB typeOption;
  static const routeName = '/MobileCreateRowFieldScreen';
  static const argViewId = 'viewId';
  static const argTypeOption = 'typeOption';

  const MobileCreateRowFieldScreen({
    required this.viewId,
    required this.typeOption,
    super.key,
  });

  @override
  State<MobileCreateRowFieldScreen> createState() =>
      _MobileCreateRowFieldScreenState();
}

class _MobileCreateRowFieldScreenState
    extends State<MobileCreateRowFieldScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.grid_field_newProperty.tr())),
      body: MobileFieldEditor(
        viewId: widget.viewId,
        typeOptionLoader: FieldTypeOptionLoader(
          viewId: widget.viewId,
          field: widget.typeOption.field_2,
        ),
      ),
    );
  }
}
