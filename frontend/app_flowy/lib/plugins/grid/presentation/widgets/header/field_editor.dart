import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show none;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'field_type_option_editor.dart';

class FieldEditor extends StatefulWidget {
  final String gridId;
  final String fieldName;
  final bool isGroupField;
  final Function(String)? onDeleted;
  final IFieldTypeOptionLoader typeOptionLoader;

  const FieldEditor({
    required this.gridId,
    this.fieldName = "",
    required this.typeOptionLoader,
    this.isGroupField = false,
    this.onDeleted,
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
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldEditorBloc(
        gridId: widget.gridId,
        fieldName: widget.fieldName,
        isGroupField: widget.isGroupField,
        loader: widget.typeOptionLoader,
      )..add(const FieldEditorEvent.initial()),
      child: Padding(
        padding: GridSize.typeOptionContentInsets,
        child: ListView(
          shrinkWrap: true,
          children: [
            FlowyText.medium(
              LocaleKeys.grid_field_editProperty.tr(),
              fontSize: 12,
            ),
            const VSpace(10),
            _FieldNameTextField(popoverMutex: popoverMutex),
            const VSpace(10),
            ..._addDeleteFieldButton(),
            _FieldTypeOptionCell(popoverMutex: popoverMutex),
          ],
        ),
      ),
    );
  }

  List<Widget> _addDeleteFieldButton() {
    if (widget.onDeleted == null) {
      return [];
    }
    return [
      BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          return _DeleteFieldButton(
            popoverMutex: popoverMutex,
            onDeleted: () {
              state.field.fold(
                () => Log.error('Can not delete the field'),
                (field) => widget.onDeleted?.call(field.id),
              );
            },
          );
        },
      ),
    ];
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

class _FieldNameTextField extends StatefulWidget {
  final PopoverMutex popoverMutex;
  const _FieldNameTextField({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<_FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<_FieldNameTextField> {
  FocusNode focusNode = FocusNode();
  late TextEditingController controller;

  @override
  void initState() {
    controller = TextEditingController();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex.close();
      }
    });

    widget.popoverMutex.listenOnPopoverChanged(() {
      if (focusNode.hasFocus) {
        focusNode.unfocus();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return MultiBlocListener(
      listeners: [
        BlocListener<FieldEditorBloc, FieldEditorState>(
          listenWhen: (p, c) => p.field == none(),
          listener: (context, state) {
            focusNode.requestFocus();
          },
        ),
        BlocListener<FieldEditorBloc, FieldEditorState>(
          listenWhen: (p, c) => controller.text != c.name,
          listener: (context, state) {
            controller.text = state.name;
          },
        ),
      ],
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        buildWhen: (previous, current) =>
            previous.errorText != current.errorText,
        builder: (context, state) {
          return RoundedInputField(
            height: 36,
            focusNode: focusNode,
            style: TextStyles.general(
              fontSize: 13,
            ),
            controller: controller,
            normalBorderColor: theme.shader4,
            errorBorderColor: theme.red,
            focusBorderColor: theme.main1,
            cursorColor: theme.main1,
            errorText: context.read<FieldEditorBloc>().state.errorText,
            onChanged: (newName) {
              context
                  .read<FieldEditorBloc>()
                  .add(FieldEditorEvent.updateName(newName));
            },
          );
        },
      ),
    );
  }
}

class _DeleteFieldButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  final VoidCallback? onDeleted;

  const _DeleteFieldButton({
    required this.popoverMutex,
    required this.onDeleted,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final enable = !state.canDelete && !state.isGroupField;
        Widget button = FlowyButton(
          text: FlowyText.medium(
            LocaleKeys.grid_field_delete.tr(),
            fontSize: 12,
            color: enable ? null : theme.shader4,
          ),
          onTap: () => onDeleted?.call(),
          hoverColor: theme.hover,
          onHover: (_) => popoverMutex.close(),
        );
        return SizedBox(height: 36, child: button);
      },
    );
  }
}
