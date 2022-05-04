import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/field_editor_bloc.dart';
import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'field_name_input.dart';
import 'field_editor_pannel.dart';

class FieldEditor extends FlowyOverlayDelegate {
  final String gridId;
  final FieldEditorBloc _fieldEditorBloc;
  final EditFieldContextLoader fieldContextLoader;
  FieldEditor({
    required this.gridId,
    required this.fieldContextLoader,
    Key? key,
  }) : _fieldEditorBloc = getIt<FieldEditorBloc>(param1: gridId, param2: fieldContextLoader) {
    _fieldEditorBloc.add(const FieldEditorEvent.initial());
  }

  void show(
    BuildContext context, {
    AnchorDirection anchorDirection = AnchorDirection.bottomWithLeftAligned,
  }) {
    FlowyOverlay.of(context).remove(identifier());
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: _FieldEditorWidget(_fieldEditorBloc, fieldContextLoader),
        constraints: BoxConstraints.loose(const Size(280, 400)),
      ),
      identifier: identifier(),
      anchorContext: context,
      anchorDirection: anchorDirection,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  static String identifier() {
    return (FieldEditor).toString();
  }

  @override
  void didRemove() {
    _fieldEditorBloc.add(const FieldEditorEvent.done());
  }

  @override
  bool asBarrier() => true;
}

class _FieldEditorWidget extends StatelessWidget {
  final FieldEditorBloc editorBloc;
  final EditFieldContextLoader fieldContextLoader;
  const _FieldEditorWidget(this.editorBloc, this.fieldContextLoader, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: editorBloc,
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          return state.editFieldContext.fold(
            () => const SizedBox(),
            (editFieldContext) => ListView(
              shrinkWrap: true,
              children: [
                FlowyText.medium(LocaleKeys.grid_field_editProperty.tr(), fontSize: 12),
                const VSpace(10),
                const _FieldNameTextField(),
                const VSpace(10),
                FieldEditorPannel(
                  editFieldContext: editFieldContext,
                  onSwitchToField: (fieldId, fieldType) {
                    return fieldContextLoader.switchToField(fieldId, fieldType);
                  },
                  onUpdated: (field, typeOptionData) {
                    context.read<FieldEditorBloc>().add(FieldEditorEvent.updateField(field, typeOptionData));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldNameTextField extends StatelessWidget {
  const _FieldNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<FieldEditorBloc, FieldEditorState, String>(
      selector: (state) {
        return state.editFieldContext.fold(
          () => "",
          (editFieldContext) => editFieldContext.gridField.name,
        );
      },
      builder: (context, name) {
        return FieldNameTextField(
          name: name,
          errorText: context.read<FieldEditorBloc>().state.errorText,
          onNameChanged: (newName) {
            context.read<FieldEditorBloc>().add(FieldEditorEvent.updateName(newName));
          },
        );
      },
    );
  }
}
