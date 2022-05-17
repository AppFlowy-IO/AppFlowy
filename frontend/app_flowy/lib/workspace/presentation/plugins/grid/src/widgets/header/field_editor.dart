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
  final FieldContextLoader contextLoader;
  FieldEditor({
    required this.gridId,
    required this.contextLoader,
    Key? key,
  }) : _fieldEditorBloc = getIt<FieldEditorBloc>(param1: gridId, param2: contextLoader) {
    _fieldEditorBloc.add(const FieldEditorEvent.initial());
  }

  void show(
    BuildContext context, {
    AnchorDirection anchorDirection = AnchorDirection.bottomWithLeftAligned,
  }) {
    FlowyOverlay.of(context).remove(identifier());
    final child = _FieldEditorPage(_fieldEditorBloc, contextLoader);
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: child,
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

class _FieldEditorPage extends StatelessWidget {
  final FieldEditorBloc editorBloc;
  final FieldContextLoader contextLoader;
  const _FieldEditorPage(this.editorBloc, this.contextLoader, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: editorBloc,
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          return state.fieldTypeOptionData.fold(
            () => const SizedBox(),
            (fieldTypeOptionContext) => ListView(
              shrinkWrap: true,
              children: [
                FlowyText.medium(LocaleKeys.grid_field_editProperty.tr(), fontSize: 12),
                const VSpace(10),
                const _FieldNameTextField(),
                const VSpace(10),
                FieldEditorPannel(
                  fieldTypeOptionData: fieldTypeOptionContext,
                  onSwitchToField: (fieldId, fieldType) {
                    return contextLoader.switchToField(fieldId, fieldType);
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
        return state.fieldTypeOptionData.fold(
          () => "",
          (fieldTypeOptionContext) => fieldTypeOptionContext.field_2.name,
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
