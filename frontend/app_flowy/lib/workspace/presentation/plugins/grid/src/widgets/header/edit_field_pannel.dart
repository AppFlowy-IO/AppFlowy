import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_name_input.dart';
import 'field_operation_list.dart';
import 'field_tyep_switcher.dart';

class EditFieldPannel extends StatelessWidget {
  final GridFieldData fieldData;
  const EditFieldPannel({required this.fieldData, Key? key}) : super(key: key);

  static void show(BuildContext context, GridFieldData fieldData) {
    final editor = EditFieldPannel(fieldData: fieldData);
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: editor,
        constraints: BoxConstraints.loose(const Size(300, 200)),
      ),
      identifier: editor.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<EditFieldBloc>(param1: fieldData)..add(const EditFieldEvent.initial()),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _FieldNameTextField(),
            const VSpace(6),
            const _FieldTypeSwitcher(),
            const VSpace(6),
            _FieldOperationList(fieldData, () => FlowyOverlay.of(context).remove(identifier())),
          ],
        ),
      ),
    );
  }

  String identifier() {
    return toString();
  }
}

class _FieldOperationList extends StatelessWidget {
  final GridFieldData fieldData;
  final VoidCallback onDismissed;
  const _FieldOperationList(this.fieldData, this.onDismissed, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actions = FieldAction.values
        .map(
          (action) => FieldActionItem(
            fieldId: fieldData.field.id,
            action: action,
            onTap: onDismissed,
          ),
        )
        .toList();

    return FieldOperationList(actions: actions);
  }
}

class _FieldTypeSwitcher extends StatelessWidget {
  const _FieldTypeSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditFieldBloc, EditFieldState>(
      builder: (context, state) {
        final editContext = context.read<EditFieldBloc>().state.editContext;
        final switchContext = SwitchFieldContext(
          editContext.gridId,
          editContext.gridField,
          editContext.typeOptionData,
        );
        return FieldTypeSwitcher(switchContext: switchContext, onSelected: (field, typeOptionData) {});
      },
    );
  }
}

class _FieldNameTextField extends StatelessWidget {
  const _FieldNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditFieldBloc, EditFieldState>(
      buildWhen: ((previous, current) => previous.editContext.gridField.name == current.editContext.gridField.name),
      builder: (context, state) {
        return FieldNameTextField(
          name: state.editContext.gridField.name,
          errorText: state.errorText,
          onNameChanged: (newName) {
            context.read<EditFieldBloc>().add(EditFieldEvent.updateFieldName(newName));
          },
        );
      },
    );
  }
}
