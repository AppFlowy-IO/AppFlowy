import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileFieldNameTextField extends StatefulWidget {
  const MobileFieldNameTextField({
    super.key,
    this.text,
  });

  final String? text;

  @override
  State<MobileFieldNameTextField> createState() =>
      _MobileFieldNameTextFieldState();
}

class _MobileFieldNameTextFieldState extends State<MobileFieldNameTextField> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.text != null) {
      controller.text = widget.text!;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PropertyEditContainer(
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: LocaleKeys.board_propertyName.tr(),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (newName) {
          context
              .read<FieldEditorBloc>()
              .add(FieldEditorEvent.renameField(newName));
        },
      ),
    );
  }
}
