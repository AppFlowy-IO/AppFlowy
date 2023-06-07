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
  final bool isGroupingField;
  final Function(String)? onDeleted;
  final Function(String)? onHidden;
  final FieldTypeOptionLoader typeOptionLoader;

  const FieldEditor({
    required this.viewId,
    required this.typeOptionLoader,
    this.isGroupingField = false,
    this.onDeleted,
    this.onHidden,
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
    final List<Widget> children = [
      _FieldNameTextField(popoverMutex: popoverMutex),
      if (widget.onDeleted != null) _addDeleteFieldButton(),
      if (widget.onHidden != null) _addHideFieldButton(),
      if (!widget.typeOptionLoader.field.isPrimary)
        _FieldTypeOptionCell(popoverMutex: popoverMutex),
    ];
    return BlocProvider(
      create: (context) {
        return FieldEditorBloc(
          isGroupField: widget.isGroupingField,
          loader: widget.typeOptionLoader,
          field: widget.typeOptionLoader.field,
        )..add(const FieldEditorEvent.initial());
      },
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
        separatorBuilder: (context, index) =>
            VSpace(GridSize.typeOptionSeparatorHeight),
        padding: const EdgeInsets.symmetric(vertical: 12.0),
      ),
    );
  }

  Widget _addDeleteFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _DeleteFieldButton(
            popoverMutex: popoverMutex,
            onDeleted: () {
              state.field.fold(
                () => Log.error('Can not delete the field'),
                (field) => widget.onDeleted?.call(field.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _addHideFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _HideFieldButton(
            popoverMutex: popoverMutex,
            onHidden: () {
              state.field.fold(
                () => Log.error('Can not hidden the field'),
                (field) => widget.onHidden?.call(field.id),
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
          (fieldInfo) {
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
  final textController = TextEditingController();
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
  Widget build(BuildContext context) {
    return BlocListener<FieldEditorBloc, FieldEditorState>(
      listenWhen: (p, c) => p.field == none(),
      listener: (context, state) {
        textController.text = state.name;
        focusNode.requestFocus();
      },
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        buildWhen: (previous, current) =>
            previous.errorText != current.errorText,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: FlowyTextField(
              focusNode: focusNode,
              controller: textController,
              onSubmitted: (String _) => PopoverContainer.of(context).close(),
              text: state.name,
              errorText: state.errorText.isEmpty ? null : state.errorText,
              onChanged: (newName) {
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
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
          onHover: (_) => popoverMutex.close(),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: SizedBox(height: GridSize.popoverItemHeight, child: button),
        );
      },
    );
  }
}

class _HideFieldButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  final VoidCallback? onHidden;

  const _HideFieldButton({
    required this.popoverMutex,
    required this.onHidden,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final Widget button = FlowyButton(
          text: FlowyText.medium(
            LocaleKeys.grid_field_hide.tr(),
          ),
          onTap: () => onHidden?.call(),
          onHover: (_) => popoverMutex.close(),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: SizedBox(height: GridSize.popoverItemHeight, child: button),
        );
      },
    );
  }
}
