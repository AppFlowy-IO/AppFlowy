import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
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
    return TextField(
      controller: controller,
      onChanged: (newName) {
        context
            .read<FieldEditorBloc>()
            .add(FieldEditorEvent.renameField(newName));
      },
    );
  }
}
