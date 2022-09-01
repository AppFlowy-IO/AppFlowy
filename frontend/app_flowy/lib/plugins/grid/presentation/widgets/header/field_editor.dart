import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'field_name_input.dart';
import 'field_type_option_editor.dart';

class FieldEditor extends StatefulWidget {
  final String gridId;
  final String fieldName;

  final IFieldTypeOptionLoader typeOptionLoader;
  const FieldEditor({
    required this.gridId,
    required this.fieldName,
    required this.typeOptionLoader,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<FieldEditor> {
  late PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldEditorBloc(
        gridId: widget.gridId,
        fieldName: widget.fieldName,
        loader: widget.typeOptionLoader,
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
              _FieldTypeOptionCell(popoverMutex: popoverMutex),
            ],
          );
        },
      ),
    );
  }
}

class _FieldTypeOptionCell extends StatelessWidget {
  final PopoverMutex popoverMutex;

  const _FieldTypeOptionCell({
    Key? key,
    required this.popoverMutex,
  }) : super(key: key);

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
            return FieldTypeOptionEditor(
              dataController: dataController,
              popoverMutex: popoverMutex,
            );
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
