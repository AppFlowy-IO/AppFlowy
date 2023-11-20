import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
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
  final Function(String)? onToggleVisibility;
  final FieldTypeOptionLoader typeOptionLoader;
  final FieldInfo? fieldInfo;

  const FieldEditor({
    required this.viewId,
    required this.typeOptionLoader,
    this.fieldInfo,
    this.isGroupingField = false,
    this.onDeleted,
    this.onToggleVisibility,
    super.key,
  });

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
    final bool requireSpace = widget.onDeleted != null ||
        widget.onToggleVisibility != null ||
        !widget.typeOptionLoader.field.isPrimary;

    final List<Widget> children = [
      FieldNameTextField(popoverMutex: popoverMutex),
      if (requireSpace) const VSpace(4),
      if (widget.onDeleted != null) _addDeleteFieldButton(),
      if (widget.onToggleVisibility != null) _addHideFieldButton(),
      if (!widget.typeOptionLoader.field.isPrimary)
        FieldTypeOptionCell(popoverMutex: popoverMutex),
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
          child: DeleteFieldButton(
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
          child: FieldVisibilityToggleButton(
            isFieldHidden:
                widget.fieldInfo!.visibility == FieldVisibility.AlwaysHidden,
            popoverMutex: popoverMutex,
            onTap: () {
              state.field.fold(
                () => Log.error('Can not hidden the field'),
                (field) => widget.onToggleVisibility?.call(field.id),
              );
            },
          ),
        );
      },
    );
  }
}

class FieldTypeOptionCell extends StatelessWidget {
  final PopoverMutex popoverMutex;

  const FieldTypeOptionCell({
    Key? key,
    required this.popoverMutex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (p, c) => p.field != c.field,
      builder: (context, state) {
        return state.field.fold(
          () => const SizedBox.shrink(),
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

class FieldNameTextField extends StatefulWidget {
  final PopoverMutex popoverMutex;
  const FieldNameTextField({
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  State<FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<FieldNameTextField> {
  final textController = TextEditingController();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

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
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
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
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex.close();
      }
    });
    focusNode.dispose();
    super.dispose();
  }
}

@visibleForTesting
class DeleteFieldButton extends StatelessWidget {
  final PopoverMutex popoverMutex;
  final VoidCallback? onDeleted;

  const DeleteFieldButton({
    required this.popoverMutex,
    required this.onDeleted,
    super.key,
  });

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
          leftIcon: const FlowySvg(FlowySvgs.delete_s),
          onTap: () {
            if (enable) onDeleted?.call();
          },
          onHover: (_) => popoverMutex.close(),
        );
        return SizedBox(height: GridSize.popoverItemHeight, child: button);
      },
    );
  }
}

@visibleForTesting
class FieldVisibilityToggleButton extends StatelessWidget {
  final bool isFieldHidden;
  final PopoverMutex popoverMutex;
  final VoidCallback? onTap;

  const FieldVisibilityToggleButton({
    required this.isFieldHidden,
    required this.popoverMutex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        final Widget button = FlowyButton(
          text: FlowyText.medium(
            isFieldHidden
                ? LocaleKeys.grid_field_show.tr()
                : LocaleKeys.grid_field_hide.tr(),
          ),
          leftIcon:
              FlowySvg(isFieldHidden ? FlowySvgs.show_m : FlowySvgs.hide_m),
          onTap: onTap,
          onHover: (_) => popoverMutex.close(),
        );
        return SizedBox(height: GridSize.popoverItemHeight, child: button);
      },
    );
  }
}
