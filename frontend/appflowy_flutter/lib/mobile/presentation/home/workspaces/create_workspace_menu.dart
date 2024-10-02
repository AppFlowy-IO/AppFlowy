import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum EditWorkspaceNameType {
  create,
  edit;

  String get title {
    switch (this) {
      case EditWorkspaceNameType.create:
        return LocaleKeys.workspace_create.tr();
      case EditWorkspaceNameType.edit:
        return LocaleKeys.workspace_renameWorkspace.tr();
    }
  }

  String get actionTitle {
    switch (this) {
      case EditWorkspaceNameType.create:
        return LocaleKeys.workspace_create.tr();
      case EditWorkspaceNameType.edit:
        return LocaleKeys.button_confirm.tr();
    }
  }
}

class EditWorkspaceNameBottomSheet extends StatefulWidget {
  const EditWorkspaceNameBottomSheet({
    super.key,
    required this.type,
    required this.onSubmitted,
    required this.workspaceName,
  });

  final EditWorkspaceNameType type;
  final void Function(String) onSubmitted;

  // if the workspace name is not empty, it will be used as the initial value of the text field.
  final String? workspaceName;

  @override
  State<EditWorkspaceNameBottomSheet> createState() =>
      _EditWorkspaceNameBottomSheetState();
}

class _EditWorkspaceNameBottomSheetState
    extends State<EditWorkspaceNameBottomSheet> {
  late final TextEditingController _textFieldController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _textFieldController = TextEditingController(
      text: widget.workspaceName,
    );
  }

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Form(
          key: _formKey,
          child: TextFormField(
            autofocus: true,
            controller: _textFieldController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: 'My Workspace',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return LocaleKeys.workspace_workspaceNameCannotBeEmpty.tr();
              }
              return null;
            },
            onEditingComplete: _onSubmit,
          ),
        ),
        const VSpace(16),
        SizedBox(
          width: double.infinity,
          child: PrimaryRoundedButton(
            text: widget.type.actionTitle,
            fontSize: 16,
            margin: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            onTap: _onSubmit,
          ),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final value = _textFieldController.text;
      widget.onSubmitted.call(value);
    }
  }
}
