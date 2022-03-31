import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/edit_field_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:app_flowy/workspace/application/grid/field/switch_field_type_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'field_name_input.dart';
import 'field_switcher.dart';

class FieldEditor extends FlowyOverlayDelegate {
  final String gridId;
  final FieldEditorBloc _fieldEditorBloc;
  final FieldContextLoader? fieldContextLoader;
  FieldEditor({
    required this.gridId,
    required this.fieldContextLoader,
    Key? key,
  }) : _fieldEditorBloc = getIt<FieldEditorBloc>(param1: gridId, param2: fieldContextLoader) {
    _fieldEditorBloc.add(const FieldEditorEvent.initial());
  }

  void show(BuildContext context) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: _EditFieldPannelWidget(_fieldEditorBloc),
        constraints: BoxConstraints.loose(const Size(220, 400)),
      ),
      identifier: identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  String identifier() {
    return toString();
  }

  @override
  void didRemove() {
    _fieldEditorBloc.add(const FieldEditorEvent.done());
  }

  @override
  bool asBarrier() => true;
}

class _EditFieldPannelWidget extends StatelessWidget {
  final FieldEditorBloc editorBloc;
  const _EditFieldPannelWidget(this.editorBloc, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: editorBloc,
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          return state.field.fold(
            () => const SizedBox(width: 200),
            (field) => ListView(
              shrinkWrap: true,
              children: [
                const FlowyText.medium("Edit property", fontSize: 12),
                const VSpace(10),
                const _FieldNameTextField(),
                const VSpace(10),
                _FieldSwitcher(SwitchFieldContext(state.gridId, field, state.typeOptionData)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldSwitcher extends StatelessWidget {
  final SwitchFieldContext switchContext;
  const _FieldSwitcher(this.switchContext, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FieldSwitcher(
      switchContext: switchContext,
      onUpdated: (field, typeOptionData) {
        context.read<FieldEditorBloc>().add(FieldEditorEvent.switchField(field, typeOptionData));
      },
    );
  }
}

class _FieldNameTextField extends StatelessWidget {
  const _FieldNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (previous, current) => previous.fieldName != current.fieldName,
      builder: (context, state) {
        return FieldNameTextField(
          name: state.fieldName,
          errorText: context.read<FieldEditorBloc>().state.errorText,
          onNameChanged: (newName) {
            context.read<FieldEditorBloc>().add(FieldEditorEvent.updateName(newName));
          },
        );
      },
    );
  }
}
