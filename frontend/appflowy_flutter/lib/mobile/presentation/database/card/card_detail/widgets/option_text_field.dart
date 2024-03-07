import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_field_bottom_sheets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OptionTextField extends StatelessWidget {
  const OptionTextField({
    super.key,
    required this.controller,
    required this.type,
    required this.onTextChanged,
    required this.onFieldTypeChanged,
  });

  final TextEditingController controller;
  final FieldType type;
  final void Function(String value) onTextChanged;
  final void Function(FieldType value) onFieldTypeChanged;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.textField(
      controller: controller,
      textFieldPadding: const EdgeInsets.symmetric(horizontal: 12.0),
      onTextChanged: onTextChanged,
      leftIcon: GestureDetector(
        onTap: () async {
          final fieldType = await showFieldTypeGridBottomSheet(
            context,
            title: LocaleKeys.grid_field_editProperty.tr(),
          );
          if (fieldType != null) {
            onFieldTypeChanged(fieldType);
          }
        },
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).brightness == Brightness.light
                ? type.mobileIconBackgroundColor
                : type.mobileIconBackgroundColorDark,
          ),
          child: Center(
            child: FlowySvg(
              type.svgData,
              size: const Size.square(22),
            ),
          ),
        ),
      ),
    );
  }
}
