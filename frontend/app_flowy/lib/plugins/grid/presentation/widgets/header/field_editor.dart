import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'field_name_input.dart';
import 'field_type_option_editor.dart';

class FieldEditor extends StatelessWidget with FlowyOverlayDelegate {
  final String gridId;
  final String fieldName;
  final VoidCallback? onRemoved;

  final IFieldTypeOptionLoader typeOptionLoader;
  const FieldEditor({
    required this.gridId,
    this.fieldName = "",
    required this.typeOptionLoader,
    this.onRemoved,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldEditorBloc(
        gridId: gridId,
        fieldName: fieldName,
        loader: typeOptionLoader,
      )..add(const FieldEditorEvent.initial()),
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        buildWhen: (p, c) => false,
        builder: (context, state) {
          return ListView(
            shrinkWrap: true,
            children: [
              FlowyText.medium(LocaleKeys.grid_field_editProperty.tr(),
                  fontSize: 12),
              const VSpace(10),
              const _FieldNameCell(),
              const VSpace(10),
              const _FieldTypeOptionCell(),
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
        constraints: BoxConstraints.loose(const Size(280, 400)),
        child: this,
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

  @override
  void didRemove() => onRemoved?.call();
}

class _FieldTypeOptionCell extends StatelessWidget {
  const _FieldTypeOptionCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (p, c) => p.field != c.field,
      builder: (context, state) {
        return state.field.fold(
          () => const SizedBox(),
          (fieldContext) {
            final dataController =
                context.read<FieldEditorBloc>().dataController;
            return FieldTypeOptionEditor(dataController: dataController);
          },
        );
      },
    );
  }
}

class _FieldNameCell extends StatelessWidget {
  const _FieldNameCell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return FieldNameTextField(
          name: state.name,
          errorText: context.read<FieldEditorBloc>().state.errorText,
          onNameChanged: (newName) {
            context
                .read<FieldEditorBloc>()
                .add(FieldEditorEvent.updateName(newName));
          },
        );
      },
    );
  }
}
