import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show none;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import '../../layout/sizes.dart';
import 'field_type_option_editor.dart';

class FieldEditor extends StatefulWidget {
  final String viewId;
  final String fieldName;
  final bool isGroupField;
  final Function(String)? onDeleted;
  final IFieldTypeOptionLoader typeOptionLoader;

  const FieldEditor({
    required this.viewId,
    this.fieldName = "",
    required this.typeOptionLoader,
    this.isGroupField = false,
    this.onDeleted,
    final Key? key,
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
  Widget build(final BuildContext context) {
    final List<Widget> children = [
      _FieldNameTextField(popoverMutex: popoverMutex),
      const VSpace(10),
      if (widget.onDeleted != null) _addDeleteFieldButton(),
      _FieldTypeOptionCell(popoverMutex: popoverMutex),
    ];
    return BlocProvider(
      create: (final context) => FieldEditorBloc(
        viewId: widget.viewId,
        fieldName: widget.fieldName,
        isGroupField: widget.isGroupField,
        loader: widget.typeOptionLoader,
      )..add(const FieldEditorEvent.initial()),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: children.length,
        itemBuilder: (final context, final index) => children[index],
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
    );
  }

  Widget _addDeleteFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (final context, final state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _DeleteFieldButton(
            popoverMutex: popoverMutex,
            onDeleted: () {
              state.field.fold(
                () => Log.error('Can not delete the field'),
                (final field) => widget.onDeleted?.call(field.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _FieldTypeOptionCell extends StatelessWidget {
  final PopoverMutex popoverMutex;

  const _FieldTypeOptionCell({
    final Key? key,
    required this.popoverMutex,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (final p, final c) => p.field != c.field,
      builder: (final context, final state) {
        return state.field.fold(
          () => const SizedBox(),
          (final fieldInfo) {
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
    final Key? key,
  }) : super(key: key);

  @override
  State<_FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<_FieldNameTextField> {
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
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
  Widget build(final BuildContext context) {
    return BlocListener<FieldEditorBloc, FieldEditorState>(
      listenWhen: (final p, final c) => p.field == none(),
      listener: (final context, final state) {
        focusNode.requestFocus();
      },
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        buildWhen: (final previous, final current) =>
            previous.errorText != current.errorText,
        builder: (final context, final state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: FlowyTextField(
              focusNode: focusNode,
              onSubmitted: (final String _) =>
                  PopoverContainer.of(context).close(),
              text: context.read<FieldEditorBloc>().state.name,
              errorText: context.read<FieldEditorBloc>().state.errorText.isEmpty
                  ? null
                  : context.read<FieldEditorBloc>().state.errorText,
              onChanged: (final newName) {
                context
                    .read<FieldEditorBloc>()
                    .add(FieldEditorEvent.updateName(newName));
              },
            ),
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
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (final previous, final current) => previous != current,
      builder: (final context, final state) {
        final enable = !state.canDelete && !state.isGroupField;
        final Widget button = FlowyButton(
          disable: !enable,
          text: FlowyText.medium(
            LocaleKeys.grid_field_delete.tr(),
            color: enable ? null : Theme.of(context).disabledColor,
          ),
          onTap: () {
            if (enable) onDeleted?.call();
          },
          onHover: (final _) => popoverMutex.close(),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: SizedBox(height: GridSize.popoverItemHeight, child: button),
        );
      },
    );
  }
}
