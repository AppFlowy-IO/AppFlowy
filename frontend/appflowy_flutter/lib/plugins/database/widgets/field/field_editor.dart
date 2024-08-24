import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_type_list.dart';
import 'type_option_editor/builder.dart';

enum FieldEditorPage {
  general,
  details,
}

class FieldEditor extends StatefulWidget {
  const FieldEditor({
    super.key,
    required this.viewId,
    required this.field,
    required this.fieldController,
    this.initialPage = FieldEditorPage.details,
    this.onFieldInserted,
  });

  final String viewId;
  final FieldPB field;
  final FieldController fieldController;
  final FieldEditorPage initialPage;
  final void Function(String fieldId)? onFieldInserted;

  @override
  State<StatefulWidget> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<FieldEditor> {
  late FieldEditorPage _currentPage;
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    textController = TextEditingController(text: widget.field.name);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FieldEditorBloc(
        viewId: widget.viewId,
        field: widget.field,
        fieldController: widget.fieldController,
        onFieldInserted: widget.onFieldInserted,
      ),
      child: _currentPage == FieldEditorPage.details
          ? _fieldDetails()
          : _fieldGeneral(),
    );
  }

  Widget _fieldGeneral() {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldNameTextField(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            textEditingController: textController,
          ),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _EditFieldButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            onTap: () {
              setState(() => _currentPage = FieldEditorPage.details);
            },
          ),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.insertLeft),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.insertRight),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.toggleVisibility),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.duplicate),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.clearData),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.delete),
          const TypeOptionSeparator(spacing: 8.0),
          _actionCell(FieldAction.wrap),
          const VSpace(8.0),
        ],
      ),
    );
  }

  Widget _fieldDetails() {
    return SizedBox(
      width: 260,
      child: FieldDetailsEditor(
        viewId: widget.viewId,
        textEditingController: textController,
      ),
    );
  }

  Widget _actionCell(FieldAction action) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: FieldActionCell(
          viewId: widget.viewId,
          fieldInfo: state.field,
          action: action,
        ),
      ),
    );
  }
}

class _EditFieldButton extends StatelessWidget {
  const _EditFieldButton({
    required this.padding,
    this.onTap,
  });

  final EdgeInsetsGeometry padding;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GridSize.popoverItemHeight,
      padding: padding,
      child: FlowyButton(
        leftIcon: const FlowySvg(FlowySvgs.edit_s),
        text: FlowyText.medium(
          lineHeight: 1.0,
          LocaleKeys.grid_field_editProperty.tr(),
        ),
        onTap: onTap,
      ),
    );
  }
}

class FieldActionCell extends StatelessWidget {
  const FieldActionCell({
    super.key,
    required this.viewId,
    required this.fieldInfo,
    required this.action,
    this.popoverMutex,
  });

  final String viewId;
  final FieldInfo fieldInfo;
  final FieldAction action;
  final PopoverMutex? popoverMutex;

  @override
  Widget build(BuildContext context) {
    bool enable = true;
    // If the field is primary, delete and duplicate are disabled.
    if (fieldInfo.isPrimary &&
        (action == FieldAction.duplicate || action == FieldAction.delete)) {
      enable = false;
    }

    return FlowyButton(
      disable: !enable,
      text: FlowyText.medium(
        action.title(fieldInfo),
        lineHeight: 1.0,
        color: enable ? null : Theme.of(context).disabledColor,
      ),
      onHover: (_) => popoverMutex?.close(),
      onTap: () => action.run(context, viewId, fieldInfo),
      leftIcon: action.leading(
        fieldInfo,
        enable ? null : Theme.of(context).disabledColor,
      ),
      rightIcon: action.trailing(context, fieldInfo),
    );
  }
}

enum FieldAction {
  insertLeft,
  insertRight,
  toggleVisibility,
  duplicate,
  clearData,
  delete,
  wrap;

  Widget? leading(FieldInfo fieldInfo, Color? color) {
    FlowySvgData? svgData;
    switch (this) {
      case FieldAction.insertLeft:
        svgData = FlowySvgs.arrow_s;
      case FieldAction.insertRight:
        svgData = FlowySvgs.arrow_s;
      case FieldAction.toggleVisibility:
        if (fieldInfo.visibility != null &&
            fieldInfo.visibility == FieldVisibility.AlwaysHidden) {
          svgData = FlowySvgs.show_m;
        } else {
          svgData = FlowySvgs.hide_s;
        }
      case FieldAction.duplicate:
        svgData = FlowySvgs.copy_s;
      case FieldAction.clearData:
        svgData = FlowySvgs.reload_s;
      case FieldAction.delete:
        svgData = FlowySvgs.delete_s;
      default:
    }

    if (svgData == null) {
      return null;
    }
    final icon = FlowySvg(
      svgData,
      size: const Size.square(16),
      color: color,
    );
    return this == FieldAction.insertRight
        ? Transform.flip(flipX: true, child: icon)
        : icon;
  }

  Widget? trailing(BuildContext context, FieldInfo fieldInfo) {
    if (this == FieldAction.wrap) {
      return Toggle(
        value: fieldInfo.wrapCellContent ?? false,
        onChanged: (_) => context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleWrapCellContent()),
        padding: EdgeInsets.zero,
      );
    }

    return null;
  }

  String title(FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.insertLeft:
        return LocaleKeys.grid_field_insertLeft.tr();
      case FieldAction.insertRight:
        return LocaleKeys.grid_field_insertRight.tr();
      case FieldAction.toggleVisibility:
        if (fieldInfo.visibility != null &&
            fieldInfo.visibility == FieldVisibility.AlwaysHidden) {
          return LocaleKeys.grid_field_show.tr();
        } else {
          return LocaleKeys.grid_field_hide.tr();
        }
      case FieldAction.duplicate:
        return LocaleKeys.grid_field_duplicate.tr();
      case FieldAction.clearData:
        return LocaleKeys.grid_field_clear.tr();
      case FieldAction.delete:
        return LocaleKeys.grid_field_delete.tr();
      case FieldAction.wrap:
        return LocaleKeys.grid_field_wrapCellContent.tr();
    }
  }

  void run(BuildContext context, String viewId, FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.insertLeft:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.insertLeft());
        break;
      case FieldAction.insertRight:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.insertRight());
        break;
      case FieldAction.toggleVisibility:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleFieldVisibility());
        break;
      case FieldAction.duplicate:
        PopoverContainer.of(context).close();
        FieldBackendService.duplicateField(
          viewId: viewId,
          fieldId: fieldInfo.id,
        );
        break;
      case FieldAction.clearData:
        NavigatorAlertDialog(
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 260,
          ),
          title: LocaleKeys.grid_field_clearFieldPromptMessage.tr(),
          confirm: () {
            FieldBackendService.clearField(
              viewId: viewId,
              fieldId: fieldInfo.id,
            );
          },
        ).show(context);
        PopoverContainer.of(context).close();
        break;
      case FieldAction.delete:
        NavigatorAlertDialog(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          confirm: () {
            FieldBackendService.deleteField(
              viewId: viewId,
              fieldId: fieldInfo.id,
            );
          },
        ).show(context);
        PopoverContainer.of(context).close();
        break;
      case FieldAction.wrap:
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleWrapCellContent());
        break;
    }
  }
}

class FieldDetailsEditor extends StatefulWidget {
  const FieldDetailsEditor({
    super.key,
    required this.viewId,
    required this.textEditingController,
    this.onAction,
  });

  final String viewId;
  final TextEditingController textEditingController;
  final Function()? onAction;

  @override
  State<StatefulWidget> createState() => _FieldDetailsEditorState();
}

class _FieldDetailsEditorState extends State<FieldDetailsEditor> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      FieldNameTextField(
        popoverMutex: popoverMutex,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        textEditingController: widget.textEditingController,
      ),
      const VSpace(8.0),
      SwitchFieldButton(popoverMutex: popoverMutex),
      const TypeOptionSeparator(spacing: 8.0),
      Flexible(
        child: FieldTypeOptionEditor(
          viewId: widget.viewId,
          popoverMutex: popoverMutex,
        ),
      ),
      _addFieldVisibilityToggleButton(),
      _addDuplicateFieldButton(),
      _addDeleteFieldButton(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _addFieldVisibilityToggleButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: FieldAction.toggleVisibility,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }

  Widget _addDeleteFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: FieldAction.delete,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }

  Widget _addDuplicateFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: FieldAction.duplicate,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }
}

class FieldTypeOptionEditor extends StatelessWidget {
  const FieldTypeOptionEditor({
    super.key,
    required this.viewId,
    required this.popoverMutex,
  });

  final String viewId;
  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        if (state.field.isPrimary) {
          return const SizedBox.shrink();
        }
        final typeOptionEditor = makeTypeOptionEditor(
          context: context,
          viewId: viewId,
          field: state.field.field,
          popoverMutex: popoverMutex,
          onTypeOptionUpdated: (Uint8List typeOptionData) {
            context
                .read<FieldEditorBloc>()
                .add(FieldEditorEvent.updateTypeOption(typeOptionData));
          },
        );

        if (typeOptionEditor == null) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: typeOptionEditor),
            const TypeOptionSeparator(spacing: 8.0),
          ],
        );
      },
    );
  }
}

class FieldNameTextField extends StatefulWidget {
  const FieldNameTextField({
    super.key,
    required this.textEditingController,
    this.popoverMutex,
    this.padding = EdgeInsets.zero,
  });

  final TextEditingController textEditingController;
  final PopoverMutex? popoverMutex;
  final EdgeInsets padding;

  @override
  State<FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<FieldNameTextField> {
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });

    widget.popoverMutex?.listenOnPopoverChanged(() {
      if (focusNode.hasFocus) {
        focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: FlowyTextField(
        focusNode: focusNode,
        controller: widget.textEditingController,
        onSubmitted: (_) => PopoverContainer.of(context).close(),
        onChanged: (newName) {
          context
              .read<FieldEditorBloc>()
              .add(FieldEditorEvent.renameField(newName));
        },
      ),
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });
    focusNode.dispose();
    super.dispose();
  }
}

class SwitchFieldButton extends StatefulWidget {
  const SwitchFieldButton({super.key, required this.popoverMutex});

  final PopoverMutex popoverMutex;

  @override
  State<SwitchFieldButton> createState() => _SwitchFieldButtonState();
}

class _SwitchFieldButtonState extends State<SwitchFieldButton> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        final bool isPrimary = state.field.isPrimary;
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(460, 540)),
            triggerActions: isPrimary ? 0 : PopoverTriggerFlags.hover,
            mutex: widget.popoverMutex,
            controller: _popoverController,
            offset: const Offset(8, 0),
            margin: const EdgeInsets.all(8),
            popupBuilder: (BuildContext popoverContext) {
              return FieldTypeList(
                onSelectField: (newFieldType) {
                  context
                      .read<FieldEditorBloc>()
                      .add(FieldEditorEvent.switchFieldType(newFieldType));
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FlowyButton(
                onTap: () {
                  if (!isPrimary) {
                    _popoverController.show();
                  }
                },
                text: FlowyText.medium(
                  state.field.fieldType.i18n,
                  lineHeight: 1.0,
                  color: isPrimary ? Theme.of(context).disabledColor : null,
                ),
                leftIcon: FlowySvg(
                  state.field.fieldType.svgData,
                  color: isPrimary ? Theme.of(context).disabledColor : null,
                ),
                rightIcon: FlowySvg(
                  FlowySvgs.more_s,
                  color: isPrimary ? Theme.of(context).disabledColor : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
