import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          return ListView(
            shrinkWrap: true,
            children: [
              FlowyText.medium(
                LocaleKeys.grid_field_editProperty.tr(),
                fontSize: 12,
              ),
              const VSpace(10),
              _FieldNameTextField(popoverMutex: popoverMutex),
              const VSpace(10),
              ..._addDeleteFieldButton(state),
              _FieldTypeOptionCell(popoverMutex: popoverMutex),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _addDeleteFieldButton(FieldEditorState state) {
    if (widget.onDeleted == null) {
      return [];
    }
    return [
      _DeleteFieldButton(
        popoverMutex: popoverMutex,
        onDeleted: () {
          state.field.fold(
            () => Log.error('Can not delete the field'),
            (field) => widget.onDeleted?.call(field.id),
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
  late String name;
  FocusNode focusNode = FocusNode();
  VoidCallback? _popoverCallback;
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex.close();
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    controller.text = context.read<FieldEditorBloc>().state.name;
    return BlocListener<FieldEditorBloc, FieldEditorState>(
      listenWhen: (previous, current) => previous.name != current.name,
      listener: (context, state) {
        controller.text = state.name;
      },
      child: BlocBuilder<FieldEditorBloc, FieldEditorState>(
        builder: (context, state) {
          listenOnPopoverChhanged(context);

          return RoundedInputField(
            height: 36,
            autoFocus: true,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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

  void listenOnPopoverChhanged(BuildContext context) {
    if (_popoverCallback != null) {
      widget.popoverMutex.removePopoverStateListener(_popoverCallback!);
    }
    _popoverCallback = widget.popoverMutex.listenOnPopoverStateChanged(() {
      if (focusNode.hasFocus) {
        final node = FocusScope.of(context);
        node.unfocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FieldNameTextField oldWidget) {
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));

    super.didUpdateWidget(oldWidget);
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
    final theme = context.watch<AppTheme>();
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
        );
        if (enable) button = _wrapPopover(button);
        return button;
      },
    );
  }

  Widget _wrapPopover(Widget widget) {
    return AppFlowyStylePopover(
      triggerActions: PopoverTriggerActionFlags.click,
      constraints: BoxConstraints.loose(const Size(400, 240)),
      mutex: popoverMutex,
      direction: PopoverDirection.center,
      popupBuilder: (popupContext) {
        return PopoverAlertView(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          cancel: () {},
          confirm: () {
            onDeleted?.call();
          },
        );
      },
      child: widget,
    );
  }
}
