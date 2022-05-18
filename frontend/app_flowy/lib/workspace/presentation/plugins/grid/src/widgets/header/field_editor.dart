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

class FieldEditor extends StatelessWidget with FlowyOverlayDelegate {
  final String gridId;
  final String fieldName;

  final FieldContextLoader contextLoader;
  const FieldEditor({
    required this.gridId,
    required this.fieldName,
    required this.contextLoader,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldEditorBloc(
        gridId: gridId,
        fieldName: fieldName,
        fieldContextLoader: contextLoader,
      )..add(const FieldEditorEvent.initial()),
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        buildWhen: (p, c) => false,
        builder: (context, state) {
          return ListView(
            shrinkWrap: true,
            children: [
              FlowyText.medium(LocaleKeys.grid_field_editProperty.tr(), fontSize: 12),
              const VSpace(10),
              const _FieldNameTextField(),
              const VSpace(10),
              const _FieldPannel(),
            ],
          );
        },
      ),
    );
  }

  void show(
    BuildContext context, {
    AnchorDirection anchorDirection = AnchorDirection.bottomWithLeftAligned,
  }) {
    FlowyOverlay.of(context).remove(identifier());
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
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
  bool asBarrier() => true;
}

class _FieldPannel extends StatelessWidget {
  const _FieldPannel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (p, c) => p.fieldContext != c.fieldContext,
      builder: (context, state) {
        return state.fieldContext.fold(
          () => const SizedBox(),
          (fieldContext) => FieldEditorPannel(fieldContext: fieldContext),
        );
      },
    );
  }
}

class _FieldNameTextField extends StatelessWidget {
  const _FieldNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (p, c) => p.name != c.name,
      builder: (context, state) {
        return FieldNameTextField(
          name: state.name,
          errorText: context.read<FieldEditorBloc>().state.errorText,
          onNameChanged: (newName) {
            context.read<FieldEditorBloc>().add(FieldEditorEvent.updateName(newName));
          },
        );
      },
    );
  }
}
